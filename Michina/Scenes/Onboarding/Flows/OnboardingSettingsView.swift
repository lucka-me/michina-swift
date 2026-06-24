//
//  OnboardingSettingsView.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

struct OnboardingSettingsView : View {
    @Environment(\.alert) private var alert
    
    @State private var web = WebServiceSettings.shared
    
    var body: some View {
        Form {
            Section {
                AppSettingsTab.LaunchAtLoginControls()
                
                Toggle(
                    "OnboardingSettingsView.Launch.StartWhenInitialized",
                    isOn: $web.startWhenInitialized
                )
            } header: {
                Text("OnboardingSettingsView.Launch")
            }
            
            WebServiceSettingsTab.PortSection()
            
            Section {
                SettingsLink()
                    .buttonStyle(.link)
            } header: {
                Text("OnboardingSettingsView.More")
            } footer: {
                Text("OnboardingSettingsView.More.Footer")
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("OnboardingSettingsView.Subtitle")
    }
}
