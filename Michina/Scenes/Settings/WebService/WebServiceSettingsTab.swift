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
                    "WebServiceSettingsTab.StartWhenInitialized",
                    isOn: $settings.startWhenInitialized
                )
                
                Section {
                    TextField(
                        "WebServiceSettingsTab.Port",
                        value: $settings.port,
                        format: .port
                    )
                } footer: {
                    Text("WebServiceSettingsTab.Port.Footer")
                }
                
                
                urlsSection
            }
            .frame(minWidth: 400, minHeight: 300)
            .onAppear {
                alert.whenTrying {
                    hostAddresses = try WebServiceSettings.collectHostAddresses()
                }
            }
        }
    }
}

fileprivate extension WebServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "WebService"
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
            Text("WebServiceSettingsTab.URL")
        } footer: {
            Text("WebServiceSettingsTab.URL.Footer")
        }
    }
}
