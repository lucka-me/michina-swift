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
        with taskScheduling: some ConstrainedTaskScheduling,
        reporting progress: Progress?
    ) async throws {
        progress?.kind = .file
        progress?.fileOperationKind = .downloading
        
        let components = ModelSuiteNameComponents(from: suite.name)
        
        let items: [ DownloadItem ]
        if progress == nil {
            items = ModelSuiteNameComponents.Category.allCases.map { category in
                .init(
                    source: components.modelDownloadURL(of: category),
                    destination: suite.models[category.modelCategory]!
                        .modelFileURL(in: cacheDirectory),
                    size: 1
                )
            }
        } else {
            // Collect sizes for reporting progress
            items = try await withThrowingTaskGroup { group in
                for category in ModelSuiteNameComponents.Category.allCases {
                    group.addTask {
                        let source = components.modelRawDataQueryURL(of: category)
                        let destination = suite.models[category.modelCategory]!
                            .modelFileURL(in: cacheDirectory)
                        
                        return if let fileSize = destination.fileSize {
                            DownloadItem(
                                source: source,
                                destination: destination,
                                size: fileSize
                            )
                        } else {
                            try await taskScheduling.addDataTask(
                                for: .init(
                                    url: components.modelRawDataQueryURL(of: category)
                                )
                            ) { data, _ in
                                let rawData = try JSONDecoder()
                                    .decode(ModelRawData.self, from: data)
                                 
                                return DownloadItem(
                                    source: source,
                                    destination: destination,
                                    size: rawData.Data.MetaContent.Size
                                )
                            }
                        }
                    }
                }
                
                return try await group.reduce(into: [ ]) { $0.append($1) }
            }
        }
        
        progress?.fileTotalCount = items.count
        progress?.completedUnitCount = 0
        progress?.totalUnitCount = items.reduce(0) { $0 + $1.size }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    try await taskScheduling.addDownloadTask(
                        from: item.source,
                        to: item.destination,
                        reporting: progress?.addChild(for: item.size, as: item.size)
                    )
                }
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

fileprivate struct ModelRawData : Decodable {
    struct MetaContentObject: Decodable {
        var Size: Int64
    }
    
    struct DataObject: Decodable {
        var MetaContent: MetaContentObject
    }
    
    var Data: DataObject
}

fileprivate struct ModelSuiteNameComponents {
    enum Category: String, CaseIterable {
        case detection = "det"
        case recognition = "rec"
        
        var modelCategory: InferenceModel.Category {
            switch self {
            case .detection: .detection
            case .recognition: .recognition
            }
        }
    }
    
    let language: String
    let versionName: String
    let scale: String
    
    init(from suiteName: String) {
        // PP-OCRv5_server
        // <version_name>_<scale>
        // EN__PP-OCRv5_mobile
        // [<lang>__]<name>_<scale>
        
        let startIndex: String.Index
        if let splitterRange = suiteName.firstRange(of: "__") {
            self.language = suiteName[..<splitterRange.lowerBound].lowercased()
            startIndex = splitterRange.upperBound
        } else {
            self.language = "ch"
            startIndex = suiteName.startIndex
        }
        let components = suiteName[startIndex...].split(separator: "_")
        
        self.versionName = .init(components[0])
        self.scale = .init(components[1])
    }
    
    func modelRawDataQueryURL(of category: Category) -> URL {
        RapidOCREndpoint.url
            .appending(components: "api", "v1", "models")
            .appending(path: RapidOCREndpoint.repository)
            .appending(components: "repo", "raw")
            .appending(
                queryItems: [
                    .init(name: "Revision", value: RapidOCREndpoint.branch),
                    .init(
                        name: "FilePath",
                        value: [
                            "onnx", versionName, category.rawValue,
                            modelFilename(of: category).appending(".onnx")
                        ].joined(separator: "/")
                    ),
                    .init(name: "Needmeta", value: "true")
                ]
            )
    }
    
    // https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/master/onnx/PP-OCRv5/det/ch_PP-OCRv5_det_server.onnx
    // https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/master/onnx/PP-OCRv5/rec/ch_PP-OCRv5_rec_server.onnx
    // <endpoint>/models/<repository>/resolve/<branch>/onnx/<name>/<model_category>/<lang>_<name>_<model_category>_<scale>.onnx
    func modelDownloadURL(of category: Category) -> URL {
        RapidOCREndpoint.url
            .appending(component: "models")
            .appending(path: RapidOCREndpoint.repository)
            .appending(components: "resolve", RapidOCREndpoint.branch)
            .appending(components: "onnx", versionName, category.rawValue)
            .appending(component: modelFilename(of: category))
            .appendingPathExtension("onnx")
    }
    
    private func modelFilename(of category: Category) -> String {
        [
            modelLanguage(of: category),
            versionName, category.rawValue,
            scale
        ]
        .joined(separator: "_")
    }
    
    private func modelLanguage(of category: Category) -> String {
        switch category {
        case .detection: "ch"
        case .recognition: self.language
        }
    }
}

fileprivate struct DownloadItem {
    let source: URL
    let destination: URL
    let size: Int64
}
