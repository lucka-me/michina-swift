//
//  CharacterRecognitionInferencePage.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import Geometry
import Magearna
import SwiftUI

struct CharacterRecognitionInferencePage : View {
    @Environment(\.alert) private var alert
    
    @State private var values = ViewValues()
    
    @State private var isInspectorPresented = true
    
    @State private var detectionModel: InferenceModel
    @State private var recognitionModel: InferenceModel
    
    @State private var images: [ ImageData ] = [ ]
    
    @State private var executionProgress: Progress? = nil
    @State private var outputs: [ Output ] = [ ]
    
    private let service = InferenceService.default
    
    init(suiteName: String?) {
        if let suiteName {
            self._detectionModel = if
                let model = Self.detectionModels.first(where: { $0.suiteName == suiteName })
            {
                .init(initialValue: model)
            } else {
                .init(initialValue: Self.detectionModels.first!)
            }
            self._recognitionModel = if
                let model = Self.recognitionModels.first(where: { $0.suiteName == suiteName })
            {
                .init(initialValue: model)
            } else {
                .init(initialValue: Self.recognitionModels.first!)
            }
        } else {
            self._detectionModel = .init(initialValue: Self.detectionModels.first!)
            self._recognitionModel = .init(initialValue: Self.recognitionModels.first!)
        }
    }
    
    var body: some View {
        List {
            ForEach(outputs, content: section(output:))
        }
        .listStyle(.inset)
        .frame(minWidth: 300)
        .toolbar(content: toolbarContent)
        .inspector(isPresented: $isInspectorPresented) {
            Form {
                modelsSection
                inputSections
            }
            .formStyle(.grouped)
        }
    }
}

extension CharacterRecognitionInferencePage {
    static let category = InferenceModelSuite.Category.characterRecognition
}

fileprivate extension CharacterRecognitionInferencePage {
    static let detectionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.detection] }
    static let recognitionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.recognition] }
}

