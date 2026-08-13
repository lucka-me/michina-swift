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
                optimizationSection
                executionProviderSection
                preloadModelsSection
                endpointsSection
                cacheSection
            }
            .frame(minWidth: 400, idealWidth: 400, minHeight: 400)
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "InferenceService"
    static let systemImage: String = "rectangle.stack"
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var optimizationSection: some View {
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
    
    @ViewBuilder
    var executionProviderSection: some View {
        @Bindable var settings = settings.executionProvider
        
        Section {
            Picker(
                "InferenceServiceSettingsTab.ExecutionProvider.EfficientCoreML",
                selection: $settings.efficientCoreML
            ) {
                ForEach(
                    InferenceServiceSettings.ExecutionProviderSettings.Option.allCases
                ) { option in
                    Text(option.titleKey)
                        .tag(option)
                }
            }
            
            Picker(
                "InferenceServiceSettingsTab.ExecutionProvider.InefficientCoreML",
                selection: $settings.inefficientCoreML
            ) {
                ForEach(
                    InferenceServiceSettings.ExecutionProviderSettings.Option.allCases
                ) { option in
                    Text(option.titleKey)
                        .tag(option)
                }
            }
            
            Picker(
                "InferenceServiceSettingsTab.ExecutionProvider.NeuralNetworkCoreML",
                selection: $settings.neuralNetworkCoreML
            ) {
                ForEach(
                    InferenceServiceSettings.ExecutionProviderSettings.Option.casesForNeuralNetwork
                ) { option in
                    Text(option.titleKey)
                        .tag(option)
                }
            }
        } header: {
            Text("InferenceServiceSettingsTab.ExecutionProvider")
        } footer: {
            Text("InferenceServiceSettingsTab.ExecutionProvider.Footer")
        }
        .pickerStyle(.segmented)
    }
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var preloadModelsSection: some View {
        Section {
            if #available(macOS 26, *) {
                ForEach(
                    settings.preloadModels.enumerated(),
                    id: \.element.id,
                    content: preloadModelRow(_:)
                )
            } else {
                ForEach(
                    Array(settings.preloadModels.enumerated()),
                    id: \.element.id,
                    content: preloadModelRow(_:)
                )
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
    
    @ViewBuilder
    func preloadModelRow(
        _ item: EnumeratedSequence<[ InferenceModel ]>.Element
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(item.element.suiteCategory.titleKey)
                    Divider()
                    Text(item.element.category.titleKey)
                }
                .font(.caption)
                
                Text(item.element.suiteName)
                    .monospaced()
            }
            
            Spacer()
            
            Button(
                "InferenceServiceSettingsTab.PreloadModels.Remove",
                systemImage: "trash",
                role: .destructive
            ) {
                settings.preloadModels.remove(at: item.offset)
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
        InferenceModel.Category.allCases.compactMap { category in
            guard
                let model = suite.models[category],
                !settings.preloadModels.contains(model)
            else {
                return nil
            }
            return model
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var endpointsSection: some View {
        Section {
            EndpointField(
                InferenceModelSuite.Provider.ImmichAppEndpoint.self,
                url: $settings.immichAppEndpointURL
            )
        } header: {
            Text("InferenceServiceSettingsTab.Endpoints")
        } footer: {
            Text("InferenceServiceSettingsTab.Endpoints.Footer")
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var cacheSection: some View {
        Section {
            TextField(
                "InferenceServiceSettingsTab.Cache.Lifespan",
                value: $settings.loadedLifespan,
                format: .number.grouping(.never),
                prompt: Text("InferenceServiceSettingsTab.Cache.Lifespan.Prompt")
            )
        } header: {
            Text("InferenceServiceSettingsTab.Cache")
        } footer: {
            Text("InferenceServiceSettingsTab.Cache.Footer")
        }
    }
}
