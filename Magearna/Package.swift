// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Magearna",
    defaultLocalization: "en",
    platforms: [ .macOS(.v26) ],
    products: [
        .library(name: "Magearna", targets: [ "Magearna" ]),
    ],
    dependencies: [
        .package(name: "ONNXRuntime", path: "../ONNXRuntime"),
        .package(name: "Tokenizers", path: "../Tokenizers"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/apple/swift-protobuf.git", .upToNextMajor(from: "1.38.0")),
        .package(url: "https://github.com/ml-explore/mlx-swift", .upToNextMajor(from: "0.31.4")),
    ],
    targets: [
        .target(
            name: "Magearna",
            dependencies: [
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "ONNXRuntime", package: "ONNXRuntime"),
                .product(name: "ONNXRuntimeExtensions", package: "ONNXRuntime"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Tokenizers", package: "Tokenizers"),
            ],
            resources: [
                .process("Resources/Localizable.xcstrings")
            ],
            plugins: [
                .plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")
            ]
        ),
    ],
    swiftLanguageModes: [ .v6 ],
)
