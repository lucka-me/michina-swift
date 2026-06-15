//
//  OnboardingIntroductionView.swift
//  Michina
//
//  Created by Lucka on 2026-06-13.
//

import SwiftUI

struct OnboardingIntroductionView : View {
    var body: some View {
        ScrollView(.vertical) {
            Grid(horizontalSpacing: 18, verticalSpacing: 24) {
                Image(AppIcon.current.preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(radius: 16)
                    .frame(maxWidth: .infinity, maxHeight: 96)
                
                if
                    let shortVersionString = Bundle.main.shortVersionString,
                    let version = Bundle.main.version
                {
                    Text("Version \(shortVersionString) \(version)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                ForEach(Message.all, content: \.self)
            }
        }
        .contentMargins(24, for: .scrollContent)
        .scrollIndicators(.never)
    }
}

fileprivate struct Message : @MainActor Identifiable, View {
    let titleKey: LocalizedStringKey
    let contentKey: LocalizedStringKey
    let systemImage: String
    let tint: Color
    
    var id: String {
        systemImage
    }
    
    var body: some View {
        GridRow {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 48, alignment: .center)
                .foregroundStyle(tint.gradient)
            
            VStack(alignment: .leading) {
                Text(titleKey)
                    .font(.headline)
                Text(contentKey)
                    .foregroundStyle(.secondary)
            }
            .gridColumnAlignment(.leading)
        }
    }
}

fileprivate extension Message {
    @ArrayBuilder<Self>
    static var all: [ Self ] {
        Message(
            titleKey: "OnboardingIntroductionView.Message.Swift",
            contentKey: "OnboardingIntroductionView.Message.Swift.Content",
            systemImage: "swift",
            tint: .orange
        )
        Message(
            titleKey: "OnboardingIntroductionView.Message.UI",
            contentKey: "OnboardingIntroductionView.Message.UI.Content",
            systemImage: "macwindow",
            tint: .accentColor
        )
        Message(
            titleKey: "OnboardingIntroductionView.Message.TestModels",
            contentKey: "OnboardingIntroductionView.Message.TestModels.Content",
            systemImage: "play.diamond",
            tint: .green
        )
    }
}
