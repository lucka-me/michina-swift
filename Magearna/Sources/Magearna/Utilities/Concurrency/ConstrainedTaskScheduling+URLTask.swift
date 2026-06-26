//
//  ConstrainedTaskScheduling+URLTask.swift
//  Magearna
//
//  Created by Lucka on 2026-06-22.
//

import Foundation

extension ConstrainedTaskScheduling {
    func addURLTask<Result: Sendable>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async throws -> Result,
    ) async throws -> Result {
        try await self.addTask(
            name: name,
            priority: priority,
            operation: operation
        ) { condition, error in
            guard condition.attempts <= 3 else {
                return false
            }
            if let error = error as? URLError, error.code == .cancelled {
                return false
            }
            try await Task.sleep(for: .seconds(condition.attempts))
            return true
        }
    }
}
