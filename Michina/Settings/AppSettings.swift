//
//  AppSettings.swift
//  Michina
//
//  Created by Lucka on 2026-06-08.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AppSettings {
    var insertMenuBarExtra: Bool {
        didSet {
            if !insertMenuBarExtra {
                presentRegularActivation = true
            }
            storage.insertMenuBarExtra = insertMenuBarExtra
        }
    }
    
    var presentRegularActivation: Bool {
        didSet {
            if !presentRegularActivation {
                insertMenuBarExtra = true
            }
            
            if presentRegularActivation {
                NSApplication.shared.setActivationPolicy(.regular)
            } else {
                NSApplication.shared.setActivationPolicy(.accessory)
            }
            
            storage.presentRegularActivation = presentRegularActivation
        }
    }
    
    private let storage = Storage()
    
    private init() {
        self.insertMenuBarExtra = storage.insertMenuBarExtra
        self.presentRegularActivation = storage.presentRegularActivation
    }
}

extension AppSettings {
    static let shared = AppSettings()
}

fileprivate extension AppSettings {
    struct Storage {
        @AppStorage("App.InsertMenuBarExtra") var insertMenuBarExtra = true
        @AppStorage("App.PresentRegularActivation") var presentRegularActivation = true
    }
}
