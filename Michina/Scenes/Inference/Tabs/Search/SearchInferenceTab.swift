//
//  SearchInferenceTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import Magearna
import SwiftUI

struct SearchInferenceTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var visualModel: InferenceModel
    @State private var imageData: ImageData? = nil
    @State private var visualProgress: Progress? = nil
    @State private var visualOutputs: [ VisualGrid.Output ] = [ ]
    
    @State private var textualModel: InferenceModel
    @State private var textualOutputs: [ TextualForm.Output ] = [ ]
    @State private var selection: TextualForm.Output? = nil
    
    @State private var isInspectorPresented = true
    
    private let service = InferenceService.default
    
    init(suiteName: String?) {
        if let suiteName {
            self._visualModel = if
                let model = VisualGrid.models.first(
                    where: { $0.suiteName == suiteName }
                )
            {
                .init(initialValue: model)
            } else {
                .init(initialValue: VisualGrid.models.first!)
            }
            self._textualModel = if
                let model = TextualForm.models.first(
                    where: { $0.suiteName == suiteName }
                )
            {
                .init(initialValue: model)
            } else {
                .init(initialValue: TextualForm.models.first!)
            }
        } else {
            self._visualModel = .init(initialValue: VisualGrid.models.first!)
            self._textualModel = .init(initialValue: TextualForm.models.first!)
        }
    }
    
    var body: some TabContent<InferenceModelSuite.Category> {
        Tab(
            Self.category.titleKey,
            systemImage: Self.category.systemImage,
            value: Self.category
        ) {
            VisualGrid(
                model: $visualModel,
                outputs: $visualOutputs,
                selection: selection
            )
            .frame(minWidth: 300)
            .toolbar(content: toolbarContent)
            .inspector(isPresented: $isInspectorPresented) {
                TextualForm(
                    model: $textualModel,
                    outputs: $textualOutputs,
                    selection: $selection
                )
            }
        }
    }
}

extension SearchInferenceTab {
    static let category = InferenceModelSuite.Category.search
}

fileprivate extension SearchInferenceTab {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        if !visualOutputs.isEmpty || !textualOutputs.isEmpty {
            ToolbarItem(placement: .destructiveAction) {
                Button(
                    "SearchInferenceTab.Action.ClearOutputs",
                    systemImage: "trash",
                    role: .destructive
                ) {
                    selection = nil
                    visualOutputs.removeAll()
                    textualOutputs.removeAll()
                }
            }
        }
    }
}
