//
//  ImmichAppEndpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation
import HTTPTypesFoundation
import SwiftProtobuf

public extension InferenceModelSuite.Provider {
    struct ImmichAppEndpoint : ExternalEndpoint, MirrorableEndpoint {
        private let baseURL: URL
        
        public init(baseURL: URL) {
            self.baseURL = baseURL
        }
        
        public func homepageURL(of suite: InferenceModelSuite) -> URL {
            baseURL.appending(components: Self.namespace, suite.name)
        }
        
        public func fetch(
            suite: InferenceModelSuite,
            to cacheDirectory: URL,
            with taskScheduling: some ConstrainedTaskScheduling,
            reporting progress: Progress?
        ) async throws {
            progress?.kind = .file
            progress?.fileOperationKind = .downloading
            
            let information: ModelsInformation = try await taskScheduling.addDataTask(
                from: baseURL
                    .appending(components: "api", "models")
                    .appending(components: Self.namespace, suite.name)
            )
            
            var sources: [ Source ]
            
            if progress == nil {
                sources = information.siblings.compactMap { sibling in
                    guard
                        !sibling.rfilename.hasSuffix(".armnn"),
                        !sibling.rfilename.hasSuffix(".rknn")
                    else {
                        return nil
                    }
                    return .init(
                        repository: suite.name,
                        revision: information.sha,
                        path: sibling.rfilename,
                        size: 1
                    )
                }
            } else {
                // Collect sizes for reporting progress
                sources = try await withThrowingTaskGroup { group in
                    for sibling in information.siblings {
                        guard
                            !sibling.rfilename.hasSuffix(".armnn"),
                            !sibling.rfilename.hasSuffix(".rknn")
                        else {
                            continue
                        }
                        
                        group.addTask {
                            try await source(
                                suite: suite,
                                revision: information.sha,
                                path: sibling.rfilename,
                                cacheDirectory: cacheDirectory,
                                with: taskScheduling
                            )
                        }
                    }
                    
                    return try await group.reduce(into: [ ]) { $0.append($1) }
                }
            }
            
            let modelStartIndex = sources.partition(by: \.isModelFile)
            
            progress?.fileTotalCount = sources.count
            progress?.completedUnitCount = 0
            progress?.totalUnitCount = sources.reduce(0) { $0 + $1.size }
            
            let directoryURL = suite.directoryURL(in: cacheDirectory)
            
            try await withThrowingTaskGroup { group in
                for source in sources[..<modelStartIndex] {
                    group.addTask {
                        try await taskScheduling.addDownloadTask(
                            from: resolvingURL(for: source),
                            to: directoryURL.appending(path: source.path),
                            reporting: progress?.addChild(for: source.size, as: source.size)
                        )
                    }
                }
                
                try await group.waitForAll()
                
                // Download model.onnx files after all other files.
                for source in sources[modelStartIndex...] {
                    group.addTask {
                        try await taskScheduling.addDownloadTask(
                            from: resolvingURL(for: source),
                            to: directoryURL.appending(path: source.path),
                            reporting: progress?.addChild(for: source.size, as: source.size)
                        )
                    }
                }
                
                try await group.waitForAll()
            }
            
            if
                suite.category == .facialRecognition,
                let model = suite.models[.recognition]
            {
                try Self.addBatchDimension(for: model, in: cacheDirectory)
            }
        }
    }
}

public extension InferenceModelSuite.Provider.ImmichAppEndpoint {
    static let `default` = Self.init(baseURL: defaultBaseURL)
}

public extension InferenceModelSuite.Provider.Endpoint where
Self == InferenceModelSuite.Provider.ImmichAppEndpoint {
    @inlinable static var immichApp: Self {
        .default
    }
    
    @inlinable static func immichApp(baseURL: URL) -> Self {
        .init(baseURL: baseURL)
    }
}

public extension InferenceModelSuite.Provider.ExternalEndpoint where
Self == InferenceModelSuite.Provider.ImmichAppEndpoint {
    @inlinable static var immichApp: Self {
        .default
    }
    
    @inlinable static func immichApp(baseURL: URL) -> Self {
        .init(baseURL: baseURL)
    }
}

public extension InferenceModelSuite.Provider.MirrorableEndpoint where
Self == InferenceModelSuite.Provider.ImmichAppEndpoint {
    @inlinable static var immichApp: Self {
        .default
    }
    
    @inlinable static func immichApp(baseURL: URL) -> Self {
        .init(baseURL: baseURL)
    }
}

fileprivate extension InferenceModelSuite.Provider.ImmichAppEndpoint {
    static let defaultBaseURL = URL(string: "https://huggingface.co")!
    static let namespace = "immich-app"
}

fileprivate extension InferenceModelSuite.Provider.ImmichAppEndpoint {
    func source(
        suite: InferenceModelSuite,
        revision: String,
        path: String,
        cacheDirectory: URL,
        with taskScheduling: some ConstrainedTaskScheduling
    ) async throws -> Source {
        let destination = suite
            .directoryURL(in: cacheDirectory)
            .appending(path: path)
        if let fileSize = destination.fileSize {
            return .init(
                repository: suite.name,
                revision: revision,
                path: path,
                size: fileSize
            )
        }
        let treeSize: TreeSize = try await taskScheduling.addDataTask(
            from: baseURL
                .appending(components: "api", "models")
                .appending(components: Self.namespace, suite.name)
                .appending(components: "treesize", revision)
                .appending(path: path)
        )
        let source = Source(
            repository: suite.name,
            revision: revision,
            path: path,
            size: treeSize.size
        )
        guard source.shouldPreDownload else {
            return source
        }
        
        // Pre download small files
        try await taskScheduling.addDownloadTask(
            from: resolvingURL(for: source),
            to: suite.directoryURL(in: cacheDirectory).appending(path: source.path),
            reporting: nil
        )
        
        return source
    }
    
    func resolvingURL(for source: Source) -> URL {
        baseURL
            .appending(components: Self.namespace, source.repository)
            .appending(components: "resolve", source.revision)
            .appending(path: source.path)
    }
}

fileprivate extension InferenceModelSuite.Provider.ImmichAppEndpoint {
    static func addBatchDimension(for model: InferenceModel, in cacheDirectory: URL) throws {
        let fileURL = model.modelFileURL(in: cacheDirectory)
        var modelProto = try ONNXModelProto(serializedBytes: Data(contentsOf: fileURL))
        modelProto.graph.input[0].type.tensorType.shape.dim[0].dimParam = "batch"
        modelProto.graph.output[0].type.tensorType.shape.dim[0].dimParam = "batch"
        try modelProto.serializedData().write(to: fileURL)
    }
}

fileprivate struct ModelsInformation : Decodable {
    struct Sibling : Decodable {
        var rfilename: String
    }
    
    var sha: String
    var siblings: [ Sibling ]
}

fileprivate struct TreeSize : Decodable {
    var size: Int64
}

fileprivate struct Source {
    let repository: String
    let revision: String
    let path: String
    let size: Int64
    
    init(repository: String, revision: String, path: String, size: Int64) {
        self.repository = repository
        self.revision = revision
        self.path = path
        self.size = size
    }
    
    var shouldPreDownload: Bool {
        !isModelFile && size <= 1024 * 1024
    }
    
    var isModelFile: Bool {
        path.hasSuffix("model.onnx")
    }
}
