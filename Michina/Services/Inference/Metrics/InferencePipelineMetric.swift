//
//  InferencePipelineMetric.swift
//  Michina
//
//  Created by Lucka on 2026-05-25.
//

import Foundation
import Magearna

@Observable
final class InferencePipelineMetric {
    let category: InferenceModelSuite.Category?
    
    private(set) var successCount = 0
    private(set) var failureCount = 0
    
    private(set) var totalElapse = Duration.zero
    private(set) var maximalElapse = Duration.zero
    private(set) var minimalElapse = Duration.zero
    
    private(set) var models: [ InferenceModel.Category : [ InferenceModelMetric ] ] = [ : ]
    
    private(set) var output: InferencePipelineOutputMetric?
    
    init(_ category: InferenceModelSuite.Category?) {
        self.category = category
        
        output = switch category {
        case .facialRecognition:
            .facialRecognition(metric: .init())
        case .characterRecognition:
            .characterRecognition(metric: .init())
        default:
            nil
        }
    }
}

extension InferencePipelineMetric {
    static var initials: [ InferenceModelSuite.Category? : InferencePipelineMetric ] {
        InferenceModelSuite.Category.allOptionalCases
            .reduce(into: [ : ]) { partial, category in
                partial[category] = .init(category)
            }
    }
}

extension InferencePipelineMetric {
    var totalCount: Int {
        successCount + failureCount
    }
    
    var averageElapse: Duration {
        guard totalElapse > .zero else {
            return .zero
        }
        return totalElapse / totalCount
    }
}

extension InferencePipelineMetric {
    struct Report : Sendable {
        let category: InferenceModelSuite.Category
        
        fileprivate let content: Content
        
        private init(category: InferenceModelSuite.Category, content: Content) {
            self.category = category
            self.content = content
        }
    }
    
    func record(report: Report) {
        switch report.content {
        case .success(let elapse, let modelReports, let outputReport):
            recordSuccess(for: elapse, with: modelReports, output: outputReport)
        case .failure(let elapse, let modelReports):
            recordFailure(for: elapse, with: modelReports)
        }
    }
}

extension InferencePipelineMetric.Report {
    static func success<Pipeline: InferencePipeline>(
        _ pipeline: Pipeline.Type,
        since startTime: ContinuousClock.Instant,
        with models: [ InferenceModelMetric.Report ],
        output: Pipeline.Output
    ) -> Self {
        .init(
            category: pipeline.category,
            content: .success(
                elapse: ContinuousClock.now - startTime,
                modelReports: models,
                outputReport: .create(from: output)
            )
        )
    }
    
    static func failure(
        in category: InferenceModelSuite.Category,
        since startTime: ContinuousClock.Instant,
        with models: [ InferenceModelMetric.Report ]
    ) -> Self {
        .init(
            category: category,
            content: .failure(
                elapse: ContinuousClock.now - startTime,
                modelReports: models
            )
        )
    }
}

fileprivate extension InferencePipelineMetric {
    func recordSuccess(
        for elapse: Duration,
        with modelReports: [ InferenceModelMetric.Report ],
        output: InferencePipelineOutputMetric.Report?
    ) {
        self.successCount += 1
        record(elapse: elapse)
        record(reports: modelReports)
        if let output {
            self.output?.record(report: output)
        }
    }
    
    func recordFailure(
        for elapse: Duration,
        with modelReports: [ InferenceModelMetric.Report ]
    ) {
        failureCount += 1
        record(elapse: elapse)
        record(reports: modelReports)
    }
    
    func record(elapse: Duration) {
        self.totalElapse += elapse
        self.maximalElapse = max(elapse, self.maximalElapse)
        self.minimalElapse = if self.minimalElapse == .zero {
            elapse
        } else {
            min(elapse, self.minimalElapse)
        }
    }
    
    func record(reports: [ InferenceModelMetric.Report ]) {
        for report in reports {
            var metrics = self.models[report.model.category, default:  [ ]]
            let index: Int
            if let existingIndex = metrics.firstIndex(where: { $0.model == report.model }) {
                index = existingIndex
            } else {
                index = metrics.endIndex
                metrics.append(.init(model: report.model))
            }
            metrics[index].record(report: report)
            self.models[report.model.category] = metrics
        }
    }
}

fileprivate extension InferencePipelineMetric.Report {
    enum Content : Sendable {
        case success(
            elapse: Duration,
            modelReports: [ InferenceModelMetric.Report ],
            outputReport: InferencePipelineOutputMetric.Report?
        )
        case failure(elapse: Duration, modelReports: [ InferenceModelMetric.Report ])
    }
}
