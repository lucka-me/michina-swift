//
//  RapidOCREndpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-05-26.
//

import Foundation
import HTTPTypesFoundation

enum RapidOCREndpoint : InferenceModelSuiteProviderEndpoint {
    static func fetch(
        suite: InferenceModelSuite,
        to cacheDirectory: URL,
        reporting progress: Progress?
    ) async throws {
        let components = Self.components(of: suite.name)
        
        let urls: [ (download: URL, destination: URL) ] = [
            (
                download: Self.detectionModelDownloadURL(
                    versionName: components.versionName,
                    scale: components.scale
                ),
                destination: suite.models[.detection]!.modelFileURL(in: cacheDirectory)
            ),
            (
                download: Self.recognitionModelDownloadURL(
                    language: components.language,
                    versionName: components.versionName,
                    scale: components.scale
                ),
                destination: suite.models[.recognition]!.modelFileURL(in: cacheDirectory)
            )
        ]
        
        progress?.completedUnitCount = 0
        progress?.totalUnitCount = .init(urls.count)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for pair in urls {
                try group.addDownloadTask(
                    from: pair.download,
                    to: pair.destination,
                    reporting: progress
                )
            }
            
            try await group.waitForAll()
        }
    }
    
    static func homepageURL(of suite: InferenceModelSuite) -> URL {
        .init(string: "https://rapidai.github.io/RapidOCRDocs/main/model_list/")!
    }
}

fileprivate extension RapidOCREndpoint {
    static let url = URL(string: "https://www.modelscope.cn")!
    static let repository = "RapidAI/RapidOCR"
    static let branch = "master"
}

fileprivate extension RapidOCREndpoint {
    static func components(
        of suiteName: String
    ) -> (language: String, versionName: String, scale: String) {
        // PP-OCRv5_server
        // <version_name>_<scale>
        // EN__PP-OCRv5_mobile
        // [<lang>__]<name>_<scale>
        
        let language: String
        let startIndex: String.Index
        if let splitterRange = suiteName.firstRange(of: "__") {
            language = suiteName[..<splitterRange.lowerBound].lowercased()
            startIndex = splitterRange.upperBound
        } else {
            language = "ch"
            startIndex = suiteName.startIndex
        }
        let components = suiteName[startIndex...].split(separator: "_")
        
        return (language, .init(components[0]), .init(components[1]))
    }
    
    // https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/master/onnx/PP-OCRv5/det/ch_PP-OCRv5_det_server.onnx
    // https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/master/onnx/PP-OCRv5/rec/ch_PP-OCRv5_rec_server.onnx
    // <endpoint>/models/<repository>/resolve/<branch>/onnx/<name>/<model_category>/<lang>_<name>_<model_category>_<scale>.onnx
    static func detectionModelDownloadURL(
        versionName: String,
        scale: String
    ) -> URL {
        url
            .appending(component: "models")
            .appending(path: Self.repository)
            .appending(components: "resolve", Self.branch, "onnx", versionName, "det")
            .appending(component: "ch_\(versionName)_det_\(scale)")
            .appendingPathExtension("onnx")
    }
    
    static func recognitionModelDownloadURL(
        language: String,
        versionName: String,
        scale: String
    ) -> URL {
        url
            .appending(component: "models")
            .appending(path: Self.repository)
            .appending(components: "resolve", Self.branch, "onnx", versionName, "rec")
            .appending(component: "\(language)_\(versionName)_rec_\(scale)")
            .appendingPathExtension("onnx")
    }
}
