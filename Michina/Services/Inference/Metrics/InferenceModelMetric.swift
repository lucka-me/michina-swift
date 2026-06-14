//
//  InferenceModelMetric.swift
//  Michina
//
//  Created by Lucka on 2026-05-26.
//

import Foundation
import Magearna

@Observable
final class InferenceModelMetric {
    let model: InferenceModel
    
    private(set) var totalCount = Int.zero
    
    private(set) var totalElapse = Duration.zero
    private(set) var maximalElapse = Duration.zero
    private(set) var minimalElapse = Duration.zero
    
    init(model: InferenceModel) {
        self.model = model
    }
}

extension InferenceModelMetric : Identifiable {
    var id: InferenceModel {
        model
    }
}

extension InferenceModelMetric {
    var averageElapse: Duration {
        totalCount > 0 ? (totalElapse / totalCount) : .zero
    }
}

extension InferenceModelMetric {
    typealias Report = InferencePipelineModelReport
    
    func record(report: Report) {
        totalCount += 1
        totalElapse += report.elapse
        self.maximalElapse = max(report.elapse, self.maximalElapse)
        self.minimalElapse = if self.minimalElapse != .zero {
            min(report.elapse, self.minimalElapse)
        } else {
            report.elapse
        }
    }
}
