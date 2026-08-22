//
//  StartWebServiceIntent.swift
//  Michina
//
//  Created by Lucka on 2026-08-20.
//

import AppIntents

struct StartWebServiceIntent : AppIntent {
    static var title: LocalizedStringResource { "StartWebServiceIntent.Title" }
    static var description: IntentDescription? { "StartWebServiceIntent.Description" }
    
    func perform() async throws -> some IntentResult {
        let service = await WebService.shared
        try await service.start()
        try await Task.sleep(for: .seconds(1))
        guard await service.status.isRunning else {
            throw await service.errors.last?.error ?? PerformUnknownError()
        }
        return .result()
    }
}

fileprivate extension StartWebServiceIntent {
    struct PerformUnknownError : LocalizedError {
    }
}
