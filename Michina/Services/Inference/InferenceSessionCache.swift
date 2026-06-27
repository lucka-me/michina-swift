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
    private(set) var fetchProgresses: [ InferenceModelSuite : Progress ] = [ : ]
    
    private(set) var sessions: [ InferenceModel : InferenceSession ] = [ : ]
    
    @ObservationIgnored
    private var loadContinuations: [ InferenceModel : [ CheckedContinuation<InferenceSession, Error> ] ] = [ : ]
    
    @ObservationIgnored
    private var fetchContinuations: [ InferenceModelSuite : [ CheckedContinuation<Void, Error> ] ] = [ : ]
    
    private let fetchTaskGroup: ConstrainedTaskGroup<Void>
    
    private let touchContinuation: AsyncStream<Touching>.Continuation
    
    private let settings = InferenceServiceSettings.shared
    
    init(
        cacheDirectory: URL = .applicationSupportDirectory.appending(component: "Models")
    ) {
        self.cacheDirectory = cacheDirectory
        
        self.fetchTaskGroup = .init(
            maxTaskCount: min(4, ProcessInfo.processInfo.processorCount)
        )
        
        let (touchStream, touchContinuation) = AsyncStream.makeStream(
            of: Touching.self,
            bufferingPolicy: .unbounded
        )
        self.touchContinuation = touchContinuation
        Task.detached(name: "InferenceSessionCache.Touch", priority: .background) {
            try await self.handle(touchStream: touchStream)
        }
        if !settings.preloadModels.isEmpty {
            let models = settings.preloadModels
            Task.detached(priority: .background) {
                try await self.load(for: models, preferredLifespan: .zero)
            }
        }
    }
}

extension InferenceSessionCache {
    static let `default`: InferenceSessionCache = .init()
}

extension InferenceSessionCache {
    func load(
        for model: InferenceModel,
        preferredLifespan: Duration? = nil
    ) async throws -> InferenceSession? {
        guard !model.isBuiltin else {
            return nil
        }
        if let session = sessions[model] {
            access(model: model, preferredLifespan: preferredLifespan)
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
            
            let options = settings.session.inferenceSessionOptions
            let taskName = model.id.replacingOccurrences(of: "/", with: ".")
            session = try await Task
                .detached(name: "InferenceSession.\(taskName)", priority: .utility) {
                    try InferenceSession(model, in: self.cacheDirectory, options: options)
                }
                .value
            sessions[model] = session
            access(model: model, preferredLifespan: preferredLifespan)
            loadContinuations[model]!.forEach { $0.resume(returning: session) }
        } catch {
            loadContinuations[model]!.forEach { $0.resume(throwing: error) }
            throw error
        }
        
        return session
    }
    
    func load(
        for models: [ InferenceModel ],
        preferredLifespan: Duration? = nil
    ) async throws -> [ InferenceModel.Category : InferenceSession ]  {
        try await withThrowingTaskGroup(
            of: InferenceSession?.self
        ) { @Sendable group in
            for model in models {
                group.addTask {
                    try await self.load(
                        for: model,
                        preferredLifespan: preferredLifespan
                    )
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
        touchContinuation.yield(.init(model: model, operation: .unload))
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
    struct Touching : Sendable {
        enum Operation : Sendable {
            case access(
                instance: ContinuousClock.Instant = .now,
                preferredLifespan: Duration?
            )
            case unload
        }
        
        let model: InferenceModel
        let operation: Operation
    }
    
    func access(model: InferenceModel, preferredLifespan: Duration?) {
        touchContinuation.yield(
            .init(
                model: model,
                operation: .access(preferredLifespan: preferredLifespan)
            )
        )
    }
    
    nonisolated func handle(touchStream: AsyncStream<Touching>) async throws {
        typealias Instant = ContinuousClock.Instant
        
        var accessInstants: [ InferenceModel : Instant ] = [ : ]
        var preferredLifespans: [ InferenceModel : Duration ] = [ : ]
        var checkTasks: [ InferenceModel : Task<Void, any Error> ] = [ : ]
        
        for await touching in touchStream {
            switch touching.operation {
            case .access(let instance, let preferredLifespan):
                accessInstants[touching.model] = instance
                
                let lifespan: Duration
                if let preferredLifespan {
                    preferredLifespans[touching.model] = preferredLifespan
                    lifespan = preferredLifespan
                } else if let preferredLifespan = preferredLifespans[touching.model] {
                    lifespan = preferredLifespan
                } else {
                    lifespan = .seconds(await settings.cache.lifespan)
                }
                
                checkTasks[touching.model]?.cancel()
                if lifespan > .zero {
                    let model = touching.model
                    let deadline = instance + lifespan
                    checkTasks[touching.model] = .detached(
                        priority: .background
                    ) { [ weak self ] in
                        try await Task.sleep(until: deadline)
                        await self?.unload(for: model)
                    }
                } else {
                    // Live forever
                    checkTasks.removeValue(forKey: touching.model)
                }
            case .unload:
                checkTasks[touching.model]?.cancel()
                
                accessInstants.removeValue(forKey: touching.model)
                preferredLifespans.removeValue(forKey: touching.model)
                checkTasks.removeValue(forKey: touching.model)
            }
        }
    }
}

fileprivate extension InferenceSessionCache {
    func fetch(suite: InferenceModelSuite) async throws {
        guard fetchContinuations[suite] == nil else {
            try await withCheckedThrowingContinuation {
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
            let endpoint: InferenceModelSuite.Provider.ExternalEndpoint?
            endpoint = switch suite.provider {
            case .immichApp: settings.immichAppEndpoint
            case .rapidOCR: .rapidOCR
            case .apple: nil
            }
            
            try await endpoint?.fetch(
                suite: suite,
                to: cacheDirectory,
                with: fetchTaskGroup,
                reporting: progress
            )
            fetchContinuations[suite]!.forEach { $0.resume() }
        } catch {
            fetchContinuations[suite]!.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
