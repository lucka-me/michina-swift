//
//  UnifiedPhotoPicker.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import PhotosUI
import SwiftUI

struct UnifiedPhotoPicker<Label: View> : View {
    @Environment(\.alert) private var alert
    
    @Binding private var selection: [ ImageData ]

    @State private var photosPickerItems: [ PhotosPickerItem ] = [ ]
    @State private var loadImageProgress: Progress? = nil
    
    private let label: () -> Label
    
    init(
        selection: Binding<[ ImageData ]>,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._selection = selection
        self.label = label
    }
    
    var body: some View {
        ZStack {
            PhotosPicker(selection: $photosPickerItems, label: label)
                .onDrop(
                    of: [ .image ],
                    isTargeted: nil
                ) { items in
                    alert.whenTrying { @MainActor in
                        try await load(items: items)
                    }
                    return true
                }
                .onChange(of: photosPickerItems) {
                    alert.whenTrying { @MainActor in
                        try await load(items: photosPickerItems)
                    }
                }
                .disabled(loadImageProgress != nil)
                .opacity(loadImageProgress != nil ? 0 : 1)
            
            if let loadImageProgress {
                ProgressView(loadImageProgress)
                    .progressViewStyle(.circular)
            }
        }
    }
}

extension UnifiedPhotoPicker where Label == Text {
    init(_ titleKey: LocalizedStringKey, selection: Binding<[ ImageData ]>) {
        self.init(selection: selection) {
            Text(titleKey)
        }
    }
    
    init(selection: Binding<[ ImageData ]>) {
        self.init(selection: selection) {
            Text("UnifiedPhotoPicker.DefaultLabel")
        }
    }
}

fileprivate extension UnifiedPhotoPicker {
    func load<Item: LoadingTransferable>(items: [ Item ]) async throws {
        guard !items.isEmpty else {
            selection = [ ]
            return
        }
        
        let progress = Progress(totalUnitCount: .init(items.count))
        self.loadImageProgress = progress
        defer {
            self.loadImageProgress = nil
        }
        self.selection = try await withThrowingTaskGroup { @Sendable group in
            for enumeration in items.enumerated() {
                group.addTask {
                    let result = try await enumeration.element.loadTransferable(
                        type: ImageData.self
                    ) { childProgress in
                        progress.addChild(childProgress, withPendingUnitCount: 1)
                    }
                    return (enumeration.offset, result)
                }
            }
            
            return try await group
                .reduce(into: [ ]) { $0.append($1) }
                .sorted(using: KeyPathComparator(\.0))
                .compactMap(\.1)
        }
    }
}

fileprivate protocol LoadingTransferable : Sendable {
    func loadTransferable<T : Transferable>(
        type: T.Type,
        reportProgress: (Progress) -> Void
    ) async throws -> T?
}

extension PhotosPickerItem : LoadingTransferable {
    func loadTransferable<T : Transferable>(
        type: T.Type,
        reportProgress: (Progress) -> Void
    ) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            let progress = self.loadTransferable(type: type) { result in
                continuation.resume(with: result)
            }
            reportProgress(progress)
        }
    }
}

extension NSItemProvider : LoadingTransferable {
    func loadTransferable<T : Transferable>(
        type: T.Type,
        reportProgress: (Progress) -> Void
    ) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            let progress = self.loadTransferable(type: type) { result in
                continuation.resume(with: result)
            }
            reportProgress(progress)
        }
    }
}
