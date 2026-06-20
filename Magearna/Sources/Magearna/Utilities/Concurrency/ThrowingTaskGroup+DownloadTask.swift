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
        with sessionConfiguration: URLSessionConfiguration = .default,
        reporting progress: Progress?
    ) throws {
        guard !FileManager.default.fileExists(at: destination) else {
            progress?.totalUnitCount = 100
            progress?.completedUnitCount = 100
            return
        }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        addTask(priority: .background) {
            var sessionInstance: URLSession? = nil
            defer {
                sessionInstance?.invalidateAndCancel()
            }
            try await withCheckedThrowingContinuation { continuation in
                let delegate = DownloadDelegate(
                    continuation: continuation,
                    destination: destination,
                    progress: progress
                )
                
                let session = URLSession(
                    configuration: sessionConfiguration,
                    delegate: delegate,
                    delegateQueue: nil
                )
                
                let task = session.downloadTask(with: .init(url: url))
                
                sessionInstance = session
                task.resume()
            }
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

fileprivate enum DownloadGroupTaskError : LocalizedError {
    case failedToConvertResponse
    case unsuccessful(status: HTTPResponse.Status)
    
    var errorDescription: String? {
        switch self {
        case .failedToConvertResponse:
            .init(localized: "DownloadGroupTaskError.FailedToConvertResponse.Description")
        case .unsuccessful(let status):
            .init(localized: "DownloadGroupTaskError.Unsuccessful.Description \(status.code)")
        }
    }
    
    var failureReason: String? {
        switch self {
        case .unsuccessful(let status): status.reasonPhrase
        default: nil
        }
    }
}

fileprivate final class DownloadDelegate : NSObject, URLSessionDownloadDelegate {
    private let continuation: CheckedContinuation<Void, Error>
    private let destination: URL
    private let progress: Progress?
    
    init(
        continuation: CheckedContinuation<Void, Error>,
        destination: URL,
        progress: Progress?
    ) {
        self.continuation = continuation
        self.destination = destination
        self.progress = progress
        
        super.init()
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        if let error {
            continuation.resume(throwing: error)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let result: Result<Void, Error>
        defer {
            continuation.resume(with: result)
        }
        
        guard
            let response = (downloadTask.response as? HTTPURLResponse)?.httpResponse
        else {
            result = .failure(DownloadGroupTaskError.failedToConvertResponse)
            return
        }
        guard response.status.kind == .successful else {
            result = .failure(
                DownloadGroupTaskError.unsuccessful(status: response.status)
            )
            return
        }
        
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            result = .success(())
        } catch {
            result = .failure(error)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesWritten != NSURLSessionTransferSizeUnknown else {
            return
        }
        progress?.totalUnitCount = totalBytesExpectedToWrite
        progress?.completedUnitCount = totalBytesWritten
    }
}
