//
//  ModelsTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import Magearna
import SwiftUI

struct ModelsTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var cache = InferenceService.default.cache
    
    @State private var searchText: String = ""
    
    @State private var isInspectorPresented = true
    @State private var selection: InferenceModelSuite? = nil
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            List(selection: $selection) {
                if searchText.isEmpty {
                    ForEach(InferenceModelSuite.Category.allCases) { category in
                        Section {
                            ForEach(InferenceModelSuite.all[category]!) { suite in
                                row(of: suite)
                            }
                            .listRowSeparator(.hidden)
                        } header: {
                            Label(category)
                        }
                    }
                } else {
                    ForEach(searchResults) { suite in
                        row(of: suite)
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.inset)
            .searchable(text: $searchText, placement: .toolbar)
            .frame(minWidth: 300, minHeight: 400)
            .navigationTitle(Self.titleKey)
            .navigationSubtitle(navigationSubtitleKey)
            .inspector(isPresented: $isInspectorPresented) {
                if let selection {
                    InferenceModelSuiteDetailView(suite: selection)
                } else {
                    Text("No Selection")
                        .font(.system(.title, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: selection) {
                if selection != nil {
                    isInspectorPresented = true
                }
            }
        }
        .badge(cache.sessions.count)
    }
}

fileprivate extension ModelsTab {
    static let titleKey: LocalizedStringKey = "Models"
    static let systemImage: String = "brain"
}

fileprivate extension ModelsTab {
    var searchResults: [ InferenceModelSuite ] {
        InferenceModelSuite.all.flatMap { (category, suites) in
            suites.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

fileprivate extension ModelsTab {
    @ViewBuilder
    func row(of suite: InferenceModelSuite) -> some View {
        VStack(alignment: .leading) {
            Text(suite.name)
                .font(.headline)
                .textSelection(.enabled)
                .lineLimit(1)
            HStack {
                ForEach(InferenceModel.Category.allCases) { category in
                    if let model = suite.models[category] {
                        label(of: model)
                    }
                }
            }
            .font(.system(.caption, weight: .thin))
        }
        .monospaced()
        .tag(suite)
    }
    
    @ViewBuilder
    func label(of model: InferenceModel) -> some View {
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

fileprivate extension ModelsTab {
    var navigationSubtitleKey: LocalizedStringKey {
        if cache.sessions.isEmpty {
            "No model loaded."
        } else {
            "Loaded \(cache.sessions.count) models."
        }
    }
}
