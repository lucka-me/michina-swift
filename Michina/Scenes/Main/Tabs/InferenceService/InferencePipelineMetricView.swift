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
                outputSection(output: output)
            }
            
            if metric.category != nil {
                ForEach(InferenceModel.Category.allCases) { category in
                    if let metrics = metric.models[category] {
                        modelSection(category: category, metrics: metrics)
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
                "Processed",
                value: metric.totalCount,
                format: .number
            )
            
            LabeledContent(
                "Success",
                value: metric.successCount,
                format: .number
            )
            
            LabeledContent(
                "Failure",
                value: metric.failureCount,
                format: .number
            )
        } header: {
            Text("Results")
        }
    }
    
    @ViewBuilder
    var elapsesSection: some View {
        Section {
            LabeledContent(
                "Average",
                value: metric.averageElapse,
                format: .elapse
            )
            
            LabeledContent(
                "Maximal",
                value: metric.maximalElapse,
                format: .elapse
            )
            
            LabeledContent(
                "Minimal",
                value: metric.minimalElapse,
                format: .elapse
            )
        } header: {
            Text("Elapse")
        } footer: {
            Text("This elapse covers the whole process of a pipeline...")
        }
    }
}

fileprivate extension InferencePipelineMetricView {
    @ViewBuilder
    func outputSection(output: InferencePipelineOutputMetric) -> some View {
        Section("Output") {
            switch output {
            case .facialRecognition(let metric):
                outputSectionContent(metric: metric)
            case .characterRecognition(let metric):
                outputSectionContent(metric: metric)
            }
        }
    }
    
    @ViewBuilder
    func outputSectionContent(
        metric: InferencePipelineOutputMetric.FacialRecognition
    ) -> some View {
        LabeledContent("Image with Face", value: metric.imageWithFacesCount, format: .number)
        LabeledContent("Face", value: metric.faceCount, format: .number)
    }
    
    @ViewBuilder
    func outputSectionContent(
        metric: InferencePipelineOutputMetric.CharacterRecognition
    ) -> some View {
        LabeledContent("Image with Character", value: metric.imageWithCharactersCount, format: .number)
        LabeledContent("Character Box", value: metric.characterBoxCount, format: .number)
        LabeledContent("Character", value: metric.characterCount, format: .number)
    }
}

fileprivate extension InferencePipelineMetricView {
    @ViewBuilder
    func modelSection(
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
