//
//  ModelsPage.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import Magearna
import SwiftUI

struct ModelsPage : View {
    @Environment(\.alert) private var alert
    
    @State private var cache = InferenceService.default.cache
    
    @State private var searchText: String = ""
    
    @State private var isInspectorPresented = true
    @State private var selection: InferenceModelSuite? = nil
    
    var body: some View {
        List(selection: $selection) {
            if searchText.isEmpty {
                ForEach(InferenceModelSuite.Category.allCases) { category in
                    Section {
                        ForEach(
                            InferenceModelSuite.all[category]!,
                            content: row(suite:)
                        )
                    } header: {
                        Label(category)
                    }
                }
                .listRowSeparator(.hidden)
            } else {
                ForEach(searchResults, content: row(suite:))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.inset)
        .searchable(text: $searchText, placement: .toolbar)
        .frame(minWidth: 300, minHeight: 400)
        .navigationTitle(Self.titleKey)
        .navigationSubtitle("ModelsPage.Subtitle \(cache.sessions.count)")
        .inspector(isPresented: $isInspectorPresented, content: inspectorContent)
        .onChange(of: selection) {
            if selection != nil {
                isInspectorPresented = true
            }
        }
    }
}

extension ModelsPage : @MainActor LabelableMetatype {
    static let titleKey: LocalizedStringKey = "ModelsPage"
    static let systemImage: String = "brain"
}

extension ModelsPage {
    static let identifier = "ModelsPage"
}

fileprivate extension ModelsPage {
    var searchResults: [ InferenceModelSuite ] {
        InferenceModelSuite.all.flatMap { (category, suites) in
            suites.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

fileprivate extension ModelsPage {
    @ViewBuilder
    func inspectorContent() -> some View {
        if let selection {
            InferenceModelSuiteDetailView(suite: selection)
        } else {
            Text("ModelsPage.NoSelection")
                .font(.system(.title, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

fileprivate extension ModelsPage {
    @ViewBuilder
    func row(suite: InferenceModelSuite) -> some View {
        VStack(alignment: .leading) {
            Text(suite.name)
                .font(.headline)
                .textSelection(.enabled)
                .lineLimit(1)
            HStack {
                ForEach(InferenceModel.Category.allCases) { category in
                    if let model = suite.models[category] {
                        label(model: model)
                    }
                }
            }
            .font(.system(.caption, weight: .thin))
        }
        .monospaced()
        .tag(suite)
    }
    
    @ViewBuilder
    func label(model: InferenceModel) -> some View {
        let color: Color = if model.isBuiltin {
            .mint.opacity(0.6)
        } else if cache.sessions[model] != nil {
            .green.opacity(0.8)
        } else {
            .gray.opacity(0.2)
        }
        
        Text(model.category.titleKey)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.gradient, in: .capsule)
    }
}
