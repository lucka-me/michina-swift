//
//  InferenceServiceMetrics.swift
//  Michina
//
//  Created by Lucka on 2026-06-06.
//

import Foundation
import Magearna

@Observable
@MainActor
final class InferenceServiceMetrics {
    private(set) var pipelines = InferencePipelineMetric.initials
    
    private(set) var runningPipelineCounts = InferenceServiceMetrics.initialPipelineCounts
    
    private let countTimer: Timer
    nonisolated private let countContinuation: AsyncStream<Counting>.Continuation
    nonisolated private let reportContinuation: AsyncStream<InferencePipelineMetric.Report>.Continuation
    
    private init() {
        let (reportStream, reportContinuation) = AsyncStream.makeStream(
            of: InferencePipelineMetric.Report.self,
            bufferingPolicy: .unbounded
        )
        let (countStream, countContinuation) = AsyncStream.makeStream(
            of: Counting.self,
            bufferingPolicy: .unbounded
        )
        
        self.countContinuation = countContinuation
        self.reportContinuation = reportContinuation
        self.countTimer = .init(fire: .now.ceiledBySecond + 1, interval: 1, repeats: true) { _ in
            countContinuation.yield(.init(category: nil, delta: 0))
        }
        RunLoop.current.add(self.countTimer, forMode: .common)
        
        Task.detached(name: "InferenceServiceMetrics.Count", priority: .background) {
            await self.handle(countStream: countStream)
        }
        Task(name: "InferenceServiceMetrics.Report", priority: .background) {
            await self.handle(reportStream: reportStream)
        }
    }
}

extension InferenceServiceMetrics {
    static let shared = InferenceServiceMetrics()
}

extension InferenceServiceMetrics {
    struct InstantCount {
        let instant: Date
        let count: Int
    }
    
    nonisolated func countStart(category: InferenceModelSuite.Category) {
        countContinuation.yield(.init(category: category, delta: 1))
    }
}

extension InferenceServiceMetrics {
    nonisolated func report(_ report: InferencePipelineMetric.Report) {
        countContinuation.yield(.init(category: report.category, delta: -1))
        reportContinuation.yield(report)
    }
}

extension InferenceServiceMetrics {
    func terminate() {
        self.countTimer.invalidate()
        self.countContinuation.finish()
        self.reportContinuation.finish()
    }
}

fileprivate extension InferenceServiceMetrics {
    struct Counting {
        let category: InferenceModelSuite.Category?
        let instant = Date.now
        let delta: Int
    }
    
    struct BufferedCounting {
        let instant: Date
        let delta: Int
    }
    
    nonisolated static let countsInterval: TimeInterval = 30
    
    nonisolated static var initialPipelineCounts: [ InferenceModelSuite.Category? : [ InstantCount ] ] {
        let now = Date.now.flooredBySecond
        let instants = stride(from: now - countsInterval, through: now, by: 1)
        return InferenceModelSuite.Category.allOptionalCases
            .reduce(into: [ : ]) { partial, category in
                partial[category] = instants.map { .init(instant: $0, count: 0) }
            }
    }
    
    nonisolated func handle(countStream: AsyncStream<Counting>) async {
        var buffer = Self.initialPipelineCounts
        
        for await counting in countStream {
            let updateCategories = if counting.category == nil {
                InferenceModelSuite.Category.allOptionalCases
            } else {
                [ counting.category, nil ]
            }
            
            for category in updateCategories {
                var counts = buffer[category]!
                defer {
                    buffer[category] = counts
                }
                if let previous = counts.last {
                    if previous.instant == counting.instant {
                        counts[counts.count - 1] = .init(
                            instant: previous.instant,
                            count: previous.count + counting.delta
                        )
                    } else {
                        counts.append(
                            .init(instant: counting.instant, count: previous.count + counting.delta)
                        )
                    }
                } else {
                    counts.append(.init(instant: counting.instant, count: counting.delta))
                }
            }
            
            if counting.category == nil {
                // Keep the interval steady.
                let deadline = counting.instant - Self.countsInterval
                for category in InferenceModelSuite.Category.allOptionalCases {
                    var counts = buffer[category]!
                    defer {
                        buffer[category] = counts
                    }
                    if
                        let index = counts.firstIndex(where: { $0.instant > deadline }),
                        index > 0
                    {
                        counts[index - 1] = .init(
                            instant: deadline,
                            count: counts[index - 1].count
                        )
                        counts.removeFirst(index - 1)
                    }
                }
                
                await MainActor.run {
                    runningPipelineCounts = buffer
                }
            }
        }
    }
}

fileprivate extension InferenceServiceMetrics {
    func handle(reportStream: AsyncStream<InferencePipelineMetric.Report>) async {
        for await report in reportStream {
            pipelines[nil]!.record(report: report)
            pipelines[report.category]!.record(report: report)
        }
    }
}
