//
//  AppSettingsTab.swift
//  Michina
//
//  Created by Lucka on 2026-06-08.
//

import SwiftUI
import ServiceManagement

struct AppSettingsTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var settings = AppSettings.shared
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            Form {
//                launchAtLoginSection
                iconsSection
            }
            .frame(minWidth: 300, maxWidth: 400)
        }
    }
}

extension AppSettingsTab {
    static let titleKey: LocalizedStringKey = "App"
    static let systemImage: String = "rectangle.badge.sparkles"
}

fileprivate extension AppSettingsTab {
    @ViewBuilder
    var launchAtLoginSection: some View {
        Section {
            Toggle(
                "Launch at Login",
                isOn: .init(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: {
                        alert.whenTrying(
                            $0
                            ? SMAppService.mainApp.register
                            : SMAppService.mainApp.unregister
                        )
                    }
                )
            )
        }
    }
    
    @ViewBuilder
    var iconsSection: some View {
        Section {
            Toggle("Show Icon in Dock", isOn: $settings.presentRegularActivation)
            Toggle("Show Icon in Menu Bar", isOn: $settings.insertMenuBarExtra)
        } footer: {
            Text("These options can't be off at same time, otherwise the app may unable to launch anymore.")
            if !settings.presentRegularActivation {
                Text("When the icon is hidden in Dock, macOS will also disable the app menus.")
            }
        }
    }
}
