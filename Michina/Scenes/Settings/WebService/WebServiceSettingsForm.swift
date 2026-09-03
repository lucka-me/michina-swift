//
//  WebServiceSettingsForm.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import SwiftUI

struct WebServiceSettingsForm : View {
    @Environment(\.alert) private var alert
    
    @State private var settings = WebServiceSettings.shared
    
    var body: some View {
        Form {
            Toggle(
                "WebServiceSettingsForm.StartWhenInitialized",
                isOn: $settings.startWhenInitialized
            )
            
            PortSection()
        }
        .frame(minWidth: 400, idealWidth: 400, minHeight: 300)
    }
}

extension WebServiceSettingsForm : @MainActor LabelableMetatype {
    static let titleKey: LocalizedStringKey = "WebService"
    static let systemImage: String = "network"
}

extension WebServiceSettingsForm {
    struct PortSection : View {
        @Environment(\.alert) private var alert
        
        @State private var settings = WebServiceSettings.shared
        @State private var hostInterfaces: [ WebServiceSettings.Interface ] = [ ]
        
        var body: some View {
            Section {
                TextField(
                    "WebServiceSettingsForm.Port.TextField",
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
                Text("WebServiceSettingsForm.Port")
            } footer: {
                Text("WebServiceSettingsForm.Port.Footer")
            }
            .onAppear {
                alert.whenTrying {
                    hostInterfaces = try WebServiceSettings.collectHostInterfaces()
                }
            }
        }
    }
}
