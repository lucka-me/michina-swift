//
//  InferenceSession.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

@preconcurrency import ONNXRuntime
import ONNXRuntimeExtensions

public final class InferenceSession : Sendable {
    public let model: InferenceModel
    
    public let inputNames: [ String ]
    public let outputNames: [ String ]
    
    public let session: ORTSession
    
    let sidecar: Sidecar?
    
    public init(
        _ model: InferenceModel,
        in cacheDirectory: URL,
        options: Options
    ) throws {
        self.model = model
        
        let sessionOptions = try ORTSessionOptions()
        try sessionOptions.setGraphOptimizationLevel(.all)
        try sessionOptions.registerCustomOps(
            functionPointer: OrtExt.getRegisterCustomOpsFunctionPointer()
        )
        
        try sessionOptions.addConfigEntry(
            withKey: "session.enable_cpu_mem_arena",
            value: "1"
        )
        
        let executionProvider: ExecutionProvider
        switch options.executionProviderPreference {
        case .coreML:
            executionProvider = switch model.compatibility {
            case .compatible, .inefficient: .coreML
            case .incompatible: .cpu
            }
        case .efficientCoreML:
            executionProvider = switch model.compatibility {
            case .compatible: .coreML
            case .inefficient, .incompatible: .cpu
            }
        case .alwaysCPU:
            executionProvider = .cpu
        }
        
        switch executionProvider {
        case .coreML:
            // https://onnxruntime.ai/docs/api/objectivec/Classes/ORTSessionOptions.html
            var executionProviderOptions = [
                "ModelFormat" : "MLProgram",
                "MLComputeUnits" : "ALL",
                "EnableOnSubgraphs": "1",
                "SpecializationStrategy" : "FastPrediction",
                "AllowLowPrecisionAccumulationOnGPU": "1",
            ]
            
            if options.persistOptimizations {
                let optimizationsURL = model.directoryURL(in: cacheDirectory).appending(
                    components: ".optimizations", "CoreML"
                )
                try FileManager.default.createDirectory(
                    at: optimizationsURL,
                    withIntermediateDirectories: true
                )
                executionProviderOptions["ModelCacheDirectory"] = optimizationsURL.path(
                    percentEncoded: false
                )
            }
            
            try sessionOptions.appendCoreMLExecutionProvider(
                withOptionsV2: executionProviderOptions
            )
        case .cpu:
            // https://github.com/immich-app/immich/blob/main/machine-learning/immich_ml/sessions/ort.py
            try sessionOptions.addConfigEntry(
                withKey: "session.inter_op_num_threads",
                value: "2"
            )
            try sessionOptions.setIntraOpNumThreads(2)
            try sessionOptions.addConfigEntry(
                withKey: "session.execution_mode",
                value: "ort_parallel"
            )
            
            if options.persistOptimizations {
                let optimizationsURL = model.directoryURL(in: cacheDirectory).appending(
                    components: ".optimizations", "CPU", "optimized"
                )
                try FileManager.default.createDirectory(
                    at: optimizationsURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try sessionOptions.setOptimizedModelFilePath(
                    optimizationsURL.path(percentEncoded: false)
                )
            }
        }
        
        // Random (?) error:
        // Trying to add a domain to DomainToVersion map, but the domain is already exist with
        // version range (1, 1000). domain: "ai.onnx.contrib"
        self.session = try ORTSession(
            env: .shared,
            modelPath: model.modelFileURL(in: cacheDirectory).path(percentEncoded: false),
            sessionOptions: sessionOptions
        )
        
        self.inputNames = try session.inputNames()
        self.outputNames = try session.outputNames()
        
        self.sidecar = switch model.suiteCategory {
        case .facialRecognition:
            switch model.category {
            case .detection: .retinaFace(
                .init(outputNamesCount: self.outputNames.count)
            )
            case .recognition: .arcFace(
                try .init(
                    model: model,
                    cacheDirectory: cacheDirectory,
                    isCoreMLExecutionProviderEnabled: executionProvider == .coreML
                )
            )
            default: fatalError("Unsupported sidecar: \(model.id)")
            }
        case .search:
            switch model.category {
            case .visual: .visualSearch(
                try .init(model: model, cacheDirectory: cacheDirectory)
            )
            case .textual: .textualSearch(
                try .init(model: model, cacheDirectory: cacheDirectory)
            )
            default: fatalError("Unsupported sidecar: \(model.id)")
            }
        case .characterRecognition:
            switch model.category {
            case .recognition: .rapidCharacterRecognition(
                try .init(model: model, cacheDirectory: cacheDirectory)
            )
            default: nil
            }
        }
    }
}

fileprivate enum ExecutionProvider {
    case coreML
    case cpu
}
