//
//  FormatStyle+Elapse.swift
//  Michina
//
//  Created by Lucka on 2026-05-26.
//

import Foundation

extension FormatStyle where Self == Duration.UnitsFormatStyle {
    static var elapse: Self {
        .elapse()
    }
    
    static func elapse(fractionalPartLength: Int = 3) -> Self {
        .units(
            allowed: [ .seconds, .milliseconds ],
            width: .narrow,
            maximumUnitCount: 1,
            fractionalPart: .show(
                length: fractionalPartLength,
                rounded: .toNearestOrAwayFromZero
            )
        )
    }
}
