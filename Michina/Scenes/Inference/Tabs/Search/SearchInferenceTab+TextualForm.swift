//
//  SearchInferenceTab+TextualForm.swift
//  Michina
//
//  Created by Lucka on 2026-06-22.
//

import Magearna
import SwiftUI

extension SearchInferenceTab {
    struct TextualForm : View {
        @Binding private var model: InferenceModel
        @Binding private var outputs: [ Output ]
        @Binding private var selection: Output?
        
        @Environment(\.alert) private var alert
        
        @State private var searchText: String = ""
        @State private var progress: Progress? = nil
        
        private let service = InferenceService.default
        
        init(
            model: Binding<InferenceModel>,
            outputs: Binding<[ Output ]>,
            selection: Binding<Output?>
        ) {
            self._model = model
            self._outputs = outputs
            self._selection = selection
        }
        
        var body: some View {
            Form {
                inputSection
            }
            .formStyle(.grouped)
        }
    }
}

extension SearchInferenceTab.TextualForm {
    static let models = InferenceModelSuite.all[.search]!
        .compactMap { $0.models[.visual] }
}

extension SearchInferenceTab.TextualForm {
    typealias Pipeline = TextualSearchInferencePipeline
    
    struct Output : Hashable, Identifiable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        let id = UUID()
        let index: Int
        
        let input: String
        let modelSuiteName: String
        
        let elapse: Duration
        let data: Pipeline.Output
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
    }
}

fileprivate extension SearchInferenceTab.TextualForm {
    @ViewBuilder
    var inputSection: some View {
        Section("SearchInferenceTab.TextualForm.Input") {
            Picker(
                "SearchInferenceTab.TextualForm.Input.Model",
                selection: $model
            ) {
                ForEach(Self.models) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
            .labelsHidden()
            
            TextField("SearchInferenceTab.TextualForm.Input.SearchText", text: $searchText)
                .onSubmit(of: .text) {
                    alert.whenTrying(runInference)
                }
                .textFieldStyle(.roundedBorder)
            
            if let progress {
                ProgressView(progress)
            } else {
                Button("SearchInferenceTab.TextualForm.Input.Run") {
                    alert.whenTrying(runInference)
                }
                .disabled(searchText.isEmpty)
            }
        }
    }
    
    func runInference() async throws {
        guard self.progress == nil else {
            return
        }
        
        let searchText = self.searchText
        guard !searchText.isEmpty else {
            return
        }
        
        self.progress = .init()
        defer {
            self.progress = nil
        }
        
        let model = self.model
        
        let input = Pipeline.Input(
            model: model,
            language: "",
            text: searchText
        )
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        let output = try await service.run(Pipeline.self, input: input)
        
        let elapse = clock.now - startTime
        
        self.outputs.append(
            .init(
                index: self.outputs.count,
                input: searchText,
                modelSuiteName: model.suiteName,
                elapse: elapse,
                data: output
            )
        )
        self.selection = self.outputs.last
    }
}

fileprivate extension SearchInferenceTab.TextualForm {
    @ViewBuilder
    var outputSections: some View {
        ForEach(outputs.reversed()) { output in
            Section {
                LabeledContent {
                    if selection == output {
                        Text("SearchInferenceTab.TextualForm.Applied")
                    } else {
                        Button("SearchInferenceTab.TextualForm.Apply") {
                            selection = output
                        }
                        .buttonStyle(.link)
                    }
                } label: {
                    Text(output.input)
                        .monospaced()
                        .textSelection(.enabled)
                }
            } header: {
                HStack(spacing: 12) {
                    Label(
                        output.index,
                        format: .number.precision(.integerLength(2)),
                        systemImage: "number"
                    )
                    
                    Spacer()
                    
                    Text(output.elapse, format: .elapse)
                }
            }
        }
    }
}
