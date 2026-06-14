//
//  Label+Format.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import SwiftUI

extension Label<Text, Image> {
    @inlinable init(_ date: Date, style: Text.DateStyle, systemImage: String) {
        self.init {
            Text(date, style: style)
        } icon: {
            Image(systemName: systemImage)
        }
    }
    
    @inlinable init<F: FormatStyle>(
        _ value: F.FormatInput,
        format: F,
        systemImage: String
    ) where F.FormatInput : Equatable, F.FormatOutput == String {
        self.init {
            Text(value, format: format)
        } icon: {
            Image(systemName: systemImage)
        }
    }
}
