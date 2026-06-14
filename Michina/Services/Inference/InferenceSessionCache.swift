//
//  InferenceSessionCache.swift
//  Michina
//
//  Created by Lucka on 2026-05-27.
//

import Foundation
import Magearna

@Observable
@MainActor
final class InferenceSessionCache {
    nonisolated let cacheDirectory: URL
    
    private(set) var loadProgresses: [ InferenceModel : Progress ] = [ : ]
    private(set) var fetchProgresses: [ ModelSuite : Progress ] = [ : ]
    
    private(set) var sessions: [ InferenceModel : InferenceSession ] = [ : ]
    
    @ObservationIgnored
    private var loadContinuations: [ InferenceModel : [ CheckedContinuation<InferenceSession, Error> ] ] = [ : ]
    
    @ObservationIgnored
    private var fetchContinuations: [ ModelSuite : [ CheckedContinuation<Void, Error> ] ] = [ : ]
    
    @ObservationIgnored
    private var touchInstants: [ InferenceModel : ContinuousClock.Instant ] = [ : ]
    
    private let touchContinuation: AsyncStream<InferenceModel>.Continuation
    
    private let settings = InferenceServiceSettings.shared.session
    
    init(
        cacheDirectory: URL = .applicationSupportDirectory.appending(component: "Models")
    ) {
        self.cacheDirectory = cacheDirectory
        let (touchStream, touchContinuation) = AsyncStream.makeStream(
            of: InferenceModel.self,
            bufferingPolicy: .bufferingOldest(1)
        )
        self.touchContinuation = touchContinuation
        Task(name: "InferenceSessionCache.Touch", priority: .background) {
            try await self.handle(touchStream: touchStream)
        }
    }
}

extension InferenceSessionCache {
    typealias ModelSuite = InferenceModelSuite
}

extension InferenceSessionCache {
    static let `default`: InferenceSessionCache = .init()
}

extension InferenceSessionCache {
    func load(for model: InferenceModel) async throws -> InferenceSession? {
        guard !model.isBuiltin else {
            return nil
        }
        if let session = sessions[model] {
            touch(model: model)
            return session
        }
        
        guard loadContinuations[model] == nil else {
            return try await withCheckedThrowingContinuation {
                loadContinuations[model]!.append($0)
            }
        }
        
        loadContinuations[model] = [ ]
        loadProgresses[model] = .init()
        defer {
            loadContinuations.removeValue(forKey: model)
            loadProgresses.removeValue(forKey: model)
        }
        
        let session: InferenceSession
        do {
            if !FileManager.default.fileExists(at: model.modelFileURL(in: cacheDirectory)) {
                try await fetch(suite: model.suite)
            }
            
            let options = settings.inferenceSessionOptions
            let taskName = model.id.replacingOccurrences(of: "/", with: ".")
            session = try await Task
                .detached(name: "InferenceSession.\(taskName)", priority: .utility) {
                    try InferenceSession(model, in: self.cacheDirectory, options: options)
                }
                .value
            sessions[model] = session
            touch(model: model)
            loadContinuations[model]!.forEach { $0.resume(returning: session) }
        } catch {
            loadContinuations[model]!.forEach { $0.resume(throwing: error) }
            throw error
        }
        
        return session
    }
    
    func load(
        for models: [ InferenceModel ]
    ) async throws -> [ InferenceModel.Category : InferenceSession ]  {
        try await withThrowingTaskGroup(
            of: InferenceSession?.self
        ) { @Sendable group in
            for model in models {
                group.addTask {
                    try await self.load(for: model)
                }
            }
            
            return try await group.reduce(into: [ : ]) { partial, result in
                if let result {
                    partial[result.model.category] = result
                }
            }
        }
    }
}

extension InferenceSessionCache {
    func unload(for model: InferenceModel) {
        sessions.removeValue(forKey: model)
        touchInstants.removeValue(forKey: model)
    }
    
    func unload(for models: [ InferenceModel ]) {
        for model in models {
            unload(for: model)
        }
    }
}

extension InferenceSessionCache {
    func terminate() {
        self.touchContinuation.finish()
    }
}

fileprivate extension InferenceSessionCache {
    func touch(model: InferenceModel) {
        touchInstants[model] = .now
        touchContinuation.yield(model)
    }
    
    func handle(touchStream: AsyncStream<InferenceModel>) async throws {
        for await _ in touchStream {
            while let oldestInstant = touchInstants.min(by: { $0.value < $1.value })?.value {
                try await Task.sleep(until: oldestInstant + .seconds(settings.timeToLive))
                let deadline = ContinuousClock.now - .seconds(settings.timeToLive)
                unload(
                    for: touchInstants
                        .filter { $0.value < deadline }
                        .map(\.key)
                )
            }
        }
    }
}

fileprivate extension InferenceSessionCache {
    func fetch(suite: ModelSuite) async throws {
        guard fetchContinuations[suite] == nil else {
            let _: Void = try await withCheckedThrowingContinuation {
                fetchContinuations[suite]!.append($0)
            }
            return
        }
        
        let progress = Progress()
        
        fetchContinuations[suite] = [ ]
        fetchProgresses[suite] = progress
        defer {
            fetchContinuations.removeValue(forKey: suite)
            fetchProgresses.removeValue(forKey: suite)
        }
        
        do {
            try await suite.fatch(to: cacheDirectory, reporting: progress)
            fetchContinuations[suite]!.forEach { $0.resume() }
        } catch {
            fetchContinuations[suite]!.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
