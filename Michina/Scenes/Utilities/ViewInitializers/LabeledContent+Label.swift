//
//  LabeledContent+Label.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import SwiftUI

extension LabeledContent<Label<Text, Image>, Text> {
    @inlinable init<F : FormatStyle>(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        value: F.FormatInput, format: F
    ) where F.FormatInput : Equatable, F.FormatOutput == String {
        self.init {
            Text(value, format: format)
        } label: {
            Label(titleKey, systemImage: systemImage)
        }
    }
}
