// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SVGConverter",
	platforms: [.iOS(.v16)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "SVGConverter",
			targets: ["SVGConverter"]
		)
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "SVGConverter",
			resources: [
				.process("Converter.html")
			]
		)

	],
	swiftLanguageModes: [.v6]
)
