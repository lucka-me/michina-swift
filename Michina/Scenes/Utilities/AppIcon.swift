//
//  AppIcon.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

enum AppIcon : String {
    case `default` = "Default"
}

extension AppIcon : CaseIterable, Identifiable {
    var id: RawValue {
        rawValue
    }
}

extension AppIcon {
    @MainActor
    static var current: Self {
        .default
    }
    
    var name: String? {
        if self == .default {
            nil
        } else {
            rawValue
        }
    }
    
    var preview: ImageResource {
        switch self {
        case .default: .AppIconPreview.default
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .default: "Default"
        }
    }
}
