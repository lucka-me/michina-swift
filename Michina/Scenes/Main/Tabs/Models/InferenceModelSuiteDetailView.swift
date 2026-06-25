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
                Section("InferenceModelSuiteDetailView.Download") {
                    ProgressView(progress)
                }
            }
            
            ForEach(InferenceModel.Category.allCases) { category in
                if let model = suite.models[category] {
                    section(model: model)
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
            
            LabeledContent("InferenceModelSuiteDetailView.Glance.Provider") {
                Text(suite.provider.titleKey)
            }
            
            if suite.isVerified {
                Label(
                    "InferenceModelSuiteDetailView.Glance.Verified",
                    systemImage: "checkmark.seal"
                )
                .foregroundStyle(.green)
            } else {
                Label(
                    "InferenceModelSuiteDetailView.Glance.NotVerified",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.red)
            }
        }
        .buttonStyle(.link)
    }
    
    @ViewBuilder
    var linksSection: some View {
        Section {
            Link("InferenceModelSuiteDetailView.Links.Homepage", destination: suite.homepageURL)
            if !suite.isBuiltin {
                let directoryURL = suite.directoryURL(in: cache.cacheDirectory)
                if FileManager.default.fileExists(at: directoryURL) {
                    Button("InferenceModelSuiteDetailView.Links.OpenDirectory") {
                        NSWorkspace.shared.open(directoryURL)
                    }
                }
            }
            
            Button("InferenceModelSuiteDetailView.Links.RunInference") {
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
    func section(model: InferenceModel) -> some View {
        Section {
            if model.isBuiltin {
                Text("InferenceModelSuiteDetailView.Model.Builtin")
            } else {
                if let size = model.contentSize(in: cache.cacheDirectory) {
                    LabeledContent(
                        "InferenceModelSuiteDetailView.Model.ContentSize",
                        value: size,
                        format: .byteCount(style: .file)
                    )
                }
                
                LabeledContent("InferenceModelSuiteDetailView.Model.Compatibility") {
                    if suite.isVerified {
                        Text(model.compatibility.titleKey)
                            .foregroundStyle(model.compatibility.color)
                            .help(model.compatibility.helpTitleKey)
                    } else {
                        Text("InferenceModel.Compatibility.Unknown")
                            .foregroundStyle(.yellow)
                    }
                }
                
                if cache.sessions[model] != nil {
                    LabeledContent("InferenceModelSuiteDetailView.Model.Loaded") {
                        Button("InferenceModelSuiteDetailView.Model.Unload") {
                            cache.unload(for: model)
                        }
                    }
                } else if let progress = cache.loadProgresses[model] {
                    ProgressView(progress)
                } else {
                    LabeledContent("InferenceModelSuiteDetailView.Model.NotLoaded") {
                        Button("InferenceModelSuiteDetailView.Model.Load") {
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
