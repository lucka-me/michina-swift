// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tokenizers",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "Tokenizers",
            targets: ["Tokenizers"]
        ),
    ],
    targets: [
        .target(name: "Hub"),
        .target(name: "Tokenizers", dependencies: [ .target(name: "Hub") ]),
    ],
    swiftLanguageModes: [.v6]
)
