//
//  FacialRecognitionInferenceTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import Magearna
import SwiftUI

struct FacialRecognitionInferenceTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var values = ViewValues()
    
    @State private var detectionModel: InferenceModel
    @State private var recognitionModel: InferenceModel
    @State private var imageData: ImageData? = nil
    
    @State private var executionProgress: Progress? = nil
    
    @State private var outputs: [ Output ] = [ ]
    @State private var selection: PresentableFace? = nil
    
    @State private var isInspectorPresented = true
    
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
                ForEach(outputs, content: section(output:))
            }
            .environment(
                \.similarityMinimalDistance,
                 .init(values.similarityMinimalDistance)
            )
            .listStyle(.inset)
            .frame(minWidth: 300)
            .toolbar(content: toolbarContent)
            .inspector(isPresented: $isInspectorPresented) {
                Form {
                    modelsSection
                    inputSections
                    outputSection
                }
                .formStyle(.grouped)
            }
        }
    }
}

extension FacialRecognitionInferenceTab {
    static let category = InferenceModelSuite.Category.facialRecognition
}

fileprivate extension FacialRecognitionInferenceTab {
    static let detectionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.detection] }
    static let recognitionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.recognition] }
}

fileprivate extension FacialRecognitionInferenceTab {
    @MainActor
    @Observable
    final class ViewValues {
        private struct Storage {
            @AppStorage("FacialRecognitionInferenceTab.DetectionMinimalConfidence")
            var detectionMinimalConfidence = 0.5
            
            @AppStorage("FacialRecognitionInferenceTab.SimilarityMinimalDistance")
            var similarityMinimalDistance = 0.5
        }
        
        var detectionMinimalConfidence: Double {
            didSet { storage.detectionMinimalConfidence = detectionMinimalConfidence }
        }
        
        var similarityMinimalDistance: Double {
            didSet { storage.similarityMinimalDistance = similarityMinimalDistance }
        }
        
        private let storage = Storage()
        
        init() {
            self.detectionMinimalConfidence = storage.detectionMinimalConfidence
            self.similarityMinimalDistance = storage.similarityMinimalDistance
        }
    }
    
    @ViewBuilder
    var modelsSection: some View {
        Section("FacialRecognitionInferenceTab.Inspector.Models") {
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
        Section("FacialRecognitionInferenceTab.Inspector.Input.Photo") {
            if let image = imageData?.image {
                image
                    .aspectRatio(contentMode: .fit)
            }
            
            UnifiedPhotoPicker(selection: $imageData)
        }
        
        Section("FacialRecognitionInferenceTab.Inspector.Input.Parameters") {
            VStack {
                LabeledContent(
                    "FacialRecognitionInferenceTab.Inspector.Input.Parameters.DetectionMinimalConfidence",
                    value: values.detectionMinimalConfidence,
                    format: .number
                )
                Slider(value: $values.detectionMinimalConfidence, in: 0...1, step: 0.01)
                    .labelsHidden()
            }
        }
    }
    
    @ViewBuilder
    var outputSection: some View {
        Section {
            VStack {
                LabeledContent(
                    "FacialRecognitionInferenceTab.Inspector.Output.SimilarityMinimalDistance",
                    value: values.similarityMinimalDistance,
                    format: .number
                )
                Slider(value: $values.similarityMinimalDistance, in: 0...2, step: 0.05)
                    .labelsHidden()
            }
        } header: {
            Text("FacialRecognitionInferenceTab.Inspector.Output")
        } footer: {
            Text("FacialRecognitionInferenceTab.Inspector.Output.Footer")
        }
    }
}

fileprivate extension FacialRecognitionInferenceTab {
    typealias Pipeline = FacialRecognitionInferencePipeline
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        if imageData != nil {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    "FacialRecognitionInferenceTab.Action.RunInference",
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
                    "FacialRecognitionInferenceTab.Action.ClearOutputHistory",
                    systemImage: "trash",
                    role: .destructive
                ) {
                    selection = nil
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
        let recognitionModel = self.recognitionModel
        
        let input = Pipeline.Input(
            detectionModel: detectionModel,
            detectionMinimalConfidence: .init(values.detectionMinimalConfidence),
            recognitionModel: recognitionModel,
            image: image
        )
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        let output = try await service.run(Pipeline.self, input: input)
        
        let elapse = clock.now - startTime
        
        self.outputs.append(
            .init(
                index: self.outputs.count,
                inputImage: imageData.image,
                inputImageSize: image.extent.size,
                recognitionModel: recognitionModel,
                elapse: elapse,
                faces: output.faces.enumerated().map { (index, face) in
                    return .init(
                        index: index,
                        recognitionModel: recognitionModel,
                        data: face
                    )
                }
            )
        )
    }
}

fileprivate extension FacialRecognitionInferenceTab {
    struct Output : Sendable, Identifiable {
        let id = UUID()
        let index: Int
        
        let inputImage: Image
        let inputImageSize: CGSize
        let recognitionModel: InferenceModel
        
        let elapse: Duration
        let faces: [ PresentableFace ]
    }
    
    struct PresentableFace : Identifiable, Sendable {
        let id = UUID()
        let index: Int
        
        let recognitionModel: InferenceModel
        
        let data: Pipeline.Output.Face
    }
    
    @ViewBuilder
    func section(output: Output) -> some View {
        Section {
            OutputView(output: output, selection: $selection)
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
                Text("FacialRecognitionInferenceTab.Output.FaceCount \(output.faces.count)")
            }
            .monospaced()
        }
    }
}

