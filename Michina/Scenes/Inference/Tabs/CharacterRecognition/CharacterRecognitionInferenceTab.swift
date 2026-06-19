//
//  CharacterRecognitionInferenceTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import Magearna
import SwiftUI

struct CharacterRecognitionInferenceTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var values = ViewValues()
    
    @State private var isInspectorPresented = true
    
    @State private var detectionModel: InferenceModel
    @State private var recognitionModel: InferenceModel
    
    @State private var imageData: ImageData? = nil
    
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
    
    var body: some TabContent<InferenceModelSuite.Category> {
        Tab(
            Self.category.titleKey,
            systemImage: Self.category.systemImage,
            value: Self.category
        ) {
            List {
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
                    modelsSection
                    inputSections
                }
                .formStyle(.grouped)
            }
        }
    }
}

extension CharacterRecognitionInferenceTab {
    static let category = InferenceModelSuite.Category.characterRecognition
}

fileprivate extension CharacterRecognitionInferenceTab {
    static let detectionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.detection] }
    static let recognitionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.recognition] }
}

fileprivate extension CharacterRecognitionInferenceTab {
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
        Section("CharacterRecognitionInferenceTab.Inspector.Models") {
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
        Section("CharacterRecognitionInferenceTab.Inspector.Photo") {
            if let image = imageData?.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            UnifiedPhotoPicker(selection: $imageData)
        }
        
        Section("CharacterRecognitionInferenceTab.Inspector.Parameters") {
            VStack {
                LabeledContent(
                    "CharacterRecognitionInferenceTab.Inspector.DetectionMinimalConfidence",
                    value: values.detectionMinimalConfidence,
                    format: .number
                )
                Slider(value: $values.detectionMinimalConfidence, in: 0...1, step: 0.01)
                    .labelsHidden()
            }
            
            TextField(
                "CharacterRecognitionInferenceTab.Inspector.DetectionMaximalResolution",
                value: $values.detectionMaximalResolution,
                format: .number
            )
            
            VStack {
                LabeledContent(
                    "CharacterRecognitionInferenceTab.Inspector.RecognitionMinimalConfidence",
                    value: values.recognitionMinimalConfidence,
                    format: .number
                )
                Slider(value: $values.recognitionMinimalConfidence, in: 0...1, step: 0.01)
                    .labelsHidden()
            }
        }
    }
}

fileprivate extension CharacterRecognitionInferenceTab {
    typealias Pipeline = CharacterRecognitionInferencePipeline
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if imageData != nil {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    "CharacterRecognitionInferenceTab.Action.RunInference",
                    systemImage: "play",
                    role: .confirm
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
                    "CharacterRecognitionInferenceTab.Action.ClearOutputHistory",
                    systemImage: "trash",
                    role: .destructive
                ) {
                    outputs.removeAll()
                }
            }
        }
    }
    
    func runInference() async throws {
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
        
        let input = Pipeline.Input(
            detectionModel: detectionModel,
            detectionMinimalConfidence: .init(values.detectionMinimalConfidence),
            detectionMaximalResolution: values.detectionMaximalResolution,
            recognitionModel: recognitionModel,
            recognitionMinimalConfidence: .init(values.recognitionMinimalConfidence),
            image: image
        )
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        let output = try await service.run(Pipeline.self, input: input)
        
        let elapse = clock.now - startTime
        
        self.outputs.append(
            .init(
                index: self.outputs.count,
                input: imageData.image,
                inputSize: image.extent.size,
                elapse: elapse,
                boxes: output.characterBoxes.map { .init(data: $0) }
            )
        )
    }
}

