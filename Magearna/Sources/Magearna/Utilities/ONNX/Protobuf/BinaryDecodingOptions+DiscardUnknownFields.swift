//
//  BinaryDecodingOptions+DiscardUnknownFields.swift
//  Magearna
//
//  Created by Lucka on 2026-06-02.
//

import SwiftProtobuf

extension BinaryDecodingOptions {
    static func discardUnknownFields(_ value: Bool) -> BinaryDecodingOptions {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = value
        return options
    }
}
