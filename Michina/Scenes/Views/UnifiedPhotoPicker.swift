//
//  UnifiedPhotoPicker.swift
//  Michina
//
//  Created by Lucka on 2026-05-30.
//

import PhotosUI
import SwiftUI

struct UnifiedPhotoPicker : View {
    @Environment(\.alert) private var alert
    
    @Binding private var imageData: ImageData?

    @State private var pickedPhotoItem: PhotosPickerItem? = nil
    @State private var loadImageProgress: Progress? = nil
    
    init(_ imageData: Binding<ImageData?>) {
        self._imageData = imageData
    }
    
    var body: some View {
        if let loadImageProgress {
            ProgressView(loadImageProgress)
        } else {
            PhotosPicker("UnifiedPhotoPicker.PhotosPicker", selection: $pickedPhotoItem)
                .onDrop(
                    of: [ .image ],
                    isTargeted: nil,
                    perform: handleDrop(images:)
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
        }
    }
}

extension UnifiedPhotoPicker {
    struct ImageData : Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let image = NSImage(data: data) else {
                    throw .runtime("Unable to decode the image.")
                }
                
                return .init(
                    data: data,
                    image: .init(nsImage: image),
                    size: image.size
                )
            }
        }
        
        let data: Data
        let image: Image
        let size: CGSize
    }
}

fileprivate extension UnifiedPhotoPicker {
    func handleDrop(images: [ NSItemProvider ]) -> Bool {
        guard let image = images.first else {
            return false
        }
        self.loadImageProgress = image.loadTransferable(
            type: ImageData.self,
            completionHandler: handle(result:)
        )
        return true
    }
    
    nonisolated func handle(result: Result<ImageData, any Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let imageData):
                self.imageData = imageData
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
                self.imageData = imageData
            case .failure(let error):
                alert(error)
            }
            self.loadImageProgress = nil
        }
    }
}

fileprivate struct RuntimeError : Error {
    let reason: String
    
    var localizedDescription: String {
        reason
    }
}

fileprivate extension Error where Self == RuntimeError {
    static func runtime(_ reason: String) -> RuntimeError {
        .init(reason: reason)
    }
}
