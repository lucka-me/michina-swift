//
//  ORTValue+Array.swift
//  Magearna
//
//  Created by Lucka on 2026-05-22.
//

import ONNXRuntime

extension ORTValue {
    func array<T>(of type: T.Type = T.self) throws -> [ T ] {
        let data = try tensorData() as Data
        return data.withUnsafeBytes {
            .init($0.bindMemory(to: T.self))
        }
    }
}
