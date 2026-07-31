//
//  ExternalLinksCommands.swift
//  Michina
//
//  Created by Lucka on 2026-07-31.
//

import SwiftUI

struct ExternalLinksCommands : Commands {
    var body: some Commands {
        CommandGroup(after: .help) {
            Link(
                "ExternalLinksCommands.SourceCode",
                destination: .init(string: "https://github.com/lucka-me/michina-swift")!
            )
            Link(
                "ExternalLinksCommands.Website",
                destination: .init(string: "https://michina.lucka.dev")!
            )
            Link(
                "ExternalLinksCommands.TestFlight",
                destination: .init(string: "https://testflight.apple.com/join/rJP9acvk")!
            )
            Menu("ExternalLinksCommands.Dependencies") {
                Link(
                    "ExternalLinksCommands.Dependencies.ONNXRuntime",
                    destination: .init(string: "https://github.com/microsoft/onnxruntime")!
                )
                Link(
                    "ExternalLinksCommands.Dependencies.Tokenizers",
                    destination: .init(string: "https://github.com/huggingface/tokenizers")!
                )
                Link(
                    "ExternalLinksCommands.Dependencies.Hummingbird",
                    destination: .init(string: "https://github.com/hummingbird-project/hummingbird")!
                )
                Link(
                    "ExternalLinksCommands.Dependencies.MLX",
                    destination: .init(string: "https://github.com/ml-explore/mlx-swift")!
                )
            }
        }
    }
}
