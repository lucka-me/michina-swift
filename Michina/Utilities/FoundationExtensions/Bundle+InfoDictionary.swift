//
//  Bundle+InfoDictionary.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import Foundation

extension Bundle {
    var shortVersionString: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    var version: String? {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}
