//
//  OnboardingFlow.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

struct OnboardingFlow : View {
    @Environment(\.dismissWindow) private var dismissWindow
    
    private let storage: Storage
    
    private init(storage: Storage) {
        self.storage = storage
    }
    
    var body: some View {
        Group {
            switch storage {
            case .introduction: OnboardingIntroductionView()
            case .settings: OnboardingSettingsView()
            }
        }
        .safeAreaBar(edge: .bottom, alignment: .trailing) {
            Group {
                if let next {
                    NavigationLink(value: next)
                } else {
                    Button("Finish", systemImage: "checkmark") {
                        dismissWindow()
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(24)
        }
        .navigationTitle(titleKey)
        .presentedWindowStyle(.titleBar)
        .presentedWindowToolbarStyle(.expanded)
    }
}

extension OnboardingFlow : @MainActor Hashable {
    static func == (lhs: OnboardingFlow, rhs: OnboardingFlow) -> Bool {
        lhs.storage == rhs.storage
    }
    
    func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }
}

extension OnboardingFlow : @MainActor Labelable {
    var titleKey: LocalizedStringKey {
        switch storage {
        case .introduction: "Welcome to Michina"
        case .settings: "Settings"
        }
    }
    
    var systemImage: String {
        switch storage {
        case .introduction: "hand.wave"
        case .settings: "gear"
        }
    }
}

extension OnboardingFlow {
    static var introduction: Self { .init(storage: .introduction) }
    static var settings: Self { .init(storage: .settings) }
}

fileprivate extension OnboardingFlow {
    enum Storage : Hashable {
        case introduction
        case settings
    }
    
    private var next: Self? {
        switch storage {
        case .introduction: .settings
        case .settings: nil
        }
    }
}
