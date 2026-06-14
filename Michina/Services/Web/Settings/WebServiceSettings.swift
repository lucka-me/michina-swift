//
//  WebServiceSettings.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class WebServiceSettings {
    var port: Int {
        didSet { storage.port = port }
    }
    
    var startWhenInitialized: Bool {
        didSet { storage.startWhenInitialized = startWhenInitialized }
    }
    
    private let storage = Storage()
    
    private init() {
        self.port = storage.port
        self.startWhenInitialized = storage.startWhenInitialized
    }
}

extension WebServiceSettings {
    static let shared = WebServiceSettings()
}

fileprivate extension WebServiceSettings {
    struct Storage {
        @AppStorage("WebService.Port") var port = 3003
        @AppStorage("WebService.StartWhenInitialized") var startWhenInitialized = false
    }
}
