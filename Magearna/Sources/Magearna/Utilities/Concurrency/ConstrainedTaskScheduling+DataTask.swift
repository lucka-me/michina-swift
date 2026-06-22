//
//  ConstrainedTaskScheduling+DataTask.swift
//  Magearna
//
//  Created by Lucka on 2026-06-19.
//

import Foundation
import HTTPTypesFoundation

extension ConstrainedTaskScheduling {
    func addDataTask<Result: Sendable>(
        for request: HTTPRequest,
        with session: URLSession = .shared,
        decode: @Sendable @escaping (Data, HTTPResponse) throws -> Result
    ) async throws -> Result {
        try await addURLTask(priority: .background) {
            let (data, response) = try await session.data(for: request)
            guard response.status.kind == .successful else {
                throw DataGroupTaskError.unsuccessful(status: response.status)
            }
            return try decode(data, response)
        }
    }
    
    func addDataTask<Result: Sendable>(
        from url: URL,
        with session: URLSession = .shared,
        decode: @Sendable @escaping (Data, HTTPResponse) throws -> Result
    ) async throws -> Result {
        try await addDataTask(for: .init(url: url), with: session, decode: decode)
    }
}

extension ConstrainedTaskScheduling {
    func addDataTask<Result: Sendable & Decodable>(
        for request: HTTPRequest,
        with session: URLSession = .shared
    ) async throws -> Result {
        try await addDataTask(for: request, with: session) { data, _ in
            try JSONDecoder().decode(Result.self, from: data)
        }
    }
    
    func addDataTask<Result: Sendable & Decodable>(
        from url: URL,
        with session: URLSession = .shared
    ) async throws -> Result {
        try await addDataTask(for: .init(url: url), with: session)
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
