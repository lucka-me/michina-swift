//
//  InferenceSession+Sidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

extension InferenceSession {
    enum Sidecar : Sendable {
        case retinaFace(RetinaFaceSidecar)
        case arcFace(ArcFaceSidecar)
        
        case visualSearch(VisualSearchSidecar)
        case textualSearch(TextualSearchSidecar)
        
        case rapidCharacterRecognition(RapidCharacterRecognitionSidecar)
    }
}
