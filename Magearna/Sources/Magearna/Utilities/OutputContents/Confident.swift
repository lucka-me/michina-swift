//
//  Confident.swift
//  Magearna
//
//  Created by Lucka on 2026-06-11.
//

public struct Confident<Item: Sendable> : Sendable {
    public let confidence: Float
    public let item: Item
}
