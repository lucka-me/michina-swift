//
//  Date+Rounding.swift
//  Michina
//
//  Created by Lucka on 2026-06-07.
//

import Foundation

extension Date {
    var ceiledBySecond: Date {
        let calendar = Calendar.current
        let nanoseconds = 1000000000 - calendar.component(.nanosecond, from: self)
        return calendar.date(
            byAdding: .nanosecond,
            value: nanoseconds,
            to: self,
            wrappingComponents: true
        ) ?? self
    }
    
    var flooredBySecond: Date {
        let calendar = Calendar.current
        let nanoseconds = -calendar.component(.nanosecond, from: self)
        return calendar.date(
            byAdding: .nanosecond,
            value: nanoseconds,
            to: self
        ) ?? self
    }
}
