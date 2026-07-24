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
        .applying {
            if #available(macOS 26, *) {
                $0.safeAreaBar(edge: .bottom, alignment: .trailing) {
                    navigationButton
                        .buttonStyle(.glassProminent)
                }
            } else {
                $0.safeAreaInset(edge: .bottom, alignment: .trailing) {
                    navigationButton
                        .buttonStyle(.borderedProminent)
                        .safeAreaInset(edge: .top, spacing: 0) {
                            Divider()
                        }
                        .background(.bar, ignoresSafeAreaEdges: .all)
                }
            }
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
        case .introduction: "OnboardingFlow.Introduction"
        case .settings: "OnboardingFlow.Settings"
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

fileprivate extension OnboardingFlow {
    @ViewBuilder
    var navigationButton: some View {
        Group {
            if let next {
                NavigationLink(value: next)
            } else {
                Button("OnboardingFlow.Finish", systemImage: "checkmark") {
                    dismissWindow()
                }
            }
        }
        .controlSize(.large)
        .padding(24)
    }
}
