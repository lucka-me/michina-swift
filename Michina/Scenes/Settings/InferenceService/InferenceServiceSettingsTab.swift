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
                endpointsSection
                cacheSection
            }
            .frame(minWidth: 400, minHeight: 400)
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
                HStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: 6) {
                            Text(enumeration.element.suiteCategory.titleKey)
                            Divider()
                            Text(enumeration.element.category.titleKey)
                        }
                        .font(.caption)
                        
                        Text(enumeration.element.suiteName)
                            .monospaced()
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        settings.preloadModels.remove(at: enumeration.offset)
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
            EndpointField<InferenceModelSuite.Provider.ImmichAppEndpoint>(
                "InferenceServiceSettingsTab.Endpoints.ImmichApp",
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
        @Bindable var settings = settings.cache
        
        Section {
            TextField(
                "InferenceServiceSettingsTab.Cache.Lifespan",
                value: $settings.lifespan,
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

fileprivate struct EndpointField<
    Endpoint: InferenceModelSuite.Provider.MirrorableEndpoint
> : View {
    @Binding private var url: URL?
    
    @Environment(\.alert) private var alert
    
    @State private var inputValue: URL?
    
    @State private var isVerified: Bool = false
    @State private var progress: Progress? = nil
    
    private let titleKey: LocalizedStringKey
    
    init(_ titleKey: LocalizedStringKey, url: Binding<URL?>) {
        self._url = url
        self._inputValue = .init(initialValue: url.wrappedValue)
        self.titleKey = titleKey
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TextField(
                titleKey,
                value: $inputValue,
                format: format,
                prompt: Text(Endpoint.defaultBaseURL, format: format)
            )
            .onSubmit {
                alert.whenTrying(verify)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(
                    """
                    InferenceServiceSettingsTab.Endpoints.Provider \
                    \(Text(Endpoint.provider.titleKey).italic())
                    """
                )
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    alert.whenTrying(verify)
                } label: {
                    if isVerified {
                        Text("InferenceServiceSettingsTab.Endpoints.Verified")
                            .foregroundStyle(.green)
                    } else {
                        Text("InferenceServiceSettingsTab.Endpoints.Verify")
                    }
                }
                .disabled(inputValue == nil)
                .opacity(progress != nil ? 0 : 1)
                .overlay {
                    if let progress {
                        ProgressView(progress)
                            .progressViewStyle(.circular)
                    }
                }
                
                Button(role: .destructive) {
                    url = nil
                    inputValue = nil
                }
                .disabled(url == nil)
            }
        }
        .disabled(progress != nil)
        .onChange(of: inputValue) {
            isVerified = false
        }
    }
    
    private var format: URL.FormatStyle {
        .url.path(.omitWhen(.path, matches: [ "", "/" ]))
    }
    
    private func verify() async throws {
        guard let inputValue else {
            isVerified = false
            return
        }
        progress = .init()
        defer {
            progress = nil
        }
        let endpoint = Endpoint(baseURL: inputValue)
        guard try await endpoint.verify() else {
            isVerified = false
            return
        }
        isVerified = true
        url = inputValue
    }
}
