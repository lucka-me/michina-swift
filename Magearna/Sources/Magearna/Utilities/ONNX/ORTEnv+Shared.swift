//
//  ORTEnv+Shared.swift
//  Magearna
//
//  Created by Lucka on 2026-06-05.
//

@preconcurrency import ONNXRuntime

extension ORTEnv {
    static let shared = try! ORTEnv(loggingLevel: .warning)
}
