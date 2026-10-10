//
//  RuntimeError.swift
//  Magearna
//
//  Created by Lucka on 2026-09-01.
//

struct RuntimeError : Error {
    let reason: String
    
    var localizedDescription: String {
        reason
    }
}

extension Error where Self == RuntimeError {
    static func runtime(_ reason: String) -> RuntimeError {
        .init(reason: reason)
    }
}
