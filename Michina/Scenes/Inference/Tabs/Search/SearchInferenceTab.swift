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
    
    @State private var category = InferenceModel.Category.visual
    @State private var visualModel: InferenceModel
    @State private var textualModel: InferenceModel
    @State private var imageData: UnifiedPhotoPicker.ImageData? = nil
    @State private var searchText: String = ""
    
    @State private var executionProgress: Progress? = nil
    
    @State private var outputs: [ Output ] = [ ]
    @State private var selection: Output? = nil
    
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
            List(selection: $selection) {
                ForEach(outputs) { output in
                    section(for: output)
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 300)
            .toolbar {
                toolbarContent
            }
            .inspector(isPresented: $isInspectorPresented) {
                Form {
                    modelSection
                    inputSection
                }
                .formStyle(.grouped)
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
    @ViewBuilder
    var modelSection: some View {
        Section("Model") {
            Picker("Category", selection: $category) {
                ForEach(
                    [ InferenceModel.Category.visual, InferenceModel.Category.textual ]
                ) { category in
                    Label(category)
                        .tag(category)
                }
            }
            .pickerStyle(.palette)
            .labelsHidden()
            
            Picker(
                "Model",
                selection: category == .visual ? $visualModel : $textualModel
            ) {
                ForEach(category == .visual ? Self.visualModels : Self.textualModels) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
            .labelsHidden()
        }
    }
    
    @ViewBuilder
    var inputSection: some View {
        Section("Input") {
            if category == .visual {
                if let image = imageData?.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                UnifiedPhotoPicker($imageData)
            } else {
                TextField("Search Text", text: $searchText)
            }
        }
    }
}

fileprivate extension SearchInferenceTab {
    typealias VisualPipeline = VisualSearchInferencePipeline
    typealias TextualPipeline = TextualSearchInferencePipeline
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if isReadyToRun {
            ToolbarItem(placement: .primaryAction) {
                Button("Run Inference", systemImage: "play", role: .confirm) {
                    if category == .visual {
                        alert.whenTrying(runVisualInference)
                    } else {
                        alert.whenTrying(runTextualInference)
                    }
                }
                .disabled(executionProgress != nil)
                .overlay {
                    if let executionProgress {
                        ProgressView(executionProgress)
                            .progressViewStyle(.circular)
                    }
                }
            }
        }
        
        if !outputs.isEmpty {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear History", systemImage: "trash", role: .destructive) {
                    selection = nil
                    outputs.removeAll()
                }
            }
        }
    }
    
    var isReadyToRun: Bool {
        if category == .visual {
            imageData != nil
        } else {
            !searchText.isEmpty
        }
    }
    
    func runVisualInference() async throws {
        self.executionProgress = .init()
        defer {
            self.executionProgress = nil
        }
        
        guard
            let imageData,
            let image = CIImage(data: imageData.data)
        else {
            alert(message: "Unable to decode the image.")
            return
        }
        
        let model = self.visualModel
        let input = VisualPipeline.Input(model: model, image: image)
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        let output = try await service.run(VisualPipeline.self, input: input)
        
        let elapse = clock.now - startTime
        
        self.outputs.append(
            .init(
                index: self.outputs.count,
                input: .visual(image: imageData.image),
                modelSuiteName: model.suiteName,
                elapse: elapse,
                embedding: output
            )
        )
    }
    
    func runTextualInference() async throws {
        self.executionProgress = .init()
        defer {
            self.executionProgress = nil
        }
        
        let searchText = self.searchText
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
        
        self.outputs.append(
            .init(
                index: self.outputs.count,
                input: .textual(text: searchText),
                modelSuiteName: model.suiteName,
                elapse: elapse,
                embedding: output
            )
        )
    }
}

fileprivate extension SearchInferenceTab {
    struct Output : Hashable, Identifiable, Sendable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        enum Input : Sendable {
            case visual(image: Image)
            case textual(text: String)
        }
        
        let id = UUID()
        let index: Int
        
        let input: Input
        let modelSuiteName: String
        
        let elapse: Duration
        let embedding: [ Float ]
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
    }
    
    @ViewBuilder
    func section(for output: Output) -> some View {
        Section {
            HStack(alignment: .top) {
                switch output.input {
                case .visual(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: 6))
                        .frame(maxWidth: 240)
                case .textual(let text):
                    Text(text)
                        .monospaced()
                        .frame(maxWidth: 240, alignment: .topLeading)
                }
                
                Spacer()
                
                if let selection, selection != output {
                    if selection.modelSuiteName == output.modelSuiteName {
                        Text(
                            output.distance(to: selection),
                            format: .number.precision(.fractionLength(4))
                        )
                    } else {
                        Text("Different Model with Selection")
                    }
                }
            }
            .tag(output)
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
            .monospaced()
        }
    }
}

fileprivate extension SearchInferenceTab.Output {
    func distance(to other: Self) -> Float {
        let (dot, normSelf, normOther) = zip(self.embedding, other.embedding)
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
