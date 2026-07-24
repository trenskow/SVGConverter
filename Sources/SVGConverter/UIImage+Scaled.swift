//
//  UIImage+Scaled.swift
//  engine-test
//
//  Created by Kristian Trenskow on 24/07/2026.
//

import UIKit

extension UIImage {

	func with(
		scale: CGFloat
	) -> UIImage {

		let format = UIGraphicsImageRendererFormat()

		format.scale = scale

		let scaled = CGSize(
			width: self.size.width / scale,
			height: self.size.height / scale)

		return UIGraphicsImageRenderer(
			size: scaled,
			format: format
		).image { context in

			context.cgContext.translateBy(
				x: 0,
				y: scaled.height)

			context.cgContext.scaleBy(
				x: 1,
				y: -1)

			context.cgContext.draw(
				self.cgImage!,
				in: .init(
					origin: .zero,
					size: scaled))

		}

	}

}
