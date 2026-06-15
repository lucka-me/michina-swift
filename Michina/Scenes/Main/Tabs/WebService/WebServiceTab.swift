//
//  WebServiceTab.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import SwiftUI

struct WebServiceTab : TabContent {
    @Environment(\.alert) private var alert
    
    @State private var service = WebService.shared
    
    @State private var isErrorsPopoverPresented = false
    
    @State private var isInspectorPresented = true
    @State private var selection: Selection? = nil
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: systemImage) {
            List(selection: $selection) {
                clientsSection
            }
            .listStyle(.inset)
            .frame(minWidth: 200, minHeight: 400)
            .toolbar {
                toolbarContent
            }
            .navigationTitle("WebService")
            .navigationSubtitle(navigationSubtitleKey)
            .inspector(isPresented: $isInspectorPresented) {
                if
                    case let .client(address) = selection,
                    let client = service.clientMetrics.first(where: { $0.address == address })
                {
                    ClientMetricView(client: client)
                } else {
                    Text("WebServiceTab.NoSelection")
                        .font(.system(.title, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: selection) {
                if selection != nil {
                    isInspectorPresented = true
                }
            }
        }
        .badge(service.clientMetrics.count)
    }
}

fileprivate extension WebServiceTab {
    static let titleKey: LocalizedStringKey = "WebServiceTab"
}

fileprivate extension WebServiceTab {
    var systemImage: String {
        if service.errors.isEmpty {
            "network"
        } else {
            "exclamationmark.triangle"
        }
    }
}

fileprivate extension WebServiceTab {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Toggle(
                "WebServiceTab.ServiceToggle",
                systemImage: "power",
                isOn: .init(
                    get: { service.status.isRunning },
                    set: { alert.whenTrying($0 ? service.start : service.stop) }
                )
            )
        }
        
        if !service.errors.isEmpty {
            ToolbarItem(placement: .status) {
                Button("WebServiceTab.Errors", systemImage: "exclamationmark.triangle") {
                    isErrorsPopoverPresented = true
                }
                .badge(service.errors.count)
                .popover(
                    isPresented: $isErrorsPopoverPresented,
                    attachmentAnchor: .rect(.bounds),
                    arrowEdge: .bottom
                ) {
                    errorsPopoverContent
                }
            }
        }
    }
    
    @ViewBuilder
    var errorsPopoverContent: some View {
        ScrollView(.vertical) {
            Grid(alignment: .leading) {
                ForEach(service.errors) { error in
                    GridRow(alignment: .firstTextBaseline) {
                        Text(error.date, format: .dateTime.hour().minute(.twoDigits).second(.twoDigits))
                        Text(error.description)
                    }
                }
            }
        }
        .monospaced()
        .contentMargins(.horizontal, 12, for: .scrollContent)
        .contentMargins(.vertical, 8, for: .scrollContent)
        .safeAreaBar(edge: .bottom, alignment: .trailing) {
            Button("WebServiceTab.Errors.Clear", role: .destructive) {
                service.clearErrors()
                isErrorsPopoverPresented = false
            }
            .keyboardShortcut(.delete)
            .padding([ .horizontal, .bottom ], 12)
        }
        .frame(maxHeight: 400)
    }
}

fileprivate extension WebServiceTab {
    @ViewBuilder
    var clientsSection: some View {
        Section {
            ForEach(service.clientMetrics, content: clientItem(_:))
                .monospaced()
        } header: {
            Label("WebServiceTab.Clients", systemImage: "server.rack")
        }
    }
    
    @ViewBuilder
    func clientItem(_ client: WebClientMetric) -> some View {
        VStack(alignment: .leading) {
            Text(client.address ?? .init(localized: "WebServiceTab.Clients.Unknown"))
                .font(.headline)
            
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                let metric = client.predictRequests[nil]!
                Text("WebServiceTab.Clients.PredictRequests \(metric.count)")
                Text(metric.contentLength, format: .byteCount(style: .file))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .tag(Selection.client(address: client.address))
    }
}

fileprivate extension WebServiceTab {
    var navigationSubtitleKey: LocalizedStringKey {
        switch service.status {
        case .paused: "WebServiceTab.Subtitle.Paused"
        case .running(let port): "WebServiceTab.Subtitle.Running \(port, format: .port)"
        }
    }
}

fileprivate enum Selection: Hashable {
    case client(address: String?)
}
