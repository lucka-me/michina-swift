//
//  StopWebServiceIntent.swift
//  Michina
//
//  Created by Lucka on 2026-08-20.
//

import AppIntents

struct StopWebServiceIntent : AppIntent {
    static var title: LocalizedStringResource { "StopWebServiceIntent.Title" }
    static var description: IntentDescription? { "StopWebServiceIntent.Description" }
    
    func perform() async throws -> some IntentResult {
        let service = await WebService.shared
        await service.stop()
        return .result()
    }
}
