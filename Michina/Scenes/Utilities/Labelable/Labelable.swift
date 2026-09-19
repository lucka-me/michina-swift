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

protocol LabelableMetatype {
    static var titleKey: LocalizedStringKey { get }
    static var systemImage: String { get }
}

extension Label<Text, Image> {
    init(_ item: some Labelable) {
        self.init(item.titleKey, systemImage: item.systemImage)
    }
    
    init<T: LabelableMetatype>(_ type: T.Type = T.self) {
        self.init(type.titleKey, systemImage: type.systemImage)
    }
}

extension NavigationLink<Label<Text, Image>, Never> {
    init<P : Hashable & Labelable>(value: P) {
        self.init(value: value) {
            Label(value)
        }
    }
}

@available(macOS 15, *)
extension Tab where Content : View, Label == DefaultTabLabel, Value == Never {
    init(
        _ label: some Labelable,
        @ViewBuilder content: () -> Content
    ) {
        self.init(label.titleKey, systemImage: label.systemImage, content: content)
    }
    
    init<T: LabelableMetatype>(
        _ type: T.Type = T.self,
        @ViewBuilder content: () -> Content
    ) {
        self.init(type.titleKey, systemImage: type.systemImage, content: content)
    }
}

@available(macOS 15, *)
extension Tab where Content : View, Label == DefaultTabLabel, Value : Hashable {
    init(
        label: some Labelable,
        value: Value,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            label.titleKey,
            systemImage: label.systemImage,
            value: value,
            content: content
        )
    }
    
    init<T: LabelableMetatype>(
        _ type: T.Type = T.self,
        value: Value,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            type.titleKey,
            systemImage: type.systemImage,
            value: value,
            content: content
        )
    }
}

@available(macOS 15, *)
extension Tab where Content : View, Label == DefaultTabLabel, Value : Hashable & Labelable {
    init(
        label value: Value,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            value.titleKey,
            systemImage: value.systemImage,
            value: value,
            content: content
        )
    }
}
