//
//  ThrowingTaskGroup+DownloadTask.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation
import HTTPTypesFoundation

extension ThrowingTaskGroup where ChildTaskResult == Void, Failure == Error {
    mutating func addDownloadTask(
        from url: URL,
        to destination: URL,
        reporting parentProgress: Progress?
    ) throws {
        let progress = parentProgress?.addChild(for: 1, as: 1)
        guard !FileManager.default.fileExists(at: destination) else {
            progress?.completedUnitCount = 1
            return
        }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        addTask(priority: .background) {
            let (temporaryURL, response) = try await URLSession.shared.download(
                for: HTTPRequest(url: url)
            )
            guard response.status.kind == .successful else {
                try FileManager.default.removeItem(at: temporaryURL)
                throw DownloadError(status: response.status)
            }
            
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            progress?.completedUnitCount = 1
        } retryWhen: { condition, error in
            guard condition.attempts <= 3 else {
                return false
            }
            if let error = error as? URLError, error.code == .cancelled {
                return false
            }
            try await Task.sleep(for: .milliseconds(100) * condition.attempts)
            return true
        }
    }
}

fileprivate extension ThrowingTaskGroup where ChildTaskResult == Void, Failure == Error {
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

fileprivate struct DownloadError : LocalizedError {
    let status: HTTPResponse.Status
    
    var errorDescription: String? {
        .init(localized: "DownloadError.ErrorDescription \(status.code)")
    }
    
    var failureReason: String? {
        status.reasonPhrase
    }
}