fileprivate extension CharacterRecognitionInferencePage {
    @MainActor
    @Observable
    final class ViewValues {
        private struct Storage {
            @AppStorage("CharacterRecognitionInferenceTab.DetectionMinimalConfidence")
            var detectionMinimalConfidence = 0.5
            
            @AppStorage("CharacterRecognitionInferenceTab.DetectionMaximalResolution")
            var detectionMaximalResolution = 736
            
            @AppStorage("CharacterRecognitionInferenceTab.RecognitionMinimalConfidence")
            var recognitionMinimalConfidence = 0.8
        }
        
        var detectionMinimalConfidence: Double {
            didSet { storage.detectionMinimalConfidence = detectionMinimalConfidence }
        }
        
        var detectionMaximalResolution: Int {
            didSet { storage.detectionMaximalResolution = detectionMaximalResolution }
        }
        
        var recognitionMinimalConfidence: Double {
            didSet { storage.recognitionMinimalConfidence = recognitionMinimalConfidence }
        }
        
        private let storage = Storage()
        
        init() {
            self.detectionMinimalConfidence = storage.detectionMinimalConfidence
            self.detectionMaximalResolution = storage.detectionMaximalResolution
            self.recognitionMinimalConfidence = storage.recognitionMinimalConfidence
        }
    }
    
    @ViewBuilder
    var modelsSection: some View {
        Section("CharacterRecognitionInferencePage.Inspector.Models") {
            Picker(
                InferenceModel.Category.detection.titleKey,
                selection: $detectionModel
            ) {
                ForEach(Self.detectionModels) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
            Picker(
                InferenceModel.Category.recognition.titleKey,
                selection: $recognitionModel
            ) {
                ForEach(Self.recognitionModels) { model in
                    Text(model.suiteName)
                        .tag(model)
                }
            }
        }
    }
    
    @ViewBuilder
    var inputSections: some View {
        Section("CharacterRecognitionInferencePage.Inspector.Photo") {
            UnifiedPhotoPicker(selection: $images) {
                if let image = images.first?.image {
                    image
                        .aspectRatio(contentMode: .fit)
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
                } else {
                    Label(
                        "UnifiedPhotoPicker.DefaultLabel",
                        systemImage: "plus.viewfinder"
                    )
                }
            }
            .buttonStyle(.plain)
        }
        
        Section("CharacterRecognitionInferencePage.Inspector.Parameters") {
            VStack {
                LabeledContent(
                    "CharacterRecognitionInferencePage.Inspector.DetectionMinimalConfidence",
                    value: values.detectionMinimalConfidence,
                    format: .number
                )
                Slider(value: $values.detectionMinimalConfidence, in: 0...1, step: 0.01)
                    .labelsHidden()
            }
            
            TextField(
                "CharacterRecognitionInferencePage.Inspector.DetectionMaximalResolution",
                value: $values.detectionMaximalResolution,
                format: .number
            )
            
            VStack {
                LabeledContent(
                    "CharacterRecognitionInferencePage.Inspector.RecognitionMinimalConfidence",
                    value: values.recognitionMinimalConfidence,
                    format: .number
                )
                Slider(value: $values.recognitionMinimalConfidence, in: 0...1, step: 0.01)
                    .labelsHidden()
            }
        }
    }
}

fileprivate extension CharacterRecognitionInferencePage {
    typealias Pipeline = CharacterRecognitionInferencePipeline
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        if !images.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    "CharacterRecognitionInferencePage.Action.RunInference",
                    systemImage: "play",
                    role: .BackDeployed.confirm
                ) {
                    alert.whenTrying(runInference)
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
                Button(
                    "CharacterRecognitionInferencePage.Action.ClearOutputHistory",
                    systemImage: "trash",
                    role: .destructive
                ) {
                    outputs.removeAll()
                }
            }
        }
    }
    
    func runInference() async throws {
        guard self.executionProgress == nil else {
            return
        }
        
        self.executionProgress = .init()
        defer {
            self.executionProgress = nil
        }
        
        let images = self.images
        let detectionModel = self.detectionModel
        let detectionMinimalConfidence = Float(values.detectionMinimalConfidence)
        let detectionMaximalResolution = values.detectionMaximalResolution
        let recognitionModel = self.recognitionModel
        let recognitionMinimalConfidence = Float(values.recognitionMinimalConfidence)
        
        struct TaskResult : Sendable {
            let offset: Int
            let input: Image
            let inputSize: CGSize
            let elapse: Duration
            let characterBoxes: [ PresentableCharacterBox ]
        }
        
        let results = try await withThrowingTaskGroup { @Sendable group in
            for enumeration in images.enumerated() {
                guard let image = CIImage(data: enumeration.element.data) else {
                    throw AlertAction.Message("Unable to decode the image.")
                }
                
                group.addTask {
                    let input = Pipeline.Input(
                        detectionModel: detectionModel,
                        detectionMinimalConfidence: detectionMinimalConfidence,
                        detectionMaximalResolution: detectionMaximalResolution,
                        recognitionModel: recognitionModel,
                        recognitionMinimalConfidence: recognitionMinimalConfidence,
                        image: image
                    )
                    
                    let clock = ContinuousClock()
                    let startTime = clock.now
                    
                    let output = try await service.run(Pipeline.self, input: input)
                    
                    let elapse = clock.now - startTime
                    
                    return TaskResult(
                        offset: enumeration.offset,
                        input: enumeration.element.image,
                        inputSize: image.extent.size,
                        elapse: elapse,
                        characterBoxes: output.characterBoxes.map { .init(data: $0) }
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
                    inputSize: $0.inputSize,
                    elapse: $0.elapse,
                    characterBoxes: $0.characterBoxes
                )
            }
        )
    }
}

