//
//  InferenceModelSuite.Provider.ImmichAppEndpoint+LabelableMetatype.swift
//  Michina
//
//  Created by Lucka on 2026-08-13.
//

import Magearna
import SwiftUI

extension InferenceModelSuite.Provider.ImmichAppEndpoint : LabelableMetatype {
    static var titleKey: LocalizedStringKey {
        "InferenceModelSuite.Provider.ImmichAppEndpoint"
    }
    
    static var systemImage: String {
        "face.smiling"
    }
}
