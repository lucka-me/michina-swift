// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "ONNXRuntime",
    platforms: [ .macOS(.v12) ],
    products: [
        .library(
            name: "ONNXRuntime",
            type: .static,
            targets: [ "ONNXRuntime" ]
        ),
    ],
    targets: [
        .target(
            name: "ONNXRuntime",
            dependencies: [ "onnxruntime-framework" ],
            path: "Frameworks/onnxruntime/source/objectivec",
            exclude: [
                "ReadMe.md", "format_objc.sh", "test", "docs",
                "ort_checkpoint.mm",
                "ort_checkpoint_internal.h",
                "ort_training_session_internal.h",
                "ort_training_session.mm",
                "include/ort_checkpoint.h",
                "include/ort_training_session.h",
                "include/onnxruntime_training.h"
            ],
            cxxSettings: [
                .define("SPM_BUILD"),
            ]
        ),
        .binaryTarget(
            name: "onnxruntime-framework",
            path: "Frameworks/onnxruntime/onnxruntime.xcframework"
        ),
        // .binaryTarget(
        //     name: "onnxruntime-framework",
        //     url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.26.0.zip",
        //     checksum: "08502ec252f6f03ebee6e729cbe0525c777b47daa76d3bc8c04bba82201d8a36"
        // )
    ],
    swiftLanguageModes: [ .v6 ],
    cxxLanguageStandard: .cxx17
)
