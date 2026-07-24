SVGConverter
----

SwiftUI library for converting SVG into PNG at display scale.

It might not be the fastest converter in the world, but it uses a `WKWebView` to do the conversion so all browser SVG extensions are supported.

It supports parallel conversion of multiple SVGs at the same time.

# Usage

Use as below.

````swift

import SwiftUI
import SVGConverter

struct Example: View {

	@State private var uiImage: UIImage?
	
	private let svg: Data
	
	init(
		svg: Data
	) {
		self.svg = svg
	}
	
	var body: some View {
		SVG { convert in 
			VStack {

				if let uiImage = self.uiImage {
					Image(
						uiImage: uiImage)
				}

				Button {
					Task { @MainActor in
						self.uiImage = try await convert(
							self.svg)
					}
				} label: {
					Text("Convert SVG")
				}

			}
		}
	}

}

````

See license in LICENSE.
