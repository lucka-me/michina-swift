//
//  ThrowingTaskGroup+Retry.swift
//  Magearna
//
//  Created by Lucka on 2026-06-19.
//

extension ThrowingTaskGroup where Failure == Error {
    mutating func addTask(
        priority: TaskPriority? = nil,
        operation: sending @Sendable @escaping () async throws -> ChildTaskResult,
        retryWhen: sending @Sendable @escaping (
            _ condition: (attempts: Int, elapse: Duration),
            _ error: any Error
        ) async throws -> Bool
    ) {
        addTask(priority: priority) {
            let startTime = ContinuousClock.now
            
            var retry = false
            var attempts = 0
            var finalResult: Swift.Result<ChildTaskResult, Failure>? = nil
            
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
}
