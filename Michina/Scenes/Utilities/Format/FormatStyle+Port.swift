//
//  FormatStyle+Port.swift
//  Michina
//
//  Created by Lucka on 2026-06-15.
//

import Foundation

extension FormatStyle where Self == IntegerFormatStyle<Int> {
    static var port: IntegerFormatStyle<Int> {
        .number.grouping(.never)
    }
}
