//
//  WebClientMetric.swift
//  Michina
//
//  Created by Lucka on 2026-05-24.
//

import Foundation
import Magearna

@Observable
final class WebClientMetric {
    let creation: Date
    
    let address: String?
    
    private(set) var recentPing: Date? = nil
    
    private(set) var predictRequests: [ InferenceModelSuite.Category? : PredictRequestMetric ] = [
        nil: .init(),
        .facialRecognition: .init(),
        .search: .init(),
        .characterRecognition: .init(),
    ]
    
    fileprivate init(creation: Date, address: String?) {
        self.creation = creation
        self.address = address
    }
}

extension WebClientMetric : Identifiable {
    var id: String? {
        address
    }
}

extension WebClientMetric : Hashable {
    static func == (lhs: WebClientMetric, rhs: WebClientMetric) -> Bool {
        lhs.creation == rhs.creation && lhs.address == rhs.address
    }
    
    func hash(into hasher: inout Hasher) {
        creation.hash(into: &hasher)
        address?.hash(into: &hasher)
    }
}

extension WebClientMetric {
    struct PredictRequestMetric {
        var count: Int = 0
        var contentLength: Int64 = 0
        
        mutating func record(contentLength: Int64) {
            self.count += 1
            self.contentLength += contentLength
        }
    }
}

extension WebClientMetric {
    struct Report : Sendable {
        let address: String?
        let date: Date = .now
        
        fileprivate let content: Content
        
        private init(address: String?, content: Content) {
            self.address = address
            self.content = content
        }
    }
    
    static func record(report: Report) -> WebClientMetric {
        let metric = WebClientMetric(creation: report.date, address: report.address)
        metric.record(report: report)
        return metric
    }
    
    func record(report: Report) {
        switch report.content {
        case .ping:
            recordPing(at: report.date)
        case .predict(let category, let contentLength):
            recordPredict(in: category, contentLength: contentLength)
        }
    }
}

extension WebClientMetric.Report {
    static func ping(
        from address: String?
    ) -> Self {
        .init(address: address, content: .ping)
    }
    
    static func predict(
        from address: String?,
        in category: InferenceModelSuite.Category,
        contentLength: Int64
    ) -> Self {
        .init(
            address: address,
            content: .predict(category: category, contentLength: contentLength)
        )
    }
}

fileprivate extension WebClientMetric {
    func recordPing(at date: Date) {
        self.recentPing = date
    }
    
    func recordPredict(in category: InferenceModelSuite.Category, contentLength: Int64) {
        predictRequests[nil]!.record(contentLength: contentLength)
        predictRequests[category]!.record(contentLength: contentLength)
    }
}

fileprivate extension WebClientMetric.Report {
    enum Content : Sendable {
        case ping
        
        case predict(category: InferenceModelSuite.Category, contentLength: Int64)
    }
}
