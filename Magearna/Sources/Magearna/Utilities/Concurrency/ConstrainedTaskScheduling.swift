//
//  ConstrainedTaskScheduling.swift
//  Magearna
//
//  Created by Lucka on 2026-06-22.
//

public protocol ConstrainedTaskScheduling : Sendable {
    typealias RetryCondition = (attempts: Int, elapse: Duration)
    
    func addTask<Result: Sendable>(
        name: String?,
        priority: TaskPriority?,
        operation: sending @escaping @isolated(any) () async throws -> Result,
        retryWhen: sending @escaping @isolated(any) (
            _ condition: RetryCondition,
            _ error: any Error
        ) async throws -> Bool
    ) async throws -> Result
}