fileprivate extension CharacterRecognitionInferencePage {
    struct Output : Sendable, Identifiable {
        let id = UUID()
        
        let index: Int
        
        let input: Image
        let inputSize: CGSize
        
        let elapse: Duration
        let characterBoxes: [ PresentableCharacterBox ]
    }
    
    struct PresentableCharacterBox : Identifiable, Sendable {
        let id = UUID()
        
        let data: Pipeline.Output.CharacterBox
    }
    
    @ViewBuilder
    func section(output: Output) -> some View {
        Section {
            OutputView(output: output)
        } header: {
            HStack(spacing: 12) {
                Label(
                    output.index,
                    format: .number.precision(.integerLength(2)),
                    systemImage: "number"
                )
                
                Spacer()
                
                Text(output.elapse, format: .elapse)
                Divider()
                Text(
                    """
                    CharacterRecognitionInferencePage.Output.BoxCount \
                    \(output.characterBoxes.count)
                    """
                )
            }
            .monospaced()
        }
    }
}

fileprivate extension CharacterRecognitionInferencePage {
    struct OutputView : View {
        @State private var hovering: UUID? = nil
        
        private let output: Output
        
        init(output: Output) {
            self.output = output
        }
        
        var body: some View {
            output.input
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    GeometryReader { proxy in
                        ForEach(output.characterBoxes) { characterBox in
                            CharacterBoxRectangle(
                                characterBox: characterBox,
                                hovering: $hovering
                            )
                        }
                        .environment(
                            \.scale,
                             proxy.size.width / output.inputSize.width
                        )
                    }
                }
        }
    }
    
    struct CharacterBoxRectangle : View {
        @Binding var hovering: UUID?
        
        @Environment(\.scale) private var scale
        
        private let characterBox: PresentableCharacterBox
        private let boundingBox: CGRect
        private let rotationAngle: Angle
        
        init(
            characterBox: PresentableCharacterBox,
            hovering: Binding<UUID?>
        ) {
            self._hovering = hovering
            
            self.characterBox = characterBox
            self.boundingBox = characterBox.data.rectangle.item.boundingBox
            self.rotationAngle = .init(radians: characterBox.data.rectangle.item.rotation)
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(frameColor, lineWidth: 4)
                    .onHover {
                        if $0 {
                            hovering = characterBox.id
                        } else if hovering == characterBox.id {
                            hovering = nil
                        }
                    }
                    .frame(
                        width: characterBox.data.rectangle.item.width * scale,
                        height: characterBox.data.rectangle.item.height * scale
                    )
                    .rotationEffect(rotationAngle, anchor: .center)
                
                Text(characterBox.data.text.item)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        .background.opacity(0.8),
                        in: .rect(cornerRadius: 6)
                    )
                    .safeAreaInset(edge: .bottom, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(
                                """
                                CharacterRecognitionInferencePage.Output.RectangleConfidence \
                                \(characterBox.data.rectangle.confidence, format: .confidence)
                                """
                            )
                            Text(
                                """
                                CharacterRecognitionInferencePage.Output.TextConfidence \
                                \(characterBox.data.text.confidence, format: .confidence)
                                """
                            )
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(frameColor, in: .rect(cornerRadius: 6))
                    }
                    .opacity(hovering == characterBox.id ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .opacity(opacity)
            .zIndex(zIndex)
            .position(
                x: boundingBox.centerX * scale,
                y: boundingBox.centerY * scale
            )
        }
        
        private var opacity: CGFloat {
            switch hovering {
            case characterBox.id: 1.0
            case nil: 0.6
            default: 0.3
            }
        }
        
        private var frameColor: Color {
            if let hovering, hovering != characterBox.id {
                .gray
            } else {
                .green
            }
        }
        
        private var zIndex: Double {
            switch hovering {
            case characterBox.id: 10
            default: 0
            }
        }
    }
}

fileprivate extension EnvironmentValues {
    @Entry var scale: CGFloat = 1.0
}

fileprivate extension CGRect {
    var centerX: CGFloat {
        self.origin.x + (self.width / 2)
    }
    
    var centerY: CGFloat {
        self.origin.y + (self.height / 2)
    }
}

