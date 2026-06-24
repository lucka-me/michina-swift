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
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            Form {
                Toggle(
                    "WebServiceSettingsTab.StartWhenInitialized",
                    isOn: $settings.startWhenInitialized
                )
                
                PortSection()
            }
            .frame(minWidth: 400, minHeight: 300)
        }
    }
}

extension WebServiceSettingsTab {
    struct PortSection : View {
        @Environment(\.alert) private var alert
        
        @State private var settings = WebServiceSettings.shared
        @State private var hostInterfaces: [ WebServiceSettings.Interface ] = [ ]
        
        var body: some View {
            Section {
                TextField(
                    "WebServiceSettingsTab.Port.TextField",
                    value: $settings.port,
                    format: .port
                )
                
                ForEach(hostInterfaces, id: \.address) { interface in
                    LabeledContent(
                        interface.name,
                        value: "http://\(interface.address):\(settings.port.formatted(.port))"
                    )
                }
                .monospaced()
            } header: {
                Text("WebServiceSettingsTab.Port")
            } footer: {
                Text("WebServiceSettingsTab.Port.Footer")
            }
            .onAppear {
                alert.whenTrying {
                    hostInterfaces = try WebServiceSettings.collectHostInterfaces()
                }
            }
        }
    }
}

fileprivate extension WebServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "WebService"
    static let systemImage: String = "network"
}
