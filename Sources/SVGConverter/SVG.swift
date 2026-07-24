//
//  SVG.swift
//  engine-test
//
//  Created by Kristian Trenskow on 24/07/2026.
//

import SwiftUI
import WebKit

@MainActor
public struct SVG<Content: View>: View {

	public enum ConverterError: Swift.Error, Sendable {
		case cannotDecodeSVG
		case cannotDecodeResult
		case jsError(message: String)
	}

	public typealias Convert = (@Sendable (Data) async throws -> UIImage)

	@MainActor
	private struct SVGBackgroundView: UIViewRepresentable {

		struct JSParameters: Encodable {
			let uuid: UUID
			let svg: String
			let scale: CGFloat
		}

		struct JSResult: Decodable {

			enum CodingKeys: String, CodingKey {
				case uuid
				case result
				case image
				case message
			}

			enum ResultType: String, Decodable {
				case success
				case failure
			}

			let uuid: UUID
			let result: Result<UIImage, Swift.Error>

			init(
				from decoder:
				any Decoder
			) throws {

				let container = try decoder.container(
					keyedBy: Self.CodingKeys.self)

				self.uuid = try container.decode(
					UUID.self,
					forKey: .uuid)

				let result = try container.decode(
					ResultType.self,
					forKey: .result)

				switch result {
				case .success:

					guard
						let data = Data(dataUrl: try container.decode(
							String.self,
								forKey: .image)),
						let image = UIImage(
							data: data)
					else {
						throw ConverterError.cannotDecodeResult
					}

					self.result = .success(
						image)

				case .failure:

					self.result = .failure(
						ConverterError.jsError(
							message: try container.decode(
								String.self,
								forKey: .message)))

				}

			}

		}

		final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, Sendable {

			private class UserContent: NSObject, WKScriptMessageHandler {

				let action: @Sendable (Any?) -> Void

				init(
					action: @Sendable @escaping (Any?) -> Void
				) {
					self.action = action
				}

				func userContentController(
					_ userContentController: WKUserContentController,
					didReceive message: WKScriptMessage
				) {
					self.action(message.body)
				}

			}

			var webView: WKWebView
			var queue: [UUID: CheckedContinuation<UIImage, Swift.Error>] = [:]

			private var loadedContinuations: [CheckedContinuation<Void, Never>] = []

			override init() {

				let configuration = WKWebViewConfiguration()

				let userContentController = WKUserContentController()

				configuration.userContentController = userContentController

				self.webView = WKWebView(
					frame: .zero,
					configuration: configuration)

				self.webView.isHidden = true

				super.init()

				userContentController.add(
					self,
					name: "converter")

				self.webView.navigationDelegate = self

			}

			func loaded() async {

				if !self.webView.isLoading {
					return
				}

				return await withCheckedContinuation { continuation in
					self.loadedContinuations.append(
						continuation)
				}

			}

			func userContentController(
				_ userContentController: WKUserContentController,
				didReceive message: WKScriptMessage
			) {

				guard
					let bodyString = message.body as? String,
					let data = bodyString.data(
						using: .utf8),
					let result = try? JSONDecoder().decode(
						JSResult.self,
						from: data)
				else {
					fatalError("Cannot decode result: \(message.body)")
				}

				let continuation = self.queue.removeValue(
					forKey: result.uuid)

				continuation?.resume(
					with: result.result)

			}

			func webView(
				_ webView: WKWebView,
				didFinish navigation: WKNavigation!
			) {

				self.loadedContinuations
					.forEach({ $0.resume() })

				self.loadedContinuations = []

			}

		}

		@Binding private var convert: Convert?
		private let html: String?
		private let displayScale: CGFloat

		init(
			convert: Binding<Convert?>,
			html: String?,
			displayScale: CGFloat
		) {
			self._convert = convert
			self.html = html
			self.displayScale = displayScale
		}

		func makeCoordinator() -> Coordinator {
			return Coordinator()
		}

		func makeUIView(
			context: Context
		) -> WKWebView {

			let html = self.html ?? String(
				data: try! Data(
					contentsOf: Bundle.module.url(
						forResource: "Converter",
						withExtension: "html")!),
				encoding: .utf8)!

			context.coordinator.webView.loadHTMLString(
				html,
				baseURL: nil)

			Task {
				self.convert = { @Sendable data in

					await context.coordinator.loaded()

					guard let svg = String(data: data, encoding: .utf8)
					else { throw ConverterError.cannotDecodeSVG }

					let parameters = JSParameters(
						uuid: UUID(),
						svg: svg,
						scale: self.displayScale)

					guard
						let arguments = String(
							data: try JSONEncoder().encode(
								parameters),
							encoding: .utf8)
					else { throw ConverterError.cannotDecodeSVG }

					let image: UIImage = try await withCheckedThrowingContinuation { continuation in
						Task { @MainActor in

							context.coordinator.queue[parameters.uuid] = continuation

							try await context.coordinator.webView.evaluateJavaScript("convert(\(arguments))")

						}
					}

					return image.with(
						scale: self.displayScale)

				}
			}

			return context.coordinator.webView

		}

		func updateUIView(
			_ uiView: WKWebView,
			context: Context
		) { }

		func sizeThatFits(
			_ proposal: ProposedViewSize,
			uiView: WKWebView,
			context: Context
		) -> CGSize? {
			return .zero
		}

	}

	@Environment(\.displayScale) private var displayScale

	@State private var convert: Convert?

	private let html: String?
	private let content: @MainActor @Sendable (@escaping Convert) -> Content

	public init(
		html: String? = nil, // Is build in – provide only for updated version.
		content: @MainActor @Sendable @escaping (@escaping Convert) -> Content
	) {
		self.html = html
		self.content = content
	}

	public var body: some View {
		ZStack {

			SVGBackgroundView(
				convert: self.$convert,
				html: self.html,
				displayScale: self.displayScale)

			if let convert = self.convert {
				self.content(
					convert)
			}

		}
	}

}
