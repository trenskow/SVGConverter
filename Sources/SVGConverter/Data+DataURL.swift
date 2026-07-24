//
//  Data+DataURL.swift
//  engine-test
//
//  Created by Kristian Trenskow on 24/07/2026.
//

import Foundation

extension Data {

	init?(
		dataUrl: String
	) {

		guard
			let comma = dataUrl.firstIndex(of: ",")
		else { return nil }

		guard
			let data = Data(
				base64Encoded: String(dataUrl[dataUrl.index(after: comma)...]))
		else { return nil }

		self = data

	}

}
