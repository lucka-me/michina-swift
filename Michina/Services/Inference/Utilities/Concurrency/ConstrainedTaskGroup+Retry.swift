//
//  ConstrainedTaskGroup+Retry.swift
//  Michina
//
//  Created by Lucka on 2026-05-24.
//

import Foundation

extension ConstrainedTaskGroup {
    @inlinable func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async throws -> (Result),
        retryWhen: sending @escaping @isolated(any) (
            _ condition: (attempts: Int, elapse: Duration),
            _ error: any Error
        ) async throws -> Bool
    ) async throws -> Result {
        try await self.addTask(name: name, priority: priority) {
            let startTime = ContinuousClock.now
            
            var retry = false
            var attempts = 0
            var finalResult: Swift.Result<Result, any Error>? = nil
            
            repeat {
                attempts += 1
                do {
                    finalResult = .success(try await operation())
                    retry = false
                } catch let error as CancellationError {
                    finalResult = .failure(error)
                    retry = false
                } catch {
                    finalResult = .failure(error)
                    retry = try await retryWhen(
                        (attempts, ContinuousClock.now - startTime),
                        error
                    )
                }
            } while retry
            
            switch finalResult! {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
    }
    
    @inlinable nonisolated func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        in taskGroup: inout ThrowingTaskGroup<Result, any Error>,
        operation: sending @Sendable @escaping @isolated(any) () async throws -> (Result),
        retryWhen: sending @Sendable @escaping @isolated(any) (
            _ condition: (attempts: Int, elapse: Duration),
            _ error: any Error
        ) async throws -> Bool
    ) {
        taskGroup.addTask {
            try await self.addTask(
                name: name,
                priority: priority,
                operation: operation,
                retryWhen: retryWhen
            )
        }
    }
}

extension ConstrainedTaskGroup where ContinuationResult == Duration {
    @inlinable func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        cooldown: Duration,
        operation: sending @escaping @isolated(any) () async throws -> (Result),
        retryWhen: sending @escaping @isolated(any) (
            _ condition: (attempts: Int, elapse: Duration),
            _ error: any Error
        ) async throws -> Bool
    ) async throws -> Result {
        try await self.addTask(name: name, priority: priority, cooldown: cooldown) {
            let startTime = ContinuousClock.now
            
            var retry = false
            var attempts = 0
            var finalResult: Swift.Result<Result, any Error>? = nil
            
            repeat {
                attempts += 1
                do {
                    finalResult = .success(try await operation())
                    retry = false
                } catch let error as CancellationError {
                    finalResult = .failure(error)
                    retry = false
                } catch {
                    finalResult = .failure(error)
                    retry = try await retryWhen(
                        (attempts, ContinuousClock.now - startTime),
                        error
                    )
                }
            } while retry
            
            switch finalResult! {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
    }
    
    @inlinable nonisolated func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        in taskGroup: inout ThrowingTaskGroup<Result, any Error>,
        cooldown: Duration,
        operation: sending @Sendable @escaping @isolated(any) () async throws -> (Result),
        retryWhen: sending @Sendable @escaping @isolated(any) (
            _ condition: (attempts: Int, elapse: Duration),
            _ error: any Error
        ) async throws -> Bool
    ) {
        taskGroup.addTask {
            try await self.addTask(
                name: name,
                priority: priority,
                cooldown: cooldown,
                operation: operation,
                retryWhen: retryWhen
            )
        }
    }
}
