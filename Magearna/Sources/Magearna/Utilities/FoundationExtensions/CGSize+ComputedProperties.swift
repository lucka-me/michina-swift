//
//  CGSize+ComputedProperties.swift
//  Magearna
//
//  Created by Lucka on 2026-05-25.
//

import CoreFoundation

extension CGSize {
    var area: Double {
        width * height
    }
    
    var ratio: Double {
        width / height
    }
}
