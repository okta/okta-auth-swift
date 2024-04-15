// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OktaAuthNative",
    platforms: [
        .macOS(.v10_14), .iOS(.v10)
    ],
    products: [
        .library(name: "OktaAuthNative", targets: ["OktaAuthNative"])
    ],
    targets: [
        .target(name: "OktaAuthNative", dependencies: [],path: "Source", exclude: ["Info.plist"], resources: [.process("Resources")]),
        .testTarget(name: "OktaAuthNative_Tests", dependencies: ["OktaAuthNative"], path: "Tests", exclude: ["AuthenticationClientTests.swift"])
    ]
)
