//
//  SettingsScene.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import SwiftUI

struct SettingsScene : Scene {
    var body: some Scene {
        Settings {
            TabView {
                AppSettingsTab()
                WebServiceSettingsTab()
                InferenceServiceSettingsTab()
            }
            .formStyle(.grouped)
//            .scenePadding()
            .windowResizeAnchor(.top)
            .alertable()
        }
    }
}
