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
            SceneView()
                .alertable()
                .applying {
                    if #available(macOS 26, *) {
                        $0.windowResizeAnchor(.leading)
                    } else {
                        $0
                    }
                }
        }
    }
}

extension MainScene {
    static let id: String = "Scene.Main"
}

fileprivate struct SceneView : View {
    @Environment(\.openWindow) private var openWindow
    
    @SceneStorage("MainScene.Page") private var page = ModelsPage.identifier
    
    @State private var cache = InferenceService.default.cache
    @State private var values = ViewValues()
    @State private var webService = WebService.shared
    
    var body: some View {
        Group {
            if #available(macOS 15, *) {
                navigation
            } else {
                legacyNavigation
            }
        }
        .onAppear(perform: checkOnboarding)
    }
    
    @available(macOS 15, *)
    @ViewBuilder
    var navigation: some View {
        TabView(selection: $page) {
            Tab(ModelsPage.self, value: ModelsPage.identifier) {
                ModelsPage()
            }
            .badge(cache.sessions.count)
            
            TabSection("MainScene.Services") {
                Tab(
                    WebServicePage.titleKey,
                    systemImage: WebServicePage.systemImage(
                        isServiceErrorsEmpty: webService.errors.isEmpty
                    ),
                    value: WebServicePage.identifier
                ) {
                    WebServicePage()
                }
                .badge(webService.clientMetrics.count)
                
                Tab(InferenceServicePage.self, value: InferenceServicePage.identifier) {
                    InferenceServicePage()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
    
    @ViewBuilder
    var legacyNavigation: some View {
        NavigationSplitView {
            List(selection: $page) {
                Label(ModelsPage.self)
                    .badge(cache.sessions.count)
                    .tag(ModelsPage.identifier)
                
                Section("MainScene.Services") {
                    Label(
                        WebServicePage.titleKey,
                        systemImage: WebServicePage.systemImage(
                            isServiceErrorsEmpty: webService.errors.isEmpty
                        )
                    )
                    .badge(webService.clientMetrics.count)
                    .tag(WebServicePage.identifier)
                    
                    Label(InferenceServicePage.self)
                        .tag(InferenceServicePage.identifier)
                }
            }
        } detail: {
            switch page {
            case ModelsPage.identifier:
                ModelsPage()
            case WebServicePage.identifier:
                WebServicePage()
            case InferenceServicePage.identifier:
                InferenceServicePage()
            default:
                Text("MainScene.NoSelection")
                    .font(.system(.title, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

fileprivate extension SceneView {
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

fileprivate extension SceneView {
    func checkOnboarding() {
        let version = OnboardingScene.version
        if values.onboardingVersion != version {
            openWindow(id: OnboardingScene.windowId)
            values.onboardingVersion = version
        }
    }
}
