//
//  FormatStyle+Confidence.swift
//  Michina
//
//  Created by Lucka on 2026-06-28.
//

import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Float>.Percent {
    static var confidence: Self {
        .percent.precision(.fractionLength(2))
    }
}
