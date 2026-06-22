//
//  ConstrainedTaskScheduling+DownloadTask.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

import Foundation
import HTTPTypesFoundation

extension ConstrainedTaskScheduling {
    func addDownloadTask(
        from url: URL,
        to destination: URL,
        reporting progress: Progress?
    ) async throws {
        guard !FileManager.default.fileExists(at: destination) else {
            progress?.totalUnitCount = 100
            progress?.completedUnitCount = 100
            return
        }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        try await addURLTask(priority: .background) {
            var sessionInstance: URLSession? = nil
            defer {
                sessionInstance?.finishTasksAndInvalidate()
            }
            try await withCheckedThrowingContinuation { continuation in
                let delegate = DownloadDelegate(
                    continuation: continuation,
                    destination: destination,
                    progress: progress
                )
                
                let session = URLSession(
                    configuration: .default,
                    delegate: delegate,
                    delegateQueue: nil
                )
                
                let task = session.downloadTask(with: .init(url: url))
                
                sessionInstance = session
                task.resume()
            }
        }
    }
}

fileprivate enum DownloadGroupTaskError : LocalizedError {
    case failedToConvertResponse
    case unsuccessful(status: HTTPResponse.Status)
    
    var errorDescription: String? {
        switch self {
        case .failedToConvertResponse:
            .init(
                localized: "DownloadGroupTaskError.FailedToConvertResponse.Description",
                bundle: #bundle
            )
        case .unsuccessful(let status):
            .init(
                localized: "DownloadGroupTaskError.Unsuccessful.Description \(status.code)",
                bundle: #bundle
            )
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
        guard
            totalBytesWritten != NSURLSessionTransferSizeUnknown,
            let progress = self.progress
        else {
            return
        }
        DispatchQueue.main.async {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
        }
    }
}
