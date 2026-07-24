//
//  View+Applying.swift
//  Michina
//
//  Created by Lucka on 2026-07-24.
//

import SwiftUI

extension View {
    @inline(always)
    func applying(@ViewBuilder modifications: (Self) -> some View) -> some View {
        modifications(self)
    }
}
