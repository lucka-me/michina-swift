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
            .frame(minWidth: 300, minHeight: 200)
        }
    }
}

extension AppSettingsTab {
    static let titleKey: LocalizedStringKey = "AppSettingsTab"
    static let systemImage: String = "rectangle.badge.sparkles"
}

fileprivate extension AppSettingsTab {
    @ViewBuilder
    var launchAtLoginSection: some View {
        Section {
            Toggle(
                "AppSettingsTab.LaunchAtLogin.Toggle",
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
            Toggle(
                "AppSettingsTab.Icon.PresentRegularActivation",
                isOn: $settings.presentRegularActivation
            )
            Toggle(
                "AppSettingsTab.Icon.InsertMenuBarExtra",
                isOn: $settings.insertMenuBarExtra
            )
        } footer: {
            Text("AppSettingsTab.Icons.Footer")
            if !settings.presentRegularActivation {
                Text("AppSettingsTab.Icons.Footer.PresentRegularActivation")
            }
        }
    }
}