fileprivate extension FacialRecognitionInferenceTab {
    struct OutputView : View {
        @Binding private var selection: PresentableFace?
        
        @State private var hovering: UUID? = nil
        
        private let output: Output
        
        init(output: Output, selection: Binding<PresentableFace?>) {
            self._selection = selection
            self.output = output
        }
        
        var body: some View {
            output.inputImage
                .scaledToFit()
                .onTapGesture {
                    selection = nil
                }
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    GeometryReader { proxy in
                        let scale = proxy.size.width / output.inputImageSize.width
                        ForEach(output.faces) { face in
                            FaceRect(
                                face: face,
                                scale: scale,
                                hovering: $hovering,
                                selection: $selection
                            )
                        }
                    }
                }
        }
    }
    
    struct FaceRect : View {
        @Binding var hovering: UUID?
        @Binding var selection: PresentableFace?
        
        @Environment(\.similarityMinimalDistance)
        private var similarityMinimalDistance
        
        @State var captionHeight = CGFloat.zero
        
        private let face: PresentableFace
        private let scale: CGFloat
        
        init(
            face: PresentableFace,
            scale: CGFloat,
            hovering: Binding<UUID?>,
            selection: Binding<PresentableFace?>
        ) {
            self._hovering = hovering
            self._selection = selection
            
            self.face = face
            self.scale = scale
        }
        
        var body: some View {
            if hovering == face.id {
                ForEach(
                    face.data.geometry.item.landmarks.enumerated(),
                    id:\.offset
                ) { landmark in
                    Circle()
                        .stroke(frameColor, lineWidth: 2)
                        .frame(width: 4, height: 4)
                        .opacity(opacity)
                        .zIndex(zIndex)
                        .position(
                            x: landmark.element.x * scale,
                            y: landmark.element.y * scale
                        )
                }
            }
            
            RoundedRectangle(cornerRadius: 6)
                .stroke(frameColor, lineWidth: 2)
                .frame(
                    width: face.data.geometry.item.boundingBox.width * scale,
                    height: face.data.geometry.item.boundingBox.height * scale
                )
                .contentShape(.rect(cornerRadius: 6))
                .onHover {
                    if $0 {
                        hovering = face.id
                    } else if hovering == face.id {
                        hovering = nil
                    }
                }
                .onTapGesture {
                    selection = face
                }
                .safeAreaInset(edge: .bottom, spacing: 4) {
                    VStackLayout(spacing: 2) {
                        Text(face.data.geometry.confidence, format: .confidence)
                        if let distance {
                            Text(distance, format: .number.precision(.fractionLength(4)))
                        }
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) {
                        captionHeight = $0
                    }
                    .background(frameColor, in: .rect(cornerRadius: 6))
                }
                .opacity(opacity)
                .zIndex(zIndex)
                .position(
                    x: face.data.geometry.item.boundingBox.centerX * scale,
                    y: face.data.geometry.item.boundingBox.centerY * scale + 2 + (captionHeight / 2)
                )
        }
        
        private var opacity: CGFloat {
            switch hovering {
            case face.id: 1.0
            case nil: 0.6
            default: 0.3
            }
        }
        
        private var frameColor: Color {
            if let selection {
                if selection.id == face.id {
                    .teal
                } else if let distance {
                    if distance <= similarityMinimalDistance {
                        .green
                    } else {
                        .red
                    }
                } else {
                    // Different models
                    .gray
                }
            } else if let hovering, hovering != face.id {
                .gray
            } else {
                .blue
            }
        }
        
        private var distance: Float? {
            guard
                let selection,
                selection.recognitionModel == face.recognitionModel,
                selection.id != face.id
            else {
                return nil
            }
            return face.distance(to: selection)
        }
        
        private var zIndex: Double {
            switch hovering {
            case face.id: 10
            default: 0
            }
        }
    }
}

fileprivate extension FacialRecognitionInferenceTab.PresentableFace {
    func distance(to other: Self) -> Float {
        let (dot, normSelf, normOther) = zip(self.data.embedding, other.data.embedding)
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

fileprivate extension EnvironmentValues {
    @Entry var similarityMinimalDistance: Float = 5.0
}

fileprivate extension CGRect {
    var centerX: CGFloat {
        self.origin.x + (self.width / 2)
    }
    
    var centerY: CGFloat {
        self.origin.y + (self.height / 2)
    }
}
