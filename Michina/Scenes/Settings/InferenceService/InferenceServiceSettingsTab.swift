//
//  InferenceServiceSettingsTab.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import SwiftUI
import ONNXRuntime

struct InferenceServiceSettingsTab : TabContent {
    @State var settings = InferenceServiceSettings.shared
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            Form {
                sessionSections
                cacheSection
            }
            .frame(minWidth: 300, maxWidth: 400)
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "InferenceService"
    static let systemImage: String = "rectangle.stack"
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var sessionSections: some View {
        @Bindable var settings = settings.session
        
        Section {
            Toggle(
                "InferenceServiceSettingsTab.ExecutionProviders.PreferCoreML",
                isOn: $settings.preferCoreML
            )
            if settings.preferCoreML {
                Toggle(
                    "InferenceServiceSettingsTab.ExecutionProviders.PreferEfficiency",
                    isOn: $settings.preferEfficiency
                )
            }
        } header: {
            Text("InferenceServiceSettingsTab.ExecutionProviders")
        } footer: {
            Text("InferenceServiceSettingsTab.ExecutionProviders.Footer")
        }
        
        Section {
            Toggle(
                "InferenceServiceSettingsTab.Optimization.PersistOptimizations",
                isOn: $settings.persistOptimizations
            )
        } header: {
            Text("InferenceServiceSettingsTab.Optimization")
        } footer: {
            Text("InferenceServiceSettingsTab.Optimization.Footer")
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var cacheSection: some View {
        @Bindable var settings = settings.cache
        
        Section {
            TextField(
                "InferenceServiceSettingsTab.Cache.TimeToLive",
                value: $settings.timeToLive,
                format: .number.grouping(.never),
                prompt: Text("InferenceServiceSettingsTab.Cache.TimeToLive.Prompt")
            )
        } header: {
            Text("InferenceServiceSettingsTab.Cache")
        } footer: {
            Text("InferenceServiceSettingsTab.Cache.Footer")
        }
    }
}
