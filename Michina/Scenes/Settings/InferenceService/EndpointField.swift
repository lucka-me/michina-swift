//
//  EndpointField.swift
//  Michina
//
//  Created by Lucka on 2026-08-11.
//

import Magearna
import SwiftUI

struct EndpointField<
    Endpoint: InferenceModelSuite.Provider.MirrorableEndpoint & LabelableMetatype
> : View {
    @Binding private var url: URL?
    
    @Environment(\.alert) private var alert
    
    @State private var inputText: String = ""
    @State private var inputValue: URL? = nil
    
    @State private var isApplied: Bool = false
    @State private var progress: Progress? = nil
    
    init(_ type: Endpoint.Type, url: Binding<URL?>) {
        self._url = url
    }
    
    init(url: Binding<URL?>) {
        self._url = url
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(Endpoint.titleKey)
                
                Spacer()
                
                Text(
                    """
                    EndpointField.Provider \
                    \(Text(Endpoint.provider.titleKey).italic())
                    """
                )
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            HStack {
                TextField(
                    "EndpointField.TextField",
                    text: $inputText,
                    prompt: Text(Endpoint.defaultBaseURL, format: Self.format)
                )
                .onSubmit {
                    alert.whenTrying(verify)
                }
                
                if let progress {
                    ProgressView(progress)
                } else if isApplied {
                    if url == nil {
                        Text("EndpointField.UseDefault")
                            .foregroundStyle(.green)
                    } else {
                        Text("EndpointField.Applied")
                            .foregroundStyle(.green)
                        
                        Button(
                            "EndpointField.Reset",
                            systemImage: "arrow.counterclockwise",
                            role: .destructive,
                            action: reset
                        )
                    }
                } else {
                    Button("EndpointField.Verify") {
                        alert.whenTrying(verify)
                    }
                    .disabled(inputValue == nil)
                }
            }
        }
        .disabled(progress != nil)
        .onChange(of: inputText, handleInputTextChanged)
        .onChange(of: url, initial: true, handleURLChanged)
    }
}

fileprivate extension EndpointField {
    static var format: URL.FormatStyle {
        .url
        .path(.omitWhen(.path, matches: [ "", "/" ]))
    }
}

fileprivate extension EndpointField {
    func handleURLChanged() {
        isApplied = true
        inputValue = url
        inputText = url?.formatted(Self.format) ?? ""
    }
    
    func handleInputTextChanged() {
        inputValue = try? Self.format.parseStrategy.parse(inputText)
        
        isApplied = if let inputValue, inputValue == url {
            true
        } else if url == nil, inputText.isEmpty {
            true
        } else {
            false
        }
    }
    
    func reset() {
        url = nil
    }
}
    
fileprivate extension EndpointField {
    func verify() async throws {
        guard let inputValue else {
            return
        }
        progress = .init()
        defer {
            progress = nil
        }
        let endpoint = Endpoint(baseURL: inputValue)
        guard try await endpoint.verify() else {
            isApplied = false
            return
        }
        
        self.url = inputValue
    }
}
