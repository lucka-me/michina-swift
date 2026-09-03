//
//  WebServicePage.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import SwiftUI

struct WebServicePage : View {
    @Environment(\.alert) private var alert
    
    @State private var service = WebService.shared
    
    @State private var isErrorsPopoverPresented = false
    
    @State private var isInspectorPresented = true
    @State private var selection: Selection? = nil
    
    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(service.clientMetrics, content: row(client:))
                    .monospaced()
            } header: {
                Label("WebServicePage.Clients", systemImage: "server.rack")
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.inset)
        .frame(minWidth: 200, minHeight: 400)
        .toolbar(content: toolbarContent)
        .navigationTitle("WebService")
        .navigationSubtitle(navigationSubtitleKey)
        .inspector(isPresented: $isInspectorPresented, content: inspectorContent)
        .onChange(of: selection) {
            if selection != nil {
                isInspectorPresented = true
            }
        }
    }
}

extension WebServicePage {
    static let identifier = "WebServicePage"
    
    static let titleKey: LocalizedStringKey = "WebServicePage"
    
    static func systemImage(isServiceErrorsEmpty: Bool) -> String {
        if isServiceErrorsEmpty {
            "network"
        } else {
            "exclamationmark.triangle"
        }
    }
}

fileprivate extension WebServicePage {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Toggle(
                "WebServicePage.ServiceToggle",
                systemImage: "power",
                isOn: .init(
                    get: { service.status.isRunning },
                    set: { alert.whenTrying($0 ? service.start : service.stop) }
                )
            )
        }
        
        if !service.errors.isEmpty {
            ToolbarItem(placement: .status) {
                Button("WebServicePage.Errors", systemImage: "exclamationmark.triangle") {
                    isErrorsPopoverPresented = true
                }
                .badge(service.errors.count)
                .popover(
                    isPresented: $isErrorsPopoverPresented,
                    attachmentAnchor: .rect(.bounds),
                    arrowEdge: .bottom,
                    content: errorsPopoverContent
                )
            }
        }
    }
    
    @ViewBuilder
    func errorsPopoverContent() -> some View {
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
        .applying {
            if #available(macOS 26, *) {
                $0.safeAreaBar(edge: .bottom, alignment: .trailing) {
                    clearErrorsButton
                }
            } else {
                $0.safeAreaInset(edge: .bottom, alignment: .trailing) {
                    clearErrorsButton
                        .safeAreaInset(edge: .top, spacing: 0) {
                            Divider()
                        }
                        .background(.bar, ignoresSafeAreaEdges: .all)
                }
            }
        }
        .frame(maxHeight: 400)
    }
    
    @ViewBuilder
    var clearErrorsButton: some View {
        Button("WebServicePage.Errors.Clear", role: .destructive) {
            service.clearErrors()
            isErrorsPopoverPresented = false
        }
        .keyboardShortcut(.delete)
        .padding([ .horizontal, .bottom ], 12)
    }
}

fileprivate extension WebServicePage {
    @ViewBuilder
    func inspectorContent() -> some View {
        if
            case let .client(address) = selection,
            let client = service.clientMetrics.first(where: { $0.address == address })
        {
            ClientMetricView(client: client)
        } else {
            Text("WebServicePage.NoSelection")
                .font(.system(.title, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

fileprivate extension WebServicePage {
    @ViewBuilder
    func row(client: WebClientMetric) -> some View {
        VStack(alignment: .leading) {
            Text(client.address ?? .init(localized: "WebServicePage.Clients.Unknown"))
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

fileprivate extension WebServicePage {
    var navigationSubtitleKey: LocalizedStringKey {
        switch service.status {
        case .paused: "WebServicePage.Subtitle.Paused"
        case .running(let port): "WebServicePage.Subtitle.Running \(port, format: .port)"
        }
    }
}

fileprivate enum Selection: Hashable {
    case client(address: String?)
}
