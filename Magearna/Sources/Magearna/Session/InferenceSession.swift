//
//  InferenceSession.swift
//  Magearna
//
//  Created by Lucka on 2026-06-10.
//

@preconcurrency import ONNXRuntime

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
        
        // Error: Trying to add a domain to DomainToVersion map, but the domain is already exist
        // with version range (1, 1000). domain: "ai.onnx.contrib"
        //
        // Occurs when load multiple models in parallel at first time after launch, likely caused
        // by sessionOptions.registerCustomOps(functionPointer:). The immich implementation
        // doesn't use onnxruntime_extension, so do we.
        self.session = try ORTSession(
            env: .shared,
            modelPath: model.modelFileURL(in: cacheDirectory).path(percentEncoded: false),
            sessionOptions: sessionOptions
        )
        
        self.inputNames = try session.inputNames()
        self.outputNames = try session.outputNames()
        
        self.sidecar = try .create(
            model: model,
            cacheDirectory: cacheDirectory,
            outputNamesCount: self.outputNames.count,
            isCoreMLExecutionProviderEnabled: executionProvider == .coreML
        )
    }
}

fileprivate enum ExecutionProvider {
    case coreML
    case cpu
}
