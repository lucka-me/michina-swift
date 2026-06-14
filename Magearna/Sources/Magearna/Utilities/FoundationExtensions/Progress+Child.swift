//
//  Progress+Child.swift
//  Magearna
//
//  Created by Lucka on 2026-05-20.
//

import Foundation

extension Progress {
    func addChild(for unitCount: Int64, as pendingUnitCount: Int64) -> Progress {
        let child = Progress(totalUnitCount: unitCount)
        self.addChild(child, withPendingUnitCount: pendingUnitCount)
        return child
    }
    
    func addChild(as pendingUnitCount: Int64) -> Progress {
        let child = Progress()
        self.addChild(child, withPendingUnitCount: pendingUnitCount)
        return child
    }
}
