//
//  ToggleWebServiceIntent.swift
//  Michina
//
//  Created by Lucka on 2026-08-20.
//

import AppIntents

struct ToggleWebServiceIntent : SetValueIntent {
    static var title: LocalizedStringResource { "ToggleWebServiceIntent.Title" }
    static var description: IntentDescription? { "ToggleWebServiceIntent.Description" }
    
    @Parameter(title: "ToggleWebServiceIntent.ValueTitle")
    var value: Bool
    
    func perform() async throws -> some ReturnsValue<Bool> {
        let service = await WebService.shared
        if value {
            try await service.start()
            try await Task.sleep(for: .seconds(1))
            guard await service.status.isRunning else {
                throw await service.errors.last?.error ?? PerformUnknownError()
            }
        } else {
            await service.stop()
        }
        
        return .result(value: await service.status.isRunning)
    }
}

fileprivate extension ToggleWebServiceIntent {
    struct PerformUnknownError : LocalizedError {
    }
}
