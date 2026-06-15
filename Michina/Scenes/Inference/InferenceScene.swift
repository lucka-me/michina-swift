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
            InferenceView(request: request)
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

fileprivate struct InferenceView : View {
    @State private var category: InferenceModelSuite.Category
    
    private let suiteName: String?
    
    init(request: InferenceScene.Request?) {
        self._category = .init(initialValue: request?.category ?? .facialRecognition)
        self.suiteName = request?.suiteName
    }
    
    var body: some View {
        TabView(selection: $category) {
            FacialRecognitionInferenceTab(suiteName: suiteName)
            SearchInferenceTab(suiteName: suiteName)
            CharacterRecognitionInferenceTab(suiteName: suiteName)
        }
        .tabViewStyle(.tabBarOnly)
    }
}
