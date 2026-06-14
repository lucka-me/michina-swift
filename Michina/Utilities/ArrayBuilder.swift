//
//  ArrayBuilder.swift
//  Michina
//
//  Created by Lucka on 2026-06-11.
//

@resultBuilder
enum ArrayBuilder<Elemenet> {
    static func buildBlock(_ components: [ Elemenet ]...) -> [ Elemenet ] {
        .init(components.joined())
    }
    
    static func buildExpression(_ expression: Elemenet) -> [ Elemenet ] {
        [ expression ]
    }
    
    static func buildExpression(_ expression: [ Elemenet ]) -> [ Elemenet ] {
        expression
    }
    
    static func buildArray(_ components: [ [ Elemenet ] ]) -> [ Elemenet ] {
        components.flatMap(\.self)
    }
}

extension Array {
    init(@ArrayBuilder<Element> content: () -> Array) {
        self = content()
    }
}
