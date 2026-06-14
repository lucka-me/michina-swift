//
//  ClientMetricView.swift
//  Michina
//
//  Created by Lucka on 2026-05-24.
//

import Magearna
import SwiftUI

struct ClientMetricView : View {
    private let client: WebClientMetric
    
    init(client: WebClientMetric) {
        self.client = client
    }
    
    var body: some View {
        Form {
            glanceSection
            
            predictRequestsSections
        }
        .formStyle(.grouped)
    }
}

fileprivate extension ClientMetricView {
    @ViewBuilder
    var glanceSection: some View {
        Section {
            LabeledContent("Address", value: client.address ?? "Unknown")
            
            LabeledContent("First Request") {
                Text(client.creation, style: .timer)
            }
            
            LabeledContent("Recent Ping") {
                if let recentPing = client.recentPing {
                    Text(recentPing, style: .timer)
                } else {
                    Text("No Pings")
                }
            }
        }
    }
}

fileprivate extension ClientMetricView {
    @ViewBuilder
    var predictRequestsSections: some View {
        predictRequestsSection(nil, metric: client.predictRequests[nil]!)
        ForEach(InferenceModelSuite.Category.allCases) { category in
            predictRequestsSection(category, metric: client.predictRequests[category]!)
        }
    }
    
    @ViewBuilder
    func predictRequestsSection(
        _ category: InferenceModelSuite.Category?,
        metric: WebClientMetric.PredictRequestMetric
    ) -> some View {
        Section {
            LabeledContent(
                "Requests",
                value: metric.count,
                format: .number
            )
            LabeledContent(
                "Data Received",
                value: metric.contentLength,
                format: .byteCount(style: .file)
            )
        } header: {
            if let category {
                Label(category)
            } else {
                Label("Total", systemImage: "rectangle.stack")
            }
        }
    }
}
