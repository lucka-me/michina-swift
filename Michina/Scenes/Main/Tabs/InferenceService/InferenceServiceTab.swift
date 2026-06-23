//
//  InferenceServiceTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import Magearna
import SwiftUI

struct InferenceServiceTab : TabContent {
    @State private var values = ViewValues()
    
    @State private var metrics = InferenceServiceMetrics.shared
    
    @State private var isInspectorPresented = true
    @State private var selection: Selection? = nil
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            List(selection: $selection) {
                section(category: nil)
                
                ForEach(InferenceModelSuite.Category.allCases, content: section(category:))
            }
            .listStyle(.inset)
            .frame(minWidth: 300, minHeight: 400)
            .toolbar(content: toolbarContent)
            .navigationTitle("InferenceService")
            .inspector(isPresented: $isInspectorPresented, content: inspectorContent)
            .onChange(of: selection) {
                if selection != nil {
                    isInspectorPresented = true
                }
            }
        }
    }
}

fileprivate extension InferenceServiceTab {
    static let titleKey: LocalizedStringKey = "InferenceServiceTab"
    static let systemImage: String = "sparkles.rectangle.stack"
}

fileprivate extension InferenceServiceTab {
    @MainActor
    @Observable
    final class ViewValues {
        private struct Storage {
            @AppStorage("InferenceServiceTab.ShowCharts")
            var showCharts = true
        }
        
        var showCharts: Bool {
            didSet { storage.showCharts = showCharts }
        }
        
        private let storage = Storage()
        
        init() {
            self.showCharts = storage.showCharts
        }
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem {
            Toggle(
                "InferenceServiceTab.ShowCharts",
                systemImage: "chart.xyaxis.line",
                isOn: $values.showCharts
            )
        }
    }
}

fileprivate extension InferenceServiceTab {
    @ViewBuilder
    func inspectorContent() -> some View {
        if case let .category(category) = selection {
            InferencePipelineMetricView(metric: metrics.pipelines[category]!)
        } else {
            Text("InferenceServiceTab.NoSelection")
                .font(.system(.title, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

fileprivate extension InferenceServiceTab {
    @ViewBuilder
    func section(category: InferenceModelSuite.Category?) -> some View {
        Section {
            row(pipelineMetric: metrics.pipelines[category]!)
                .tag(Selection.category(category: category))
                .listRowSeparator(.visible, edges: .top)
            
            if values.showCharts {
                PipelineCountChart(counts: metrics.runningPipelineCounts[category]!)
                    .frame(height: 60)
                    .padding(.top, 12)
                    .listRowSeparator(.hidden)
            }
        } header: {
            Group {
                if let category {
                    Label(category)
                } else {
                    Label("InferenceServiceTab.Overall", systemImage: "rectangle.stack")
                }
            }
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    func row(pipelineMetric: InferencePipelineMetric) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(
                pipelineMetric.totalCount,
                format: .number.grouping(.never).precision(.integerLength(6...))
            )
            .font(.system(size: 24, weight: .medium))
            
            Grid(alignment: .leading, horizontalSpacing: 6) {
                GridRow {
                    Text("ResultCount.Success")
                    Text(pipelineMetric.successCount, format: .number)
                        .gridColumnAlignment(.trailing)
                }
                .foregroundStyle(pipelineMetric.successCount > 0 ? .green : .secondary)
                GridRow {
                    Text("ResultCount.Failure")
                    Text(pipelineMetric.failureCount, format: .number)
                }
                .foregroundStyle(pipelineMetric.failureCount > 0 ? .red : .secondary)
            }
            .font(.caption)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("InferenceServiceTab.AverageElapse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(pipelineMetric.averageElapse, format: .elapse)
            }
        }
        .monospaced()
        .lineLimit(1)
    }
}

fileprivate enum Selection: Hashable {
    case category(category: InferenceModelSuite.Category?)
}
