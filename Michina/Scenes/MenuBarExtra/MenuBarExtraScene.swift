//
//  MenuBarExtraScene.swift
//  Michina
//
//  Created by Lucka on 2026-06-08.
//

import Magearna
import SwiftUI

struct MenuBarExtraScene : Scene {
    @State private var settings = AppSettings.shared
    
    var body: some Scene {
        MenuBarExtra(isInserted: $settings.insertMenuBarExtra) {
            VStack(alignment: .leading, spacing: 8) {
                WebServiceBlock()
                    .blockStyle()
                
                InferenceServiceBlock()
                    .blockStyle()
                
                LinksBlock()
                    .blockStyle()
            }
            .padding(8)
            .containerShape(.rect(cornerRadius: 16))
        } label: {
            MenuBarExtraLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
@Observable
fileprivate final class SceneValues {
    private struct Storage {
        @AppStorage("MenuBarExtraScene.PresentCetrgory")
        var presentCategory: InferenceModelSuite.Category?
    }
    
    static let shared = SceneValues()
    
    var presentCategory: InferenceModelSuite.Category? {
        didSet { storage.presentCategory = presentCategory }
    }
    
    private let storage = Storage()
    
    private init() {
        self.presentCategory = storage.presentCategory
    }
}

fileprivate struct MenuBarExtraLabel : View {
    @State private var values = SceneValues.shared
    
    @State private var service = WebService.shared
    @State private var metrics = InferenceServiceMetrics.shared
    
    var body: some View {
        Label(value, format: .number, systemImage: systemImage)
            .monospaced()
            .symbolVariant(.fill)
            .labelStyle(.titleAndIcon)
    }
    
    private var value: Int {
        metrics.runningPipelineCounts[values.presentCategory]?.last?.count ?? 0
    }
    
    private var systemImage: String {
        service.status.isRunning ? "sparkles.rectangle.stack" : "pause"
    }
}

fileprivate struct WebServiceBlock : View {
    @State private var service = WebService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("Web Service")
                
                Spacer()
                
                Toggle(
                    "Toggle Web Service",
                    isOn: .init(
                        get: { service.status.isRunning },
                        set: { Task(operation: $0 ? service.start : service.stop) }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack {
                Text("\(service.clientMetrics.count) clients")
                
                Spacer()
                
                switch service.status {
                case .paused:
                    Text("Paused")
                case .running(let port):
                    Text("Port \(port, format: .number.grouping(.never))")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .monospaced()
    }
}

fileprivate struct InferenceServiceBlock : View {
    @State private var values = SceneValues.shared
    
    @State private var metrics = InferenceServiceMetrics.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("Inference Service")
                
                Spacer()
                
                Picker("Category", selection: $values.presentCategory) {
                    Text("All")
                        .tag(InferenceModelSuite.Category?.none)
                    
                    ForEach(InferenceModelSuite.Category.allCases) { category in
                        Label(category)
                            .tag(category)
                    }
                    .labelStyle(.iconOnly)
                }
                .pickerStyle(.segmented)
                .controlSize(.mini)
                .labelsHidden()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            row(for: metrics.pipelines[values.presentCategory]!)
            
            PipelineCountChart(
                counts: metrics.runningPipelineCounts[values.presentCategory]!,
                style: .compact
            )
            .frame(height: 60)
        }
        .monospaced()
    }
    
    @ViewBuilder
    func row(for pipelineMetric: InferencePipelineMetric) -> some View {
        HStack(alignment: .center) {
            Text(
                pipelineMetric.totalCount,
                format: .number.grouping(.never).precision(.integerLength(6...))
            )
            .font(.system(size: 24, weight: .medium))
            
            Spacer()
            
            Grid(alignment: .leading, horizontalSpacing: 6) {
                GridRow {
                    Text("Success")
                    Text(pipelineMetric.successCount, format: .number)
                        .gridColumnAlignment(.trailing)
                }
                .foregroundStyle(pipelineMetric.successCount > 0 ? .green : .secondary)
                GridRow {
                    Text("Failure")
                    Text(pipelineMetric.failureCount, format: .number)
                }
                .foregroundStyle(pipelineMetric.failureCount > 0 ? .red : .secondary)
            }
            .font(.caption)
        }
    }
}

fileprivate struct LinksBlock : View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        HStack(alignment: .center) {
            Button("Open App") {
                openWindow(id: MainScene.id)
            }
            
            SettingsLink()
                .labelStyle(.iconOnly)
            
            Spacer()
            
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        }
        .buttonStyle(.bordered)
    }
}

fileprivate extension View {
    func blockStyle() -> some View {
        self
            .lineLimit(1)
            .padding(8)
            .background {
                ConcentricRectangle(
                    corners: .concentric(minimum: 8),
                    isUniform: true
                )
                .fill(.thinMaterial.opacity(0.5))
                .stroke(.separator)
            }
    }
}
