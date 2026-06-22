//
//  URL+FileSize.swift
//  Magearna
//
//  Created by Lucka on 2026-06-22.
//

import Foundation

extension URL {
    var fileSize: Int64? {
        guard
            FileManager.default.fileExists(at: self),
            let values = try? resourceValues(forKeys: [ .fileSizeKey ]),
            let value = values.fileSize
        else {
            return nil
        }
        return .init(value)
    }
}
