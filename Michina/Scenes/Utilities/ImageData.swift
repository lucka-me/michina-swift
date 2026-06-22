//
//  ImageData.swift
//  Michina
//
//  Created by Lucka on 2026-06-19.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImageData : Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = NSImage(data: data) else {
                throw .runtime("Unable to decode the image.")
            }
            
            return .init(
                data: data,
                image: .init(nsImage: image)
                    .antialiased(true)
                    .resizable()
            )
        }
    }
    
    let data: Data
    let image: Image
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
