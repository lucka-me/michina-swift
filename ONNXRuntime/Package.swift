// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let onnxruntimeBuildConfig = Context.environment["ORT_BUILD_CONFIG"] ?? "Release"

let package = Package(
    name: "ONNXRuntime",
    products: [
        .library(
            name: "ONNXRuntime",
            type: .static,
            targets: ["ONNXRuntime"]
        ),
        .library(
            name: "ONNXRuntimeExtensions",
            type: .static,
            targets: ["ONNXRuntimeExtensions"]
        ),
    ],
    targets: [
        .target(
            name: "ONNXRuntime",
            dependencies: ["onnxruntime-framework"],
            path: "onnxruntime/objectivec",
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
        .target(
            name: "ONNXRuntimeExtensions",
            dependencies: ["onnxruntime-extensions-framework", "onnxruntime-framework"],
            cxxSettings: [
                .define("ORT_SWIFT_PACKAGE_MANAGER_BUILD"),
            ]
        ),
        .binaryTarget(
            name: "onnxruntime-framework",
            path: "onnxruntime/build/\(onnxruntimeBuildConfig)/\(onnxruntimeBuildConfig)/onnxruntime.xcframework"
        ),
        // .binaryTarget(
        //     name: "onnxruntime-framework",
        //     url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.26.0.zip",
        //     checksum: "08502ec252f6f03ebee6e729cbe0525c777b47daa76d3bc8c04bba82201d8a36"
        // )
        .binaryTarget(
            name: "onnxruntime-extensions-framework",
            url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-extensions-c-0.13.0.zip",
            checksum: "346522d1171d4c99cb0908fa8e4e9330a4a6aad39cd83ce36eb654437b33e6b5"
        ),
    ],
    swiftLanguageModes: [.v6],
    cxxLanguageStandard: .cxx17
)
