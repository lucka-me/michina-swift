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
    
    @Binding private var selection: ImageData?

    @State private var pickedPhotoItem: PhotosPickerItem? = nil
    @State private var loadImageProgress: Progress? = nil
    
    private let label: () -> Label
    
    init(
        selection: Binding<ImageData?>,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._selection = selection
        self.label = label
    }
    
    var body: some View {
        ZStack {
            PhotosPicker(selection: $pickedPhotoItem, label: label)
                .onDrop(
                    of: [ .image ],
                    isTargeted: nil,
                    perform: handleDrop(items:)
                )
                .onChange(of: pickedPhotoItem) {
                    guard let pickedPhotoItem else {
                        return
                    }
                    
                    self.loadImageProgress = pickedPhotoItem.loadTransferable(
                        type: ImageData.self,
                        completionHandler: handle(result:)
                    )
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
    init(_ titleKey: LocalizedStringKey, selection: Binding<ImageData?>) {
        self.init(selection: selection) {
            Text(titleKey)
        }
    }
    
    init(selection: Binding<ImageData?>) {
        self.init(selection: selection) {
            Text("UnifiedPhotoPicker.DefaultLabel")
        }
    }
}

fileprivate extension UnifiedPhotoPicker {
    func handleDrop(items: [ NSItemProvider ]) -> Bool {
        guard let item = items.first else {
            return false
        }
        self.loadImageProgress = item.loadTransferable(
            type: ImageData.self,
            completionHandler: handle(result:)
        )
        return true
    }
    
    nonisolated func handle(result: Result<ImageData, any Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let imageData):
                self.selection = imageData
            case .failure(let error):
                alert(error)
            }
            self.loadImageProgress = nil
        }
    }
    
    nonisolated func handle(result: Result<ImageData?, any Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let imageData):
                self.selection = imageData
            case .failure(let error):
                alert(error)
            }
            self.loadImageProgress = nil
        }
    }
}
