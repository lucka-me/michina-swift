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
        
        let optimizationVersioning: OptimizationVersioning?
        switch options.executionProvider {
        case .coreML(let format):
            let modelFormat = switch format {
            case .mlProgram: "MLProgram"
            case .neuralNetwork: "NeuralNetwork"
            }
            // https://onnxruntime.ai/docs/api/objectivec/Classes/ORTSessionOptions.html
            var executionProviderOptions = [
                "ModelFormat" :  modelFormat,
                "MLComputeUnits" : "ALL",
                "EnableOnSubgraphs" : "1",
                "SpecializationStrategy" : "FastPrediction",
                "AllowLowPrecisionAccumulationOnGPU" : "1",
            ]
            
            if options.persistOptimizations {
                let versioning = OptimizationVersioning(
                    model: model,
                    cacheDirectory: cacheDirectory,
                    executionProvider: .coreML
                )
                if try versioning.checkOutdated() {
                    try FileManager.default.createDirectory(
                        at: versioning.directory,
                        withIntermediateDirectories: true
                    )
                    optimizationVersioning = versioning
                } else {
                    optimizationVersioning = nil
                }
                
                executionProviderOptions["ModelCacheDirectory"] = versioning.directory.path(
                    percentEncoded: false
                )
            } else {
                optimizationVersioning = nil
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
                let versioning = OptimizationVersioning(
                    model: model,
                    cacheDirectory: cacheDirectory,
                    executionProvider: .cpu
                )
                try FileManager.default.createDirectory(
                    at: versioning.directory,
                    withIntermediateDirectories: true
                )
                try sessionOptions.setOptimizedModelFilePath(
                    versioning.directory
                        .appending(component: "optimized")
                        .path(percentEncoded: false)
                )
            }
            
            optimizationVersioning = nil
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
        
        try optimizationVersioning?.markUpToDate()
        
        self.inputNames = try session.inputNames()
        self.outputNames = try session.outputNames()
        
        self.sidecar = try .create(
            model: model,
            cacheDirectory: cacheDirectory,
            outputNamesCount: self.outputNames.count,
            isCoreMLExecutionProviderEnabled: options.executionProvider.isCoreML
        )
    }
}

fileprivate struct OptimizationVersioning {
    enum ExecutionProvider : String {
        case coreML = "CoreML"
        case cpu = "CPU"
    }
    
    private struct Versions : Codable {
        var onnxRuntime: String?
    }
    
    let directory: URL
    
    private let versionsFile: URL
    
    init(
        model: InferenceModel,
        cacheDirectory: URL,
        executionProvider: ExecutionProvider
    ) {
        self.directory = model
            .directoryURL(in: cacheDirectory)
            .appending(components: ".optimizations", executionProvider.rawValue)
        self.versionsFile = directory
            .appending(component: "versions")
            .appendingPathExtension("json")
    }
    
    func checkOutdated() throws -> Bool {
        guard FileManager.default.fileExists(at: directory) else {
            return true
        }
        
        guard
            FileManager.default.fileExists(at: versionsFile),
            let versions = try? JSONDecoder()
                .decode(Versions.self, from: .init(contentsOf: versionsFile)),
            versions.onnxRuntime == ORTVersion()
        else {
            try FileManager.default.removeItem(at: directory)
            return true
        }
        
        return false
    }
    
    func markUpToDate() throws {
        try JSONEncoder()
            .encode(Versions(onnxRuntime: ORTVersion()))
            .write(to: versionsFile)
    }
}

fileprivate extension InferenceSession.Options.ExecutionProvider {
    var isCoreML : Bool {
        switch self {
        case .coreML: true
        case .cpu: false
        }
    }
}
