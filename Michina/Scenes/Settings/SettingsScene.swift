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
            Group {
                if #available(macOS 15.0, *) {
                    navigation
                } else {
                    legacyNavigation
                }
            }
            .alertable()
        }
        .windowResizability(.contentMinSize)
    }
}

fileprivate extension SettingsScene {
    @available(macOS 15.0, *)
    @ViewBuilder
    var navigation : some View {
        TabView {
            Tab(AppSettingsForm.self) {
                AppSettingsForm()
            }
            
            Tab(WebServiceSettingsForm.self) {
                WebServiceSettingsForm()
            }
            
            Tab(InferenceServiceSettingsForm.self) {
                InferenceServiceSettingsForm()
            }
        }
        .formStyle(.grouped)
        .applying {
            if #available(macOS 26, *) {
                $0.windowResizeAnchor(.leading)
            } else {
                $0
            }
        }
        .windowResizeBehavior(.enabled)
    }
    
    @ViewBuilder
    var legacyNavigation : some View {
        TabView {
            AppSettingsForm()
                .tabItem {
                    Label(AppSettingsForm.self)
                }
            
            WebServiceSettingsForm()
                .tabItem {
                    Label(WebServiceSettingsForm.self)
                }
            
            InferenceServiceSettingsForm()
                .tabItem {
                    Label(InferenceServiceSettingsForm.self)
                }
        }
    }
}
