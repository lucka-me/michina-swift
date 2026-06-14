//
//  ImmichAppEndpoint.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation
import HTTPTypesFoundation
import SwiftProtobuf

enum ImmichAppEndpoint : InferenceModelSuiteProviderEndpoint {
    static func fetch(
        suite: InferenceModelSuite,
        to cacheDirectory: URL,
        reporting progress: Progress?
    ) async throws {
        let information = try await modelInformation(
            namespace: Self.namespace,
            name: suite.name
        )
        
        var filenames = information.siblings
            .compactMap { sibling -> String? in
                guard
                    !sibling.rfilename.hasSuffix(".armnn"),
                    !sibling.rfilename.hasSuffix(".rknn")
                else {
                    return nil
                }
                
                return sibling.rfilename
            }
        let modelFilenamesStartIndex = filenames.partition {
            $0.hasSuffix("model.onnx")
        }
        
        let totalFileCount = Int64(filenames.count)
        
        progress?.completedUnitCount = 0
        progress?.totalUnitCount = totalFileCount
        
        let directoryURL = suite.directoryURL(in: cacheDirectory)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for filename in filenames[..<modelFilenamesStartIndex] {
                try group.addDownloadTask(
                    from: Self.downloadURL(
                        namespace: Self.namespace,
                        repository: suite.name,
                        revision: information.sha,
                        filename: filename
                    ),
                    to: directoryURL.appending(path: filename),
                    reporting: progress
                )
            }
            
            try await group.waitForAll()
            
            // Download model.onnx files after all other files.
            for filename in filenames[modelFilenamesStartIndex...] {
                try group.addDownloadTask(
                    from: Self.downloadURL(
                        namespace: Self.namespace,
                        repository: suite.name,
                        revision: information.sha,
                        filename: filename
                    ),
                    to: directoryURL.appending(path: filename),
                    reporting: progress
                )
            }
            
            try await group.waitForAll()
        }
        
        if
            suite.category == .facialRecognition,
            let model = suite.models[.recognition]
        {
            try addBatchDimension(for: model, in: cacheDirectory)
        }
    }
    
    static func homepageURL(of suite: InferenceModelSuite) -> URL {
        url.appending(components: namespace, suite.name)
    }
}

fileprivate extension ImmichAppEndpoint {
    static let url = URL(string: "https://huggingface.co")!
    static let namespace = "immich-app"
}

fileprivate extension ImmichAppEndpoint {
    static func downloadURL(
        namespace: String,
        repository: String,
        revision: String,
        filename: String
    ) -> URL {
        url
            .appending(components: namespace, repository)
            .appending(components: "resolve", revision)
            .appending(path: filename)
    }
    
    static func modelInformation(
        namespace: String,
        name: String
    ) async throws -> ModelInformation {
        let (body, _) = try await URLSession.shared.data(
            for: HTTPRequest(
                url: url
                    .appending(components: "api", "models")
                    .appending(components: namespace, name)
            )
        )
        
        return try JSONDecoder().decode(ModelInformation.self, from: body)
    }
}

fileprivate extension ImmichAppEndpoint {
    static func addBatchDimension(for model: InferenceModel, in cacheDirectory: URL) throws {
        let fileURL = model.modelFileURL(in: cacheDirectory)
        var modelProto = try ONNXModelProto(serializedBytes: Data(contentsOf: fileURL))
        modelProto.graph.input[0].type.tensorType.shape.dim[0].dimParam = "batch"
        modelProto.graph.output[0].type.tensorType.shape.dim[0].dimParam = "batch"
        try modelProto.serializedData().write(to: fileURL)
    }
}

fileprivate struct ModelInformation : Decodable {
    struct Sibling : Decodable {
        var rfilename: String
    }
    
    var sha: String
    var siblings: [ Sibling ]
}
