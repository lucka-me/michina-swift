//
//  InferenceServiceSettingsTab.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import SwiftUI
import Magearna

struct InferenceServiceSettingsTab : TabContent {
    @State var settings = InferenceServiceSettings.shared
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            Form {
                sessionSections
                preloadModelsSection
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
    var preloadModelsSection: some View {
        Section {
            ForEach(
                settings.preloadModels.enumerated(),
                id: \.element.id
            ) { enumeration in
                LabeledContent {
                    Button(role: .destructive) {
                        settings.preloadModels.remove(at: enumeration.offset)
                    }
                } label: {
                    VStack(alignment: .leading) {
                        HStack(spacing: 12) {
                            Text(enumeration.element.suiteCategory.titleKey)
                            Text(enumeration.element.category.titleKey)
                        }
                        .font(.caption)
                        
                        Text(enumeration.element.suiteName)
                            .monospaced()
                    }
                }
            }
            
            addPreloadModelMenu
        } header: {
            Text("InferenceServiceSettingsTab.PreloadModels")
        } footer: {
            Text("InferenceServiceSettingsTab.PreloadModels.Footer")
        }
    }
    
    @ViewBuilder
    var addPreloadModelMenu: some View {
        Menu("InferenceServiceSettingsTab.PreloadModels.Add") {
            ForEach(InferenceModelSuite.Category.allCases) { suiteCategory in
                Section(suiteCategory.titleKey) {
                    ForEach(preloadableSuites(category: suiteCategory)) { suite in
                        let models = preloadableModels(in: suite)
                        if !models.isEmpty {
                            Menu(suite.name) {
                                ForEach(models) { model in
                                    Button(model.category.titleKey) {
                                        settings.preloadModels.append(model)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func preloadableSuites(
        category: InferenceModelSuite.Category
    ) -> [ InferenceModelSuite ] {
        InferenceModelSuite.all[category]!
            .filter { !$0.isBuiltin }
    }
    
    func preloadableModels(in suite: InferenceModelSuite) -> [ InferenceModel ] {
        suite.models
            .compactMap { settings.preloadModels.contains($0.value) ? nil : $0.value }
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
