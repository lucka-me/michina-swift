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
                    Text("\(shortVersionString) (\(version))")
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
            titleKey: "Built with Swift",
            contentKey: "Native, at full speed. With acceleration like Core ML and vImage, available only on Apple platforms.",
            systemImage: "swift",
            tint: .orange
        )
        Message(
            titleKey: "Full UI",
            contentKey: "No command line or Docker stuff. Check status and statistics at real-time. Also available in menu bar icon.",
            systemImage: "macwindow",
            tint: .accentColor
        )
        Message(
            titleKey: "Test Models",
            contentKey: "Select a model, tap *Run a Inference* to check if it runs properly and gives results as you expected.",
            systemImage: "play.diamond",
            tint: .green
        )
    }
}
