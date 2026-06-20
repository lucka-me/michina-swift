//
//  ThrowingTaskGroup+DataTask.swift
//  Magearna
//
//  Created by Lucka on 2026-06-19.
//

import Foundation
import HTTPTypesFoundation

extension ThrowingTaskGroup where Failure == Error {
    mutating func addDataTask(
        for request: HTTPRequest,
        with session: URLSession = .shared,
        decode: @Sendable @escaping (Data, HTTPResponse) throws -> ChildTaskResult
    ) {
        addTask(priority: .background) {
            let (data, response) = try await session.data(for: request)
            guard response.status.kind == .successful else {
                throw DataGroupTaskError.unsuccessful(status: response.status)
            }
            return try decode(data, response)
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
    
    mutating func addDataTask(
        from url: URL,
        with session: URLSession = .shared,
        decode: @Sendable @escaping (Data, HTTPResponse) throws -> ChildTaskResult
    ) {
        addDataTask(for: .init(url: url), with: session, decode: decode)
    }
}

extension ThrowingTaskGroup where ChildTaskResult: Decodable, Failure == Error {
    mutating func addDataTask(
        for request: HTTPRequest,
        with session: URLSession = .shared
    ) {
        addDataTask(for: request, with: session) { data, _ in
            try JSONDecoder().decode(ChildTaskResult.self, from: data)
        }
    }
    
    mutating func addDataTask(
        from url: URL,
        with session: URLSession = .shared
    ) {
        addDataTask(for: .init(url: url), with: session)
    }
}

fileprivate enum DataGroupTaskError : LocalizedError {
    case unsuccessful(status: HTTPResponse.Status)
    
    var errorDescription: String? {
        switch self {
        case .unsuccessful(let status):
            .init(
                localized: "DataGroupTaskError.Unsuccessful.Description \(status.code)",
                bundle: #bundle
            )
        }
    }
    
    var failureReason: String? {
        switch self {
        case .unsuccessful(let status): status.reasonPhrase
        }
    }
}
