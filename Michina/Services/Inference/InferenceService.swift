//
//  InferenceService.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import Foundation
import Magearna

@MainActor
final class InferenceService {
    let cache = InferenceSessionCache.default
    let metrics = InferenceServiceMetrics.shared
    
    nonisolated private let inferenceTaskGroup: ConstrainedTaskGroup<Void>
    
    init(
        maxTaskCount: Int = ProcessInfo.processInfo.processorCount
    ) {
        self.inferenceTaskGroup = .init(maxTaskCount: maxTaskCount)
    }
}

extension InferenceService {
    static let `default`: InferenceService = .init()
}

extension InferenceService {
    nonisolated func run<Pipeline: InferencePipeline>(
        _ pipelineType: Pipeline.Type,
        input: Pipeline.Input
    ) async throws -> Pipeline.Output {
        metrics.countStart(category: pipelineType.category)
        
        let startTime = ContinuousClock.now
        
        let pipeline = Pipeline(input)
        
        let output: Pipeline.Output
        do {
            let sessions = try await cache.load(for: await pipeline.models)
            try await pipeline.prepare(sessions)
            
            output = try await inferenceTaskGroup.addTask(operation: pipeline.run)
        } catch {
            // TODO: Display the error
            metrics.report(
                .failure(
                    in: pipelineType.category,
                    since: startTime,
                    with: await pipeline.modelReports
                )
            )
            throw error
        }
        
        metrics.report(
            .success(
                pipelineType,
                since: startTime,
                with: await pipeline.modelReports,
                output: output
            )
        )
        
        return output
    }
}

extension InferenceService {
    func terminate() {
        self.cache.terminate()
        self.metrics.terminate()
    }
}
