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
            LabeledContent(
                "ClientMetricView.Glance.Address",
                value: client.address ?? .init(localized: "ClientMetricView.Glance.Address.Nil")
            )
            
            LabeledContent("ClientMetricView.Glance.Creation") {
                Text(client.creation, style: .timer)
            }
            
            LabeledContent("ClientMetricView.Glance.RecentPing") {
                if let recentPing = client.recentPing {
                    Text(recentPing, style: .timer)
                } else {
                    Text("ClientMetricView.Glance.RecentPing.Nil")
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
                "ClientMetricView.PredictRequest.Count",
                value: metric.count,
                format: .number
            )
            LabeledContent(
                "ClientMetricView.PredictRequest.ContentLength",
                value: metric.contentLength,
                format: .byteCount(style: .file)
            )
        } header: {
            if let category {
                Label(category)
            } else {
                Label("ClientMetricView.PredictRequest.Total", systemImage: "rectangle.stack")
            }
        }
    }
}
