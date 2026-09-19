//
//  InferencePipelineMetricView.swift
//  Michina
//
//  Created by Lucka on 2026-05-26.
//

import Magearna
import SwiftUI

struct InferencePipelineMetricView : View {
    private let metric: InferencePipelineMetric
    
    init(metric: InferencePipelineMetric) {
        self.metric = metric
    }
    
    var body: some View {
        Form {
            resultsSection
            
            if metric.totalCount > 0 {
                elapsesSection
            }
            
            if let output = metric.output {
                section(output: output)
            }
            
            if metric.category != nil {
                ForEach(InferenceModel.Category.allCases) { category in
                    if let metrics = metric.models[category] {
                        section(category: category, metrics: metrics)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

fileprivate extension InferencePipelineMetricView {
    @ViewBuilder
    var resultsSection: some View {
        Section {
            LabeledContent(
                "InferencePipelineMetricView.Results.TotalCount",
                value: metric.totalCount,
                format: .number
            )
            
            LabeledContent(
                "ResultCount.Success",
                value: metric.successCount,
                format: .number
            )
            
            LabeledContent(
                "ResultCount.Failure",
                value: metric.failureCount,
                format: .number
            )
        } header: {
            Text("InferencePipelineMetricView.Results")
        }
    }
    
    @ViewBuilder
    var elapsesSection: some View {
        Section {
            LabeledContent(
                "InferencePipelineMetricView.Elapse.Average",
                value: metric.averageElapse,
                format: .elapse
            )
            
            LabeledContent(
                "InferencePipelineMetricView.Elapse.Maximal",
                value: metric.maximalElapse,
                format: .elapse
            )
            
            LabeledContent(
                "InferencePipelineMetricView.Elapse.Minimal",
                value: metric.minimalElapse,
                format: .elapse
            )
        } header: {
            Text("InferencePipelineMetricView.Elapse")
        } footer: {
            Text("InferencePipelineMetricView.Elapse.Footer")
        }
    }
}

fileprivate extension InferencePipelineMetricView {
    @ViewBuilder
    func section(output: InferencePipelineOutputMetric) -> some View {
        Section("InferencePipelineMetricView.Output") {
            switch output {
            case .facialRecognition(let metric):
                sectionContent(metric: metric)
            case .characterRecognition(let metric):
                sectionContent(metric: metric)
            }
        }
    }
    
    @ViewBuilder
    func sectionContent(
        metric: InferencePipelineOutputMetric.FacialRecognition
    ) -> some View {
        LabeledContent(
            "InferencePipelineMetricView.Output.ImageWithFacesCount",
            value: metric.imageWithFacesCount,
            format: .number
        )
        LabeledContent(
            "InferencePipelineMetricView.Output.faceCount",
            value: metric.faceCount,
            format: .number
        )
    }
    
    @ViewBuilder
    func sectionContent(
        metric: InferencePipelineOutputMetric.CharacterRecognition
    ) -> some View {
        LabeledContent(
            "InferencePipelineMetricView.Output.ImageWithCharactersCount",
            value: metric.imageWithCharactersCount,
            format: .number
        )
        LabeledContent(
            "InferencePipelineMetricView.Output.CharacterBoxCount",
            value: metric.characterBoxCount,
            format: .number
        )
        LabeledContent(
            "InferencePipelineMetricView.Output.CharacterCount",
            value: metric.characterCount,
            format: .number
        )
    }
}

fileprivate extension InferencePipelineMetricView {
    @ViewBuilder
    func section(
        category: InferenceModel.Category,
        metrics: [ InferenceModelMetric ]
    ) -> some View {
        Section {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(metric.model.suiteName)
                            .lineLimit(2)
                        Spacer()
                        Text(metric.totalCount, format: .number)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .center) {
                        Text(metric.minimalElapse, format: .elapse(fractionalPartLength: 2))
                        Spacer()
                        Text(metric.averageElapse, format: .elapse(fractionalPartLength: 2))
                        Spacer()
                        Text(metric.maximalElapse, format: .elapse(fractionalPartLength: 2))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .monospaced()
        } header: {
            Label(category)
        }
    }
}
