//
//  ConstrainedTaskGroup+SwiftTaskGroup.swift
//  Michina
//
//  Created by Lucka on 2026-06-10.
//

extension ConstrainedTaskGroup {
    @inlinable nonisolated func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        in taskGroup: inout ThrowingTaskGroup<Result, any Error>,
        operation: sending @Sendable @escaping @isolated(any) (
            ContinuationResult?
        ) async throws -> (Result, ContinuationResult?)
    ) {
        taskGroup.addTask {
            try await self.addTask(name: name, priority: priority, operation: operation)
        }
    }
    
    @inlinable nonisolated func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        in taskGroup: inout TaskGroup<Result>,
        operation: sending @Sendable @escaping @isolated(any) (
            ContinuationResult?
        ) async -> (Result, ContinuationResult?)
    ) {
        taskGroup.addTask {
            await self.addTask(name: name, priority: priority, operation: operation)
        }
    }
}

extension ConstrainedTaskGroup where ContinuationResult == Duration {
    @inlinable func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        in taskGroup: inout ThrowingTaskGroup<Result, any Error>,
        cooldown: Duration,
        operation: sending @escaping @isolated(any) () async throws -> (Result)
    ) {
        taskGroup.addTask {
            try await self.addTask(
                name: name,
                priority: priority,
                cooldown: cooldown,
                operation: operation
            )
        }
    }
}
