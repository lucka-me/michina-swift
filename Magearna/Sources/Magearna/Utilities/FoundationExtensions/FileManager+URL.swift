//
//  FileManager+URL.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation

extension FileManager {
    func fileExists(at url: URL, percentEncoded: Bool = false) -> Bool {
        fileExists(atPath: url.path(percentEncoded: percentEncoded))
    }
}
