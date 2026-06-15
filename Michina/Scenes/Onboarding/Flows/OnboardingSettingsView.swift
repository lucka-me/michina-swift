//
//  OnboardingSettingsView.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

struct OnboardingSettingsView : View {
    @Environment(\.alert) private var alert
    
    @State private var app = AppSettings.shared
    @State private var web = WebServiceSettings.shared
    @State private var inference = InferenceService.default
    
    @State private var hostAddresses: [ String ] = [ ]
    
    var body: some View {
        Form {
            Section {
                Toggle(
                    "OnboardingSettingsView.Launch.StartWhenInitialized",
                    isOn: $web.startWhenInitialized
                )
            } header: {
                Text("OnboardingSettingsView.Launch")
            }
            
            Section {
                TextField(
                    "OnboardingSettingsView.Port.TextField",
                    value: $web.port,
                    format: .port
                )
            } header: {
                Text("OnboardingSettingsView.Port")
            } footer: {
                Text("WebServiceSettingsTab.Port.Footer")
            }
            
            Section {
                ForEach(hostAddresses, id: \.self) { address in
                    Text("http://" + address + ":" + web.port.formatted(.port))
                        .monospaced()
                        .textSelection(.enabled)
                }
            } header: {
                Text("WebServiceSettingsTab.URL")
            } footer: {
                Text("OnboardingSettingsView.URL.Footer")
                Text("WebServiceSettingsTab.URL.Footer")
            }
            
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
        .onAppear {
            alert.whenTrying {
                hostAddresses = try WebServiceSettings.collectHostAddresses()
            }
        }
    }
}
