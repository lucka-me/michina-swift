//
//  VisualSearchInferencePipeline.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import ONNXRuntime

// Actually implement OpenClipVisualEncoder

public actor VisualSearchInferencePipeline : InferencePipeline {
    public static let category = InferenceModelSuite.Category.search
    
    public private(set) var modelReports: [InferencePipelineModelReport] = [ ]
    
    private let input: Input
    
    private var session: InferenceSession? = nil
    private var sidecar: VisualSearchSidecar? = nil
    
    private var output: Output = [ ]
    
    public init(_ input: Input) {
        self.input = input
    }
    
    public var models: [ InferenceModel ] {
        [ input.model ]
    }
    
    public func prepare(_ sessions: [ InferenceModel.Category : InferenceSession ]) throws {
        guard let session = sessions[.visual] else {
            fatalError(
                "Unable to extract visual model required by VisualSearchInferencePipeline."
            )
        }
        
        self.session = session
        guard case let .visualSearch(sidecar) = session.sidecar else {
            fatalError("The session doesn't contain VisualSearchInferencePipeline.Configurations.")
        }
        self.sidecar = sidecar
        
        output.removeAll()
    }
    
    public func run() throws -> Output {
        guard let session, let sidecar else {
            fatalError("VisualSearchInferencePipeline.prepared() was not called.")
        }
        
        let elapse = try ContinuousClock().measure {
            let processedImage = try sidecar
                .process(image: input.image)
            let data = try processedImage
                .decodeForONNX(
                    mean: sidecar.decodeMean,
                    scale: sidecar.decodeScale
                )
            let inputShape = sidecar.inputShape
            precondition(
                data.count == inputShape.map(\.intValue).reduce(1, *) * MemoryLayout<Float>.size,
                "The length of input data doesn't match the input shape, check the processing."
            )
            
            let inputValue = try ORTValue(
                tensorData: .init(data: data),
                elementType: .float,
                shape: inputShape
            )
            let outputs = try session.session.run(
                withInputs: [ session.inputNames[0] : inputValue ],
                outputNames: .init(session.outputNames),
                runOptions: nil
            )
            
            self.output = try outputs[session.outputNames[0]]!.array()
        }
        modelReports.append(.init(model: input.model, elapse: elapse))
        
        return self.output
    }
}

public extension VisualSearchInferencePipeline {
    typealias Output = [ Float ]
    
    struct Input : Sendable {
        let model: InferenceModel
        
        public let image: CIImage
        
        public init(model: InferenceModel, image: CIImage) {
            self.model = model
            self.image = image
        }
    }
}

fileprivate extension VisualSearchInferencePipeline {
    enum StaticConfigurations {
        static let batchSize: NSNumber = 1
        static let channelCount: NSNumber = 3
    }
}

fileprivate extension VisualSearchSidecar {
    var inputShape: [ NSNumber ] {
        [
            VisualSearchInferencePipeline.StaticConfigurations.batchSize,
            VisualSearchInferencePipeline.StaticConfigurations.channelCount,
            inputSize.height as NSNumber,
            inputSize.width as NSNumber,
        ]
    }
    
    func process(image: CIImage) throws -> CGImage {
        // immich resizes to *fill* the inputSize and *crop* the center part
        // However it should follow resize_mode in the cfg file...?
        let imageSize = image.extent.size
        let scale: CGFloat
        let aspectRatio: CGFloat
        switch resizeMode {
        case .squash:
            scale = inputSize.height / imageSize.height
            aspectRatio = (inputSize.width / imageSize.width) / scale
        }
        
        let scaledImage: CIImage?
        switch interpolation {
        case .bicubic:
            let scaleFilter = CIFilter.bicubicScaleTransform()
            scaleFilter.inputImage = image
            scaleFilter.scale = .init(scale)
            scaleFilter.aspectRatio = .init(aspectRatio)
            scaledImage = scaleFilter.outputImage
        case .lanczos:
            let scaleFilter = CIFilter.lanczosScaleTransform()
            scaleFilter.inputImage = image
            scaleFilter.scale = .init(scale)
            scaleFilter.aspectRatio = .init(aspectRatio)
            scaledImage = scaleFilter.outputImage
        }
        // TODO: Figure out how to generate a correct size
        // The scale and aspectRatio is not 100% precise, the size of scaledImage may not match
        // inputSize
        guard let scaledImage else {
            throw .runtime("Unable to resize the image")
        }
        guard
            let cgImage = CIContext.pipelineShared.createCGImage(
                scaledImage.composited(over: .black),
                from: .init(
                    // Core Graphics: Origin at Lower-Left
                    // vImage and other: Origin at Upper-Left
                    // So we need to move the origin down to keep the CGImage filled from top row
                    // Both x grows right
                    origin: .init(
                        x: scaledImage.extent.origin.x,
                        y: scaledImage.extent.origin.y
                            - (inputSize.height - scaledImage.extent.height)
                    ),
                    size: inputSize
                )
            )
        else {
            throw .runtime("Unable to create CGImage")
        }
        return cgImage
    }
}

fileprivate struct RuntimeError : Error {
    let reason: String
    
    var localizedDescription: String {
        reason
    }
}

fileprivate extension Error where Self == RuntimeError {
    static func runtime(_ reason: String) -> RuntimeError {
        .init(reason: reason)
    }
}
