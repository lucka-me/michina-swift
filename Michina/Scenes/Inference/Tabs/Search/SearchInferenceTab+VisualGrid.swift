//
//  SearchInferenceTab+VisualGrid.swift
//  Michina
//
//  Created by Lucka on 2026-06-22.
//

import Magearna
import SwiftUI

extension SearchInferenceTab {
    struct VisualGrid : View {
        @Binding private var model: InferenceModel
        @Binding private var outputs: [ Output ]
        
        @Environment(\.alert) private var alert
        
        @State private var images: [ ImageData ] = [ ]
        @State private var progress: Progress? = nil
        
        private let service = InferenceService.default
        private let selection: TextualForm.Output?
        
        init(
            model: Binding<InferenceModel>,
            outputs: Binding<[ Output ]>,
            selection: TextualForm.Output?
        ) {
            self._model = model
            self._outputs = outputs
            self.selection = selection
        }
        
        var body: some View {
            ScrollView(.vertical) {
                LazyVGrid(columns: Self.columns) {
                    inputCell
                    
                    ForEach(
                        sortedOutputs,
                        id: \.output.id,
                        content: cell(output:)
                    )
                    .monospaced()
                }
                .animation(.bouncy, value: selection)
            }
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins([ .horizontal, .bottom ], 12, for: .scrollContent)
        }
    }
}

extension SearchInferenceTab.VisualGrid {
    static let models = InferenceModelSuite.all[.search]!
        .compactMap { $0.models[.visual] }
}

extension SearchInferenceTab.VisualGrid {
    typealias Pipeline = VisualSearchInferencePipeline
    
    struct Output : Identifiable {
        let id = UUID()
        let index: Int
        
        let input: Image
        let modelSuiteName: String
        
        let elapse: Duration
        let data: Pipeline.Output
    }
}

fileprivate extension SearchInferenceTab.VisualGrid {
    static let columns: [ GridItem ] = [
        .init(
            .adaptive(minimum: 150, maximum: 300),
            spacing: 12,
            alignment: .top
        )
    ]
}

fileprivate extension SearchInferenceTab.VisualGrid {
    @ViewBuilder
    var inputCell: some View {
        Color.secondary
            .opacity(0.4)
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .top) {
                UnifiedPhotoPicker(selection: $images) {
                    photoPickerLabel
                }
                .buttonStyle(.plain)
            }
            .overlay(alignment: .bottom) {
                inputContent
                    .padding(8)
                    .background(.thinMaterial.opacity(0.8))
            }
            .clipShape(.rect(cornerRadius: 12))
    }
    
    @ViewBuilder
    var photoPickerLabel: some View {
        Color.clear
            .overlay(alignment: images.isEmpty ? .top : .center) {
                if let image = images.first?.image {
                    image
                        .scaledToFill()
                } else {
                    Label(
                        "UnifiedPhotoPicker.DefaultLabel",
                        systemImage: "plus.viewfinder"
                    )
                    .padding(24)
                }
            }
            .overlay(alignment: .topTrailing) {
                if images.count > 1 {
                    Text("UnifiedPhotoPicker.Multiple \(images.count - 1)")
                        .font(.caption)
                        .padding(6)
                        .background(
                            .thinMaterial.opacity(0.5),
                            in: .rect(cornerRadius: 6, style: .continuous)
                        )
                        .padding(6)
                }
            }
            .contentShape(.rect)
    }
    
    @ViewBuilder
    var inputContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(
                "SearchInferenceTab.VisualGrid.Input.Model",
                selection: $model
            ) {
                ForEach(Self.models) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
            .labelsHidden()
            
            ZStack(alignment: .leading) {
                Button("SearchInferenceTab.VisualGrid.Input.Run") {
                    alert.whenTrying(runInference)
                }
                .disabled(images.isEmpty || progress != nil)
                .opacity(progress == nil ? 1 : 0)
                
                if let progress {
                    ProgressView(progress)
                }
            }
        }
    }
    
    func runInference() async throws {
        guard self.progress == nil else {
            return
        }
        
        self.progress = .init()
        defer {
            self.progress = nil
        }
        
        struct TaskResult : Sendable {
            let offset: Int
            let input: Image
            let elapse: Duration
            let data: Pipeline.Output
        }
        
        let images = self.images
        let model = self.model
        let results = try await withThrowingTaskGroup { @Sendable group in
            for enumeration in images.enumerated() {
                guard let image = CIImage(data: enumeration.element.data) else {
                    throw AlertAction.Message("Unable to decode the image.")
                }
                
                group.addTask {
                    let input = Pipeline.Input(model: model, image: image)
                    
                    let clock = ContinuousClock()
                    let startTime = clock.now
                    
                    let output = try await service.run(Pipeline.self, input: input)
                    
                    let elapse = clock.now - startTime
                    
                    return TaskResult(
                        offset: enumeration.offset,
                        input: enumeration.element.image,
                        elapse: elapse,
                        data: output
                    )
                }
            }
            
            return try await group
                .reduce(into: [ ]) {
                    $0.append($1)
                }
                .sorted(using: KeyPathComparator(\.offset))
        }
        
        let indexStart = self.outputs.count
        self.outputs.append(
            contentsOf: results.map {
                .init(
                    index: indexStart + $0.offset,
                    input: $0.input,
                    modelSuiteName: model.suiteName,
                    elapse: $0.elapse,
                    data: $0.data
                )
            }
        )
    }
}

fileprivate extension SearchInferenceTab.VisualGrid {
    @ViewBuilder
    func cell(output: (output: Output, distance: Float?)) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                output.output.input
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
                            Text("SearchInferenceTab.VisualGrid.Output.DifferentModel")
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
                .background(.thinMaterial.opacity(0.8))
            }
            .clipShape(.rect(cornerRadius: 12))
    }
    
    var sortedOutputs: [ (output: Output, distance: Float?) ] {
        guard let selection else {
            return outputs.map { ($0, nil) }
        }
        return outputs
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
}

fileprivate extension SearchInferenceTab.TextualForm.Output {
    func distance(to other: SearchInferenceTab.VisualGrid.Output) -> Float {
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
