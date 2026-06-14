//
//  InferencePipeline.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

public protocol InferencePipeline : Actor {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    
    static var category: InferenceModelSuite.Category { get }
    
    init(_ input: Input)
    
    var models: [ InferenceModel ] { get }
    var modelReports: [ InferencePipelineModelReport ] { get }
    
    func prepare(_ sessions: [ InferenceModel.Category : InferenceSession ]) throws
    func run() async throws -> Output
}
