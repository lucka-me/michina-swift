//
//  OnboardingScene.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

struct OnboardingScene : Scene {
    var body: some Scene {
        Window(Self.titleKey, id: Self.windowId) {
            NavigationStack {
                OnboardingFlow.introduction
                    .navigationDestination(for: OnboardingFlow.self) { workflow in
                        workflow
                    }
            }
            .frame(minWidth: 400, minHeight: 500)
            .alertable()
        }
        .windowIdealSize(.fitToContent)
    }
}

extension OnboardingScene {
    static let windowId = "Scene.Onboarding"
    static let titleKey: LocalizedStringKey = "OnboardingScene"
    
    static var version: String? { "0" }
}
