//
//  PipelineCountChart.swift
//  Michina
//
//  Created by Lucka on 2026-06-08.
//

import Charts
import SwiftUI

struct PipelineCountChart : View {
    private let counts: [ InferenceServiceMetrics.InstantCount ]
    
    private let style: Style
    
    init(
        counts: [ InferenceServiceMetrics.InstantCount ],
        style: Style = .regular
    ) {
        self.counts = counts
        self.style = style
    }
    
    var body: some View {
        Chart {
            ForEach(counts, id: \.instant) { item in
                LineMark(
                    x: .value("Instant", item.instant),
                    y: .value("Pipelines", item.count)
                )
                .foregroundStyle(Color.accentColor)
                
                AreaMark(
                    x: .value("Instant", item.instant),
                    y: .value("Pipelines", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ .accentColor.opacity(0.8), .accentColor.opacity(0.1) ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .interpolationMethod(.stepStart)
            
            if style == .regular {
                RuleMark(
                    y: .value("Processors", ProcessInfo.processInfo.processorCount)
                )
                .foregroundStyle(.gray.opacity(0.6))
                .lineStyle(.init(dash: [ 4, 2 ]))
                .annotation(position: .bottom, alignment: .leading) {
                    Text("Processors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(
                preset: .aligned,
                position: .bottom,
                values: .stride(by: .second, count: 1)
            ) {
                if style == .regular {
                    AxisTick(centered: true, length: 8)
                }
            }
        }
        .chartYScale(domain: 0 ... chartYScaleUpperBound)
        .chartYAxis {
            AxisMarks(values: .stride(by: 5)) {
                if style == .regular {
                    AxisValueLabel(format: Decimal.FormatStyle())
                    AxisGridLine()
                }
            }
        }
    }
}

extension PipelineCountChart {
    enum Style {
        case compact
        case regular
    }
}

fileprivate extension PipelineCountChart {
    var chartYScaleUpperBound: Int {
        let max = counts.max(by: { $0.count < $1.count })?.count ?? 5
        return (max / 5 + 1) * 5
    }
}
