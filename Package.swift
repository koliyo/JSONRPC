// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
	name: "JSONRPC",
	platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
	products: [
		.library(name: "JSONRPC", targets: ["JSONRPC"]),
	],
	dependencies: [
			// NOTE: This is only for testing
			.package(
				url: "https://github.com/apple/swift-collections.git",
				.upToNextMinor(from: "1.0.0") // or `.upToNextMajor
			)
	],
	targets: [
		.target(name: "JSONRPC", dependencies: [], swiftSettings: settings),
		.testTarget(name: "JSONRPCTests", dependencies: [
			"JSONRPC",
			.product(name: "Collections", package: "swift-collections")
			], swiftSettings: settings),
	]
)
