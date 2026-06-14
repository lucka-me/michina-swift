//
//  ConstrainedTaskGroup.swift
//  Michina
//
//  Created by Lucka on 2024-10-10.
//

import Foundation

actor ConstrainedTaskGroup<ContinuationResult: Sendable> {
    let maxTaskCount: Int
    
    private var currentTaskCount = 0
    private var pendingTaskContinuations: [ CheckedContinuation<ContinuationResult?, Never> ] = [ ]
    
    init(maxTaskCount: Int = ProcessInfo.processInfo.processorCount) {
        self.maxTaskCount = maxTaskCount
    }
}

extension ConstrainedTaskGroup {
    func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) (
            ContinuationResult?
        ) async throws -> (Result, ContinuationResult?)
    ) async throws -> Result {
        let previousContinuationResult = await nextSlot()
        
        var currentContinuationResult: ContinuationResult? = nil
        defer {
            openSlot(with: currentContinuationResult)
        }
        
        let task = Task.detached(name: name, priority: priority) {
            try await operation(previousContinuationResult)
        }
        let results = try await task.value
        currentContinuationResult = results.1
        return results.0
    }
    
    func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) (
            ContinuationResult?
        ) async -> (Result, ContinuationResult?)
    ) async -> Result {
        let previousContinuationResult = await nextSlot()
        
        var currentContinuationResult: ContinuationResult? = nil
        defer {
            openSlot(with: currentContinuationResult)
        }
        
        let task = Task.detached(name: name, priority: priority) {
            await operation(previousContinuationResult)
        }
        let results = await task.value
        currentContinuationResult = results.1
        return results.0
    }
}
    
extension ConstrainedTaskGroup {
    func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async throws -> Result
    ) async throws -> Result {
        let _ = await nextSlot()
        
        defer {
            openSlot(with: nil)
        }
        
        return try await Task
            .detached(name: name, priority: priority, operation: operation)
            .value
    }
    
    func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async -> Result
    ) async -> Result {
        let _ = await nextSlot()
        
        defer {
            openSlot(with: nil)
        }
        
        return await Task
            .detached(name: name, priority: priority, operation: operation)
            .value
    }
}

fileprivate extension ConstrainedTaskGroup {
    func nextSlot() async -> ContinuationResult? {
        let result: ContinuationResult?
        if currentTaskCount < maxTaskCount {
            result = nil
        } else {
            result = await withCheckedContinuation {
                self.pendingTaskContinuations.insert($0, at: 0)
            }
        }
        
        currentTaskCount += 1
        
        return result
    }
    
    func openSlot(with result: ContinuationResult?) {
        currentTaskCount -= 1
        if currentTaskCount < maxTaskCount, let continuation = pendingTaskContinuations.popLast() {
            continuation.resume(returning: result)
        }
    }
}
