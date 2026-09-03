//
//  InferenceServiceSettingsForm.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import SwiftUI
import Magearna

struct InferenceServiceSettingsForm : View {
    @State var settings = InferenceServiceSettings.shared
    
    var body: some View {
        Form {
            optimizationSection
            executionProviderSection
            preloadModelsSection
            endpointSections
            cacheSection
        }
        .frame(minWidth: 400, idealWidth: 400, minHeight: 400)
    }
}

extension InferenceServiceSettingsForm : @MainActor LabelableMetatype {
    static let titleKey: LocalizedStringKey = "InferenceService"
    static let systemImage: String = "rectangle.stack"
}

fileprivate extension InferenceServiceSettingsForm {
    @ViewBuilder
    var optimizationSection: some View {
        Section {
            Toggle(
                "InferenceServiceSettingsForm.Optimization.PersistOptimizations",
                isOn: $settings.persistOptimizations
            )
        } header: {
            Text("InferenceServiceSettingsForm.Optimization")
        } footer: {
            Text("InferenceServiceSettingsForm.Optimization.Footer")
        }
    }
    
    @ViewBuilder
    var executionProviderSection: some View {
        @Bindable var settings = settings.executionProvider
        
        Section {
            Picker(
                "InferenceServiceSettingsForm.ExecutionProvider.EfficientCoreML",
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
                "InferenceServiceSettingsForm.ExecutionProvider.InefficientCoreML",
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
                "InferenceServiceSettingsForm.ExecutionProvider.NeuralNetworkCoreML",
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
            Text("InferenceServiceSettingsForm.ExecutionProvider")
        } footer: {
            Text("InferenceServiceSettingsForm.ExecutionProvider.Footer")
        }
        .pickerStyle(.segmented)
    }
}

fileprivate extension InferenceServiceSettingsForm {
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
            Text("InferenceServiceSettingsForm.PreloadModels")
        } footer: {
            Text("InferenceServiceSettingsForm.PreloadModels.Footer")
        }
    }
    
    @ViewBuilder
    var addPreloadModelMenu: some View {
        Menu("InferenceServiceSettingsForm.PreloadModels.Add") {
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
                "InferenceServiceSettingsForm.PreloadModels.Remove",
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

fileprivate extension InferenceServiceSettingsForm {
    @ViewBuilder
    var endpointSections: some View {
        Section {
            EndpointField(
                InferenceModelSuite.Provider.ImmichAppEndpoint.self,
                url: $settings.immichAppEndpointURL
            )
        } header: {
            Text("InferenceServiceSettingsForm.ImmichAppEndpoint")
        } footer: {
            Text("InferenceServiceSettingsForm.ImmichAppEndpoint.Footer")
        }
    }
}

fileprivate extension InferenceServiceSettingsForm {
    @ViewBuilder
    var cacheSection: some View {
        Section {
            TextField(
                "InferenceServiceSettingsForm.Cache.Lifespan",
                value: $settings.loadedLifespan,
                format: .number.grouping(.never),
                prompt: Text("InferenceServiceSettingsForm.Cache.Lifespan.Prompt")
            )
        } header: {
            Text("InferenceServiceSettingsForm.Cache")
        } footer: {
            Text("InferenceServiceSettingsForm.Cache.Footer")
        }
    }
}
