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
                    "Start Web Service When Michina Launches",
                    isOn: $web.startWhenInitialized
                )
            } header: {
                Text("Launch")
            }
            
            Section {
                TextField(
                    "Listen on Port",
                    value: $web.port,
                    format: .port
                )
            } header: {
                Text("Port")
            } footer: {
                Text("The defualt port is 3003, you need to restart the Web Service to apply the new port.")
            }
            
            Section {
                ForEach(hostAddresses, id: \.self) { address in
                    Text("http://" + address + ":" + web.port.formatted(.port))
                        .monospaced()
                        .textSelection(.enabled)
                }
            } header: {
                Text("URL")
            } footer: {
                Text("In your Immich instance, navigate to Machine Learning Settings and add an URL to this device.")
                Text("These URLs are generated from your device's network interface information, and for reference only.")
            }
            
            Section {
                SettingsLink()
                    .buttonStyle(.link)
            } header: {
                Text("More")
            } footer: {
                Text("Configure app icon and inference preferences in Settings window.")
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("Most important options.")
        .onAppear {
            alert.whenTrying {
                hostAddresses = try WebServiceSettings.collectHostAddresses()
            }
        }
    }
}
