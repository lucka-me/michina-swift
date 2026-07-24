//
//  ButtonRole+BackDeployments.swift
//  Michina
//
//  Created by Lucka on 2026-07-24.
//

import SwiftUI

public extension ButtonRole {
    enum BackDeployed {
        static var confirm: ButtonRole? {
            if #available(macOS 26.0, *) {
                .confirm
            } else {
                nil
            }
        }
    }
}
