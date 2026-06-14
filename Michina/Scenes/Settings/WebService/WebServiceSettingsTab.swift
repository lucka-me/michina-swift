//
//  WebServiceSettingsTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import SwiftUI

struct WebServiceSettingsTab : TabContent {
    @State var settings = WebServiceSettings.shared
    
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
            }
            .frame(minWidth: 200, maxWidth: 400)
        }
    }
}

fileprivate extension WebServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "Web Service"
    static let systemImage: String = "network"
}
