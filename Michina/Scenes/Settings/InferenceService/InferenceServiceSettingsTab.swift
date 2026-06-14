//
//  InferenceServiceSettingsTab.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import SwiftUI
import ONNXRuntime

struct InferenceServiceSettingsTab : TabContent {
    @State var settings = InferenceServiceSettings.shared
    
    var body: some TabContent<Never> {
        Tab(Self.titleKey, systemImage: Self.systemImage) {
            Form {
                sessionSections
                onnxRuntimeSection
            }
            .frame(minWidth: 300, maxWidth: 400)
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    static let titleKey: LocalizedStringKey = "Inference Service"
    static let systemImage: String = "rectangle.stack"
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var sessionSections: some View {
        @Bindable var settings = settings.session
        
        Section {
            Toggle("Prefer Core ML", isOn: $settings.preferCoreML)
            if settings.preferCoreML {
                Toggle(
                    "Run Inefficient Models with CPU",
                    isOn: $settings.preferEfficiency
                )
            }
        } header: {
            Text("Execution Providers")
        } footer: {
            Text("Some models will cause error when running with Core ML, they will always run with CPU.")
        }
        
        Section {
            Toggle("Save Model Optimization Data on Disk", isOn: $settings.persistOptimizations)
        } header: {
            Text("Optimization")
        } footer: {
            Text("These files may help reduce elapse of loading and execution, they will be generated during the first load and saved to \".optimizations\" hidden folder alongside the model file.")
            Text("Please notice that, however, these files are usually very large, especially with Core ML.")
        }
        
        Section {
            TextField(
                "Unload After",
                value: $settings.timeToLive,
                format: .number.grouping(.never),
                prompt: Text("Seconds")
            )
        } header: {
            Text("In-Memory Cache")
        } footer: {
            Text("The model will be unloaded after a period of idle to reduce memory usage.")
        }
    }
}

fileprivate extension InferenceServiceSettingsTab {
    @ViewBuilder
    var onnxRuntimeSection: some View {
        Section("ONNX Runtime") {
            LabeledContent("Supports CoreML Provider") {
                if ORTIsCoreMLExecutionProviderAvailable() {
                    Text("Yes")
                        .foregroundStyle(.green)
                } else {
                    Text("No")
                        .foregroundStyle(.red)
                }
            }
            LabeledContent("Version", value: ORTVersion() ?? "Unknown")
        }
    }
}
