//
//  InferenceModelSuite.Category+Representing.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import Magearna
import SwiftUI

extension InferenceModelSuite.Category : Labelable {
    var titleKey: LocalizedStringKey {
        switch self {
        case .facialRecognition: "Facial Recognition"
        case .search: "Smart Search"
        case .characterRecognition: "OCR"
        }
    }
    
    var systemImage: String {
        switch self {
        case .facialRecognition: "person.crop.rectangle"
        case .search: "sparkle.magnifyingglass"
        case .characterRecognition: "text.viewfinder"
        }
    }
}
