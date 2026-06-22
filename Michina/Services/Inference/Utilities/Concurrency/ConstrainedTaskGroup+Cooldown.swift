//
//  ConstrainedTaskGroup+Cooldown.swift
//  Michina
//
//  Created by Lucka on 2026-06-10.
//

extension ConstrainedTaskGroup where ContinuationResult == Duration {
    @inlinable func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        cooldown: Duration,
        operation: sending @escaping @isolated(any) () async throws -> Result
    ) async throws -> Result {
        try await self.addTask(name: name, priority: priority) { cooldownRemaining in
            if let cooldownRemaining, cooldownRemaining > .zero {
                try await Task.sleep(for: cooldownRemaining)
            }
            
            let startTime = ContinuousClock.now
            
            let result = try await operation()
            
            let duration = ContinuousClock.now - startTime
            
            return (result, cooldown > duration ? (cooldown - duration) : .zero)
        }
    }
    
    @inlinable func addTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        cooldown: Duration,
        operation: sending @escaping @isolated(any) () async -> Result
    ) async throws -> Result {
        try await self.addTask(name: name, priority: priority) { cooldownRemaining in
            if let cooldownRemaining, cooldownRemaining > .zero {
                try await Task.sleep(for: cooldownRemaining)
            }
            
            let startTime = ContinuousClock.now
            
            let result = await operation()
            
            let duration = ContinuousClock.now - startTime
            
            return (result, cooldown > duration ? (cooldown - duration) : .zero)
        }
    }
}
