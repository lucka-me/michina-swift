//
//  InferenceModelSuiteDetailView.swift
//  Michina
//
//  Created by Lucka on 2026-05-20.
//

import Magearna
import SwiftUI

struct InferenceModelSuiteDetailView : View {
    @Environment(\.alert) private var alert
    @Environment(\.openWindow) private var openWindow
    
    @State private var cache = InferenceService.default.cache
    
    private let suite: InferenceModelSuite
    
    init(suite: InferenceModelSuite) {
        self.suite = suite
    }
    
    var body: some View {
        Form {
            glanceSection
            linksSection
            
            if let progress = cache.fetchProgresses[suite] {
                Section("Download") {
                    ProgressView(progress)
                }
            }
            
            ForEach(InferenceModel.Category.allCases) { category in
                if let model = suite.models[category] {
                    modelSection(model)
                }
            }
        }
        .formStyle(.grouped)
    }
}

fileprivate extension InferenceModelSuiteDetailView {
    @ViewBuilder
    var glanceSection: some View {
        Section {
            Text(suite.name)
                .monospaced()
                .textSelection(.enabled)
            
            LabeledContent("Provided by") {
                Label(suite.provider)
                    .labelStyle(.titleOnly)
            }
            
            if suite.isVerified {
                Label("Verified", systemImage: "checkmark.seal")
                    .foregroundStyle(.green)
            } else {
                Label("Not Verified", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
        .buttonStyle(.link)
    }
    
    @ViewBuilder
    var linksSection: some View {
        Section {
            Link("Open Homepage", destination: suite.homepageURL)
            if !suite.isBuiltin {
                let directoryURL = suite.directoryURL(in: cache.cacheDirectory)
                if FileManager.default.fileExists(at: directoryURL) {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.open(directoryURL)
                    }
                }
            }
            
            Button("Run a Inference") {
                openWindow(
                    value: InferenceScene.Request(
                        category: suite.category,
                        suiteName: suite.name
                    )
                )
            }
        }
        .buttonStyle(.link)
    }
}

fileprivate extension InferenceModelSuiteDetailView {
    @ViewBuilder
    func modelSection(_ model: InferenceModel) -> some View {
        Section {
            if model.isBuiltin {
                Text("Built-in Model")
            } else {
                if let size = model.contentSize(in: cache.cacheDirectory) {
                    LabeledContent(
                        "Size of Files",
                        value: size,
                        format: .byteCount(style: .file)
                    )
                }
                
                if suite.isVerified {
                    switch model.compatibility {
                    case .compatible:
                        Text("Compatible with Core ML")
                            .foregroundStyle(.green)
                    case .inefficient:
                        Text("Inefficient with Core ML")
                            .foregroundStyle(.orange)
                    case .incompatible:
                        Text("Incompatible with Core ML")
                            .foregroundStyle(.red)
                    }
                } else {
                    Text("Unknown compatibility with Core ML")
                        .foregroundStyle(.yellow)
                }
                
                if cache.sessions[model] != nil {
                    LabeledContent("Loaded") {
                        Button("Unload") {
                            cache.unload(for: model)
                        }
                    }
                } else if let progress = cache.loadProgresses[model] {
                    ProgressView(progress)
                } else {
                    LabeledContent("Not Loaded") {
                        Button("Load") {
                            alert.whenTrying {
                                let _ = try await cache.load(for: model)
                            }
                        }
                    }
                }
            }
        } header: {
            Label(model.category)
        }
    }
}

fileprivate extension InferenceModel {
    func contentSize(in cacheDirectory: URL) -> Int64? {
        let directoryURL = self.directoryURL(in: cacheDirectory)
        let fileManager = FileManager.default
        guard
            fileManager.fileExists(at: directoryURL),
            let urls = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [ .fileSizeKey ]
            )
        else {
            return nil
        }
        return urls.reduce(0) { accumulated, url in
            guard
                let values = try? url.resourceValues(forKeys: [ .fileSizeKey ]),
                let value = values.fileSize
            else {
                return accumulated
            }
            return accumulated + .init(value)
        }
    }
}
