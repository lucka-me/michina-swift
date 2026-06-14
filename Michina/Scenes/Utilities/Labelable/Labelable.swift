//
//  Labelable.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import SwiftUI

protocol Labelable {
    var titleKey: LocalizedStringKey { get }
    var systemImage: String { get }
}

extension Label<Text, Image> {
    init(_ item: some Labelable) {
        self.init(item.titleKey, systemImage: item.systemImage)
    }
}

extension NavigationLink<Label<Text, Image>, Never> {
    init<P : Hashable & Labelable>(value: P) {
        self.init(value: value) {
            Label(value)
        }
    }
}
