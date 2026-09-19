//
//  AppSettingsForm.swift
//  Michina
//
//  Created by Lucka on 2026-06-08.
//

import SwiftUI
import ServiceManagement

struct AppSettingsForm : View {
    @Environment(\.alert) private var alert
    
    @State private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            Section {
                LaunchAtLoginControls()
            }
            
            iconsSection
        }
        .frame(minWidth: 300, idealWidth: 300, minHeight: 200)
    }
}

extension AppSettingsForm : @MainActor LabelableMetatype {
    static let titleKey: LocalizedStringKey = "AppSettingsForm"
    static let systemImage: String = "macwindow"
}

extension AppSettingsForm {
    struct LaunchAtLoginControls : View {
        @Environment(\.alert) private var alert
        
        @State private var appServiceStatus = SMAppService.mainApp.status
        
        var body: some View {
            toggle
            
            if appServiceStatus == .requiresApproval {
                Text("AppSettingsForm.LaunchAtLogin.RequiresApproval")
                    .foregroundStyle(.yellow)
            }
            
            Button("AppSettingsForm.LaunchAtLogin.OpenSystemSettings") {
                SMAppService.openSystemSettingsLoginItems()
            }
            .buttonStyle(.link)
        }
    }
}

fileprivate extension AppSettingsForm {
    @ViewBuilder
    var iconsSection: some View {
        Section {
            Toggle(
                "AppSettingsForm.Icon.PresentRegularActivation",
                isOn: $settings.presentRegularActivation
            )
            Toggle(
                "AppSettingsForm.Icon.InsertMenuBarExtra",
                isOn: $settings.insertMenuBarExtra
            )
        } footer: {
            Text("AppSettingsForm.Icons.Footer")
            if !settings.presentRegularActivation {
                Text("AppSettingsForm.Icons.Footer.PresentRegularActivation")
            }
        }
    }
}

fileprivate extension AppSettingsForm.LaunchAtLoginControls {
    @ViewBuilder
    var toggle: some View {
        Toggle(
            "AppSettingsForm.LaunchAtLogin.Toggle",
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
