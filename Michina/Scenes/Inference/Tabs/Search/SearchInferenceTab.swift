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
    @State private var visualOutputs: [ VisualOutput ] = [ ]
    
    @State private var textualModel: InferenceModel
    @State private var searchText: String = ""
    @State private var textualProgress: Progress? = nil
    @State private var textualOutputs: [ TextualOutput ] = [ ]
    @State private var selection: TextualOutput? = nil
    
    @State private var isInspectorPresented = true
    
    private let service = InferenceService.default
    
    init(suiteName: String?) {
        if let suiteName {
            self._visualModel = if
                let model = Self.visualModels.first(where: { $0.suiteName == suiteName })
            {
                .init(initialValue: model)
            } else {
                .init(initialValue: Self.visualModels.first!)
            }
            self._textualModel = if
                let model = Self.textualModels.first(where: { $0.suiteName == suiteName })
            {
                .init(initialValue: model)
            } else {
                .init(initialValue: Self.textualModels.first!)
            }
        } else {
            self._visualModel = .init(initialValue: Self.visualModels.first!)
            self._textualModel = .init(initialValue: Self.textualModels.first!)
        }
    }
    
    var body: some TabContent<InferenceModelSuite.Category> {
        Tab(
            Self.category.titleKey,
            systemImage: Self.category.systemImage,
            value: Self.category
        ) {
            visualContent
                .frame(minWidth: 300)
                .toolbar {
                    toolbarContent
                }
                .inspector(isPresented: $isInspectorPresented) {
                    textualContent
                }
        }
    }
}

extension SearchInferenceTab {
    static let category = InferenceModelSuite.Category.search
}

fileprivate extension SearchInferenceTab {
    static let visualModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.visual] }
    static let textualModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.textual] }
}

