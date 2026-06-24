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
                Section {
                    LaunchAtLoginControls()
                }
                
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

extension AppSettingsTab {
    struct LaunchAtLoginControls : View {
        @Environment(\.alert) private var alert
        
        @State private var appServiceStatus = SMAppService.mainApp.status
        
        var body: some View {
            toggle
            
            if appServiceStatus == .requiresApproval {
                Text("AppSettingsTab.LaunchAtLogin.RequiresApproval")
                    .foregroundStyle(.yellow)
            }
            
            Button("AppSettingsTab.LaunchAtLogin.OpenSystemSettings") {
                SMAppService.openSystemSettingsLoginItems()
            }
            .buttonStyle(.link)
        }
    }
}

fileprivate extension AppSettingsTab {
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

fileprivate extension AppSettingsTab.LaunchAtLoginControls {
    @ViewBuilder
    var toggle: some View {
        Toggle(
            "AppSettingsTab.LaunchAtLogin.Toggle",
            isOn: .init(
                get: { appServiceStatus == .enabled },
                set: { newValue in
                    alert.whenTrying {
                        try setLaunchOnLogin(isOn: newValue)
                    }
                }
            )
        )
        .onAppear {
            appServiceStatus = SMAppService.mainApp.status
        }
    }
    
    func setLaunchOnLogin(isOn: Bool) throws {
        let appService = SMAppService.mainApp
        defer {
            self.appServiceStatus = appService.status
        }
        if isOn {
            try appService.register()
        } else {
            try appService.unregister()
        }
    }
}
