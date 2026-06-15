//
//  MainScene.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import SwiftUI

struct MainScene : Scene {
    var body: some Scene {
        WindowGroup(id: Self.id) {
            MainView()
                .alertable()
                .windowResizeAnchor(.leading)
        }
    }
}

extension MainScene {
    static let id: String = "Scene.Main"
}

fileprivate struct MainView : View {
    @Environment(\.openWindow) private var openWindow
    
    @State private var values = ViewValues()
    
    var body: some View {
        TabView {
            ModelsTab()
            
            TabSection("MainScene.Services") {
                WebServiceTab()
                
                InferenceServiceTab()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onAppear(perform: checkOnboarding)
    }
}

fileprivate extension MainView {
    @MainActor
    @Observable
    final class ViewValues {
        private struct Storage {
            @AppStorage("MainView.OnboardingVersion")
            var onboardingVersion: String?
        }
        
        var onboardingVersion: String? {
            didSet { storage.onboardingVersion = onboardingVersion }
        }
        
        private let storage = Storage()
        
        init() {
            self.onboardingVersion = storage.onboardingVersion
        }
    }
}

fileprivate extension MainView {
    func checkOnboarding() {
        let version = OnboardingScene.version
        if values.onboardingVersion != version {
            openWindow(id: OnboardingScene.windowId)
            values.onboardingVersion = version
        }
    }
}