fileprivate extension CharacterRecognitionInferenceTab {
    struct Output : Sendable, Identifiable {
        let id = UUID()
        
        let index: Int
        
        let input: Image
        let inputSize: CGSize
        
        let elapse: Duration
        let boxes: [ PresentableCharacterBox ]
    }
    
    struct PresentableCharacterBox : Identifiable, Sendable {
        let id = UUID()
        
        let data: Pipeline.Output.CharacterBox
    }
    
    @ViewBuilder
    func section(for output: Output) -> some View {
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
                Text("CharacterRecognitionInferenceTab.Output.BoxCount \(output.boxes.count)")
            }
            .monospaced()
        }
    }
}

fileprivate extension CharacterRecognitionInferenceTab {
    struct OutputView : View {
        @State private var hovering: UUID? = nil
        
        private let output: Output
        
        init(output: Output) {
            self.output = output
        }
        
        var body: some View {
            output.input
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    GeometryReader { proxy in
                        let scale = proxy.size.width / output.inputSize.width
                        ForEach(output.boxes) { box in
                            CharacterBoxQuadrilateral(
                                box: box,
                                scale: scale,
                                hovering: $hovering
                            )
                        }
                    }
                }
        }
    }
    
    struct CharacterBoxQuadrilateral : View {
        @Binding var hovering: UUID?
        
        @State var captionHeight = CGFloat.zero
        
        private let box: PresentableCharacterBox
        private let scale: CGFloat
        
        init(
            box: PresentableCharacterBox,
            scale: CGFloat,
            hovering: Binding<UUID?>
        ) {
            self._hovering = hovering
            
            self.box = box
            self.scale = scale
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 6)
                .rotation(box.data.shape.item.rotationAngle, anchor: .center)
                .stroke(frameColor, lineWidth: 4)
                .frame(
                    width: box.data.shape.item.boundingBox.width * scale,
                    height: box.data.shape.item.boundingBox.height * scale
                )
                .opacity(opacity)
                .contentShape(
                    .rect(cornerRadius: 6)
                    .rotation(box.data.shape.item.rotationAngle, anchor: .center)
                )
                .onHover {
                    if $0 {
                        hovering = box.id
                    } else if hovering == box.id {
                        hovering = nil
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 4) {
                    VStack(spacing: 4) {
                        Text(box.data.text.item)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                .background.opacity(0.8),
                                in: .rect(cornerRadius: 6)
                            )
                        
                        HStack(spacing: 8) {
                            Text("CharacterRecognitionInferenceTab.Output.ShapeConfidence \(box.data.shape.confidence, format: .percent.precision(.fractionLength(2)))")
                            Text("CharacterRecognitionInferenceTab.Output.TextConfidence \(box.data.text.confidence, format: .percent.precision(.fractionLength(2)))")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(frameColor, in: .rect(cornerRadius: 6))
                    }
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) {
                        captionHeight = $0
                    }
                    .opacity(hovering == box.id ? 1 : 0)
                }
                .zIndex(zIndex)
                .position(position)
        }
        
        private var position: CGPoint {
            let boundingBox = box.data.shape.item.boundingBox
            return .init(
                x: boundingBox.centerX * scale,
                y: boundingBox.centerY * scale + 2 + (captionHeight / 2)
            )
        }
        
        private var opacity: CGFloat {
            switch hovering {
            case box.id: 1.0
            case nil: 0.6
            default: 0.3
            }
        }
        
        private var frameColor: Color {
            if let hovering, hovering != box.id {
                .gray
            } else {
                .green
            }
        }
        
        private var zIndex: Double {
            switch hovering {
            case box.id: 10
            default: 0
            }
        }
    }
}

fileprivate extension CGRect {
    var centerX: CGFloat {
        self.origin.x + (self.width / 2)
    }
    
    var centerY: CGFloat {
        self.origin.y + (self.height / 2)
    }
}

fileprivate extension Quadrilateral {
    var rotationAngle: Angle {
        let dx = self.topLeft.x - self.bottomLeft.x
        let dy = self.topLeft.y - self.bottomLeft.y
        
        return if dx.isZero {
            .zero
        } else if dy.isZero {
            .degrees(90)
        } else {
            .radians(atan2(dy, dx))
        }
    }
}
