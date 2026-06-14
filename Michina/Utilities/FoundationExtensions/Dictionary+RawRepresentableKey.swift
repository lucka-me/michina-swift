//
//  Dictionary+RawRepresentableKey.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

extension Dictionary {
    subscript<K: RawRepresentable>(_ key: K) -> Value? where K.RawValue == Key {
        self[key.rawValue]
    }
}
