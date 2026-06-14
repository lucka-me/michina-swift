//
//  OnboardingSettingsView.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

struct OnboardingSettingsView : View {
    @State private var app = AppSettings.shared
    @State private var web = WebServiceSettings.shared
    @State private var inference = InferenceService.default
    
    var body: some View {
        Form {
            webSection
        }
        .formStyle(.grouped)
        .navigationSubtitle("Most important options.")
    }
}

fileprivate extension OnboardingSettingsView {
    @ViewBuilder
    var webSection: some View {
        Section {
            Toggle("Start Service When Michina Launches", isOn: $web.startWhenInitialized)
            
            TextField(
                "Listen to Port",
                value: $web.port,
                format: .number.grouping(.never)
            )
        } header: {
            Text("Web Service")
        } footer: {
            Text("Please add a URL to your Immich instance in Machine Learning Settings. The default port is 3003.")
        }
    }
}
