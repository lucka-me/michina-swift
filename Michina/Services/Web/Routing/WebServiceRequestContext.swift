//
//  WebServiceRequestContext.swift
//  Michina
//
//  Created by Lucka on 2026-06-12.
//

import HTTPTypes
import Hummingbird
import NIOCore

struct WebServiceRequestContext : RemoteAddressRequestContext {
    let remoteAddress: SocketAddress?
    
    var coreContext: CoreRequestContextStorage
    
    init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
        self.remoteAddress = source.channel.remoteAddress
    }
    
    var requestDecoder: UnitedRequestDecoder {
        Self.requestDecoder
    }
    
    var maxUploadSize: Int {
        Self.maxUploadSize
    }
}

extension WebServiceRequestContext {
    func findClientAddress(with request: Request) -> String? {
        // https://github.com/vapor/vapor/blob/main/Sources/Vapor/Request/Request.swift
        if let forward = request.headers[values: .xForwardedFor].first {
            forward
        } else {
            self.remoteAddress?.ipAddress
        }
    }
}

fileprivate extension WebServiceRequestContext {
    static let requestDecoder = UnitedRequestDecoder()
    static let maxUploadSize = 10 * 1024 * 1024
}

fileprivate extension HTTPField.Name {
    static var xForwardedFor: Self {
        .init("X-Forwarded-For")!
    }
}
