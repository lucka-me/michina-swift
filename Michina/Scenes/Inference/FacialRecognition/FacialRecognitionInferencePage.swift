//
//  FacialRecognitionInferencePage.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import Magearna
import SwiftUI

struct FacialRecognitionInferencePage : View {
    @Environment(\.alert) private var alert
    
    @State private var values = ViewValues()
    
    @State private var detectionModel: InferenceModel
    @State private var recognitionModel: InferenceModel
    @State private var images: [ ImageData ] = [ ]
    
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
    
    var body: some View {
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

extension FacialRecognitionInferencePage {
    static let category = InferenceModelSuite.Category.facialRecognition
}

fileprivate extension FacialRecognitionInferencePage {
    static let detectionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.detection] }
    static let recognitionModels = InferenceModelSuite.all[category]!
        .compactMap { $0.models[.recognition] }
}

fileprivate extension FacialRecognitionInferencePage {
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
        Section("FacialRecognitionInferencePage.Inspector.Models") {
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
        Section("FacialRecognitionInferencePage.Inspector.Input.Photo") {
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
        
        Section("FacialRecognitionInferencePage.Inspector.Input.Parameters") {
            VStack {
                LabeledContent(
                    "FacialRecognitionInferencePage.Inspector.Input.Parameters.DetectionMinimalConfidence",
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
                    "FacialRecognitionInferencePage.Inspector.Output.SimilarityMinimalDistance",
                    value: values.similarityMinimalDistance,
                    format: .number
                )
                Slider(value: $values.similarityMinimalDistance, in: 0...2, step: 0.05)
                    .labelsHidden()
            }
        } header: {
            Text("FacialRecognitionInferencePage.Inspector.Output")
        } footer: {
            Text("FacialRecognitionInferencePage.Inspector.Output.Footer")
        }
    }
}

fileprivate extension FacialRecognitionInferencePage {
    typealias Pipeline = FacialRecognitionInferencePipeline
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        if !images.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    "FacialRecognitionInferencePage.Action.RunInference",
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
                    "FacialRecognitionInferencePage.Action.ClearOutputHistory",
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
        let recognitionModel = self.recognitionModel
        
        struct TaskResult : Sendable {
            let offset: Int
            let inputImage: Image
            let inputImageSize: CGSize
            let elapse: Duration
            let faces: [ PresentableFace ]
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
                        recognitionModel: recognitionModel,
                        image: image
                    )
                    
                    let clock = ContinuousClock()
                    let startTime = clock.now
                    
                    let output = try await service.run(Pipeline.self, input: input)
                    
                    let elapse = clock.now - startTime
                    
                    return TaskResult(
                        offset: enumeration.offset,
                        inputImage: enumeration.element.image,
                        inputImageSize: image.extent.size,
                        elapse: elapse,
                        faces: output.faces.enumerated().map { (index, face) in
                            return .init(
                                index: index,
                                recognitionModel: recognitionModel,
                                data: face,
                                landmarks: face.geometry.item.landmarks.map {
                                    .init(data: $0)
                                }
                            )
                        }
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
                    inputImage: $0.inputImage,
                    inputImageSize: $0.inputImageSize,
                    recognitionModel: recognitionModel,
                    elapse: $0.elapse,
                    faces: $0.faces
                )
            }
        )
    }
}

fileprivate extension FacialRecognitionInferencePage {
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
        
        let landmarks: [ PresentableLandmark ]
    }
    
    struct PresentableLandmark: Identifiable, Sendable {
        let id = UUID()
        
        let data: CGPoint
    }
    
    @ViewBuilder
    func section(output: Output) -> some View {
        Section {
            OutputView(output: output, selection: $selection)
                .listRowSeparator(.hidden)
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
                Text("FacialRecognitionInferencePage.Output.FaceCount \(output.faces.count)")
            }
            .monospaced()
        }
    }
}

fileprivate extension FacialRecognitionInferencePage {
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
                        ForEach(output.faces) { face in
                            FaceRect(
                                face: face,
                                hovering: $hovering,
                                selection: $selection
                            )
                        }
                        .environment(
                            \.scale,
                             proxy.size.width / output.inputImageSize.width
                        )
                    }
                }
        }
    }
    
    struct FaceRect : View {
        @Binding var hovering: UUID?
        @Binding var selection: PresentableFace?
        
        @Environment(\.scale) private var scale
        
        @Environment(\.similarityMinimalDistance)
        private var similarityMinimalDistance
        
        @State var captionHeight = CGFloat.zero
        
        private let face: PresentableFace
        
        init(
            face: PresentableFace,
            hovering: Binding<UUID?>,
            selection: Binding<PresentableFace?>
        ) {
            self._hovering = hovering
            self._selection = selection
            
            self.face = face
        }
        
        var body: some View {
            if hovering == face.id {
                ForEach(face.landmarks) { landmark in
                    Circle()
                        .stroke(frameColor, lineWidth: 2)
                        .frame(width: 4, height: 4)
                        .opacity(opacity)
                        .zIndex(zIndex)
                        .position(
                            x: landmark.data.x * scale,
                            y: landmark.data.y * scale
                        )
                }
            }
            
            RoundedRectangle(cornerRadius: 6)
                .stroke(frameColor, lineWidth: 2)
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
                .frame(
                    width: face.data.geometry.item.boundingBox.width * scale,
                    height: face.data.geometry.item.boundingBox.height * scale
                )
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

fileprivate extension FacialRecognitionInferencePage.PresentableFace {
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
    @Entry var scale: CGFloat = 1.0
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
