//
//  WebServiceSettingsTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import SwiftUI

struct WebServiceSettingsTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var settings = WebServiceSettings.shared
    
    @State private var hostAddresses: [ String ] = [ ]
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            Form {
                Toggle(
                    "Start When App Launches",
                    isOn: $settings.startWhenInitialized
                )
                
                TextField(
                    "Port",
                    value: $settings.port,
                    format: .number.grouping(.never)
                )
                
                urlsSection
            }
            .frame(minWidth: 200, maxWidth: 400)
            .onAppear {
                alert.whenTrying {
                    hostAddresses = try WebServiceSettings.collectHostAddresses()
                }
            }
        }
    }
}

fileprivate extension WebServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "Web Service"
    static let systemImage: String = "network"
}

fileprivate extension WebServiceSettingsTab {
    @ViewBuilder
    var urlsSection: some View {
        Section {
            ForEach(hostAddresses, id: \.self) { address in
                Text("http://" + address + ":" + settings.port.formatted(.port))
                    .monospaced()
                    .textSelection(.enabled)
            }
        } header: {
            Text("URL")
        } footer: {
            Text("These URLs are generated from your device's network interface information, and for reference only.")
        }
    }
}