fileprivate extension SearchInferenceTab {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if !visualOutputs.isEmpty || !textualOutputs.isEmpty {
            ToolbarItem(placement: .destructiveAction) {
                Button(
                    "SearchInferenceTab.Action.ClearOutputHistory",
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

fileprivate extension SearchInferenceTab {
    typealias VisualPipeline = VisualSearchInferencePipeline
    
    struct VisualOutput : Identifiable {
        let id = UUID()
        let index: Int
        
        let input: Image
        let modelSuiteName: String
        
        let elapse: Duration
        let data: VisualPipeline.Output
    }
    
    @ViewBuilder
    var visualContent: some View {
        ScrollView(.vertical) {
            LazyVGrid(
                columns: [
                    .init(.adaptive(minimum: 150, maximum: 300), spacing: 12, alignment: .top)
                ]
            ) {
                Color.secondary
                    .opacity(0.4)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .top) {
                        visualPhotoPicker
                    }
                    .overlay(alignment: .bottom) {
                        visualInputContent
                            .padding(8)
                            .background(.thinMaterial.opacity(0.6))
                    }
                    .clipShape(.rect(cornerRadius: 12))
                
                ForEach(sortedVisualOutputs, id: \.output.id) { output in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            output.output.input
                                .resizable()
                                .scaledToFill()
                        }
                        .overlay(alignment: .bottom) {
                            VStack(alignment: .trailing, spacing: 8) {
                                if let distance = output.distance {
                                    if distance != .infinity {
                                        Text(
                                            distance,
                                            format: .number.precision(.fractionLength(4))
                                        )
                                    } else {
                                        Text("SearchInferenceTab.Output.DifferentModel")
                                    }
                                }
                                
                                HStack {
                                    Label(
                                        output.output.index,
                                        format: .number.precision(.integerLength(2)),
                                        systemImage: "number"
                                    )
                                    
                                    Spacer()
                                    
                                    Text(output.output.elapse, format: .elapse)
                                }
                            }
                            .padding(8)
                            .background(.thinMaterial.opacity(0.6))
                        }
                        .clipShape(.rect(cornerRadius: 12))
                }
                .monospaced()
            }
            .animation(.bouncy, value: selection)
        }
        .contentMargins(.vertical, 8, for: .scrollContent)
        .contentMargins(.horizontal, 12, for: .scrollContent)
    }
    
    @ViewBuilder
    var visualPhotoPicker: some View {
        UnifiedPhotoPicker(selection: $imageData) {
            if let imageData {
                imageData.image
                    .resizable()
                    .scaledToFill()
            } else {
                Label("UnifiedPhotoPicker.DefaultLabel", systemImage: "plus.viewfinder")
                    .padding(24)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    var visualInputContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(
                "SearchInferenceTab.Visual.Input.Model",
                selection: $visualModel
            ) {
                ForEach(Self.visualModels) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
            .labelsHidden()
            
            if let visualProgress {
                ProgressView(visualProgress)
            } else {
                Button("SearchInferenceTab.Visual.Input.Run") {
                    alert.whenTrying(runVisualInference)
                }
                .disabled(imageData == nil)
            }
        }
    }
    
    var sortedVisualOutputs: [ (output: VisualOutput, distance: Float?) ] {
        guard let selection else {
            return visualOutputs.map { ($0, nil) }
        }
        return visualOutputs
            .map { ($0, selection.distance(to: $0)) }
            .sorted { lhs, rhs in
                return if lhs.distance != .infinity {
                    if rhs.distance != .infinity {
                        lhs.distance! < rhs.distance!
                    } else {
                        true
                    }
                } else {
                    false
                }
            }
    }
    
    func runVisualInference() async throws {
        guard
            self.visualProgress == nil,
            let imageData
        else {
            return
        }
        
        self.visualProgress = .init()
        defer {
            self.visualProgress = nil
        }
        
        guard let image = CIImage(data: imageData.data) else {
            alert(message: "Unable to decode the image.")
            return
        }
        
        let model = self.visualModel
        let input = VisualPipeline.Input(model: model, image: image)
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        let output = try await service.run(VisualPipeline.self, input: input)
        
        let elapse = clock.now - startTime
        
        self.visualOutputs.append(
            .init(
                index: self.visualOutputs.count,
                input: imageData.image,
                modelSuiteName: model.suiteName,
                elapse: elapse,
                data: output
            )
        )
    }
}

fileprivate extension SearchInferenceTab {
    typealias TextualPipeline = TextualSearchInferencePipeline
    
    struct TextualOutput : Hashable, Identifiable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        let id = UUID()
        let index: Int
        
        let input: String
        let modelSuiteName: String
        
        let elapse: Duration
        let data: VisualPipeline.Output
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
    }
    
    @ViewBuilder
    var textualContent: some View {
        Form {
            textualInputSection
            
            ForEach(textualOutputs.reversed()) { output in
                Section {
                    LabeledContent {
                        if selection == output {
                            Text("SearchInferenceTab.Textual.Applied")
                        } else {
                            Button("SearchInferenceTab.Textual.Apply") {
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
        .formStyle(.grouped)
    }
    
    @ViewBuilder
    var textualInputSection: some View {
        Section("SearchInferenceTab.Textual.Input") {
            Picker(
                "SearchInferenceTab.Textual.Input.Model",
                selection: $textualModel
            ) {
                ForEach(Self.textualModels) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
            .labelsHidden()
            
            TextField("SearchInferenceTab.Textual.Input.SearchText", text: $searchText)
                .onSubmit(of: .text) {
                    alert.whenTrying(runTextualInference)
                }
                .textFieldStyle(.roundedBorder)
            
            if let textualProgress {
                ProgressView(textualProgress)
            } else {
                Button("SearchInferenceTab.Textual.Input.Run") {
                    alert.whenTrying(runTextualInference)
                }
                .disabled(searchText.isEmpty)
            }
        }
    }
    
    func runTextualInference() async throws {
        guard self.textualProgress == nil else {
            return
        }
        
        let searchText = self.searchText
        guard !searchText.isEmpty else {
            return
        }
        
        self.textualProgress = .init()
        defer {
            self.textualProgress = nil
        }
        
        let model = self.textualModel
        
        let input = TextualPipeline.Input(
            model: model,
            language: "",
            text: searchText
        )
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        let output = try await service.run(TextualPipeline.self, input: input)
        
        let elapse = clock.now - startTime
        
        self.textualOutputs.append(
            .init(
                index: self.textualOutputs.count,
                input: searchText,
                modelSuiteName: model.suiteName,
                elapse: elapse,
                data: output
            )
        )
    }
}

fileprivate extension SearchInferenceTab.TextualOutput {
    func distance(to other: SearchInferenceTab.VisualOutput) -> Float {
        guard self.modelSuiteName == other.modelSuiteName else {
            return .infinity
        }
        
        let (dot, normSelf, normOther) = zip(self.data, other.data)
            .reduce(
                into: (dot: Float.zero, normSelf: Float.zero, normOther: Float.zero)
            ) { partial, pair in
                partial.dot += pair.0 * pair.1
                partial.normSelf += pair.0 * pair.0
                partial.normOther += pair.1 * pair.1
            }
        return 1 - dot / sqrt(normSelf * normOther)
    }
}
