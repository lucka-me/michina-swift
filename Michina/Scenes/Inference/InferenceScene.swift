//
//  InferenceScene.swift
//  Michina
//
//  Created by Lucka on 2026-05-29.
//

import Magearna
import SwiftUI

struct InferenceScene : Scene {
    var body: some Scene {
        WindowGroup(Self.titleKey, for: Request.self) { $request in
            SceneView(request: request)
                .alertable()
                .presentedWindowToolbarStyle(.expanded)
        }
    }
}

extension InferenceScene {
    static let titleKey: LocalizedStringKey = "InferenceScene"
    
    struct Request : Codable, Hashable {
        let category: InferenceModelSuite.Category
        let suiteName: String
    }
}

fileprivate struct SceneView : View {
    @State private var category: InferenceModelSuite.Category
    
    private let suiteName: String?
    
    init(request: InferenceScene.Request?) {
        self._category = .init(initialValue: request?.category ?? .facialRecognition)
        self.suiteName = request?.suiteName
    }
    
    var body: some View {
        if #available(macOS 15, *) {
            navigation
        } else {
            legacyNavigation
        }
    }
    
    @available(macOS 15, *)
    @ViewBuilder
    var navigation: some View {
        TabView(selection: $category) {
            Tab(label: FacialRecognitionInferencePage.category) {
                FacialRecognitionInferencePage(suiteName: suiteName)
            }
            
            Tab(label: SearchInferencePage.category) {
                SearchInferencePage(suiteName: suiteName)
            }
            
            Tab(label: CharacterRecognitionInferencePage.category) {
                CharacterRecognitionInferencePage(suiteName: suiteName)
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
    
    @ViewBuilder
    var legacyNavigation: some View {
        TabView(selection: $category) {
            FacialRecognitionInferencePage(suiteName: suiteName)
                .tabItem {
                    Label(FacialRecognitionInferencePage.category)
                }
                .tag(FacialRecognitionInferencePage.category)
            
            SearchInferencePage(suiteName: suiteName)
                .tabItem {
                    Label(SearchInferencePage.category)
                }
                .tag(SearchInferencePage.category)
            
            CharacterRecognitionInferencePage(suiteName: suiteName)
                .tabItem {
                    Label(CharacterRecognitionInferencePage.category)
                }
                .tag(CharacterRecognitionInferencePage.category)
        }
    }
}
