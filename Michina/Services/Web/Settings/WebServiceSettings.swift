//
//  WebServiceSettings.swift
//  Michina
//
//  Created by Lucka on 2026-06-04.
//

import Darwin
import Foundation
import SwiftUI
import System

@MainActor
@Observable
final class WebServiceSettings {
    var port: Int {
        didSet { storage.port = port }
    }
    
    var startWhenInitialized: Bool {
        didSet { storage.startWhenInitialized = startWhenInitialized }
    }
    
    private let storage = Storage()
    
    private init() {
        self.port = storage.port
        self.startWhenInitialized = storage.startWhenInitialized
    }
}

extension WebServiceSettings {
    static let shared = WebServiceSettings()
}

extension WebServiceSettings {
    static func collectHostAddresses() throws -> [ String ] {
        var headPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&headPointer) == .zero, let headPointer else {
            throw Errno(rawValue: errno)
        }
        
        defer {
            freeifaddrs(headPointer)
        }
        
        var results: [ String ] = [ ]
        var enumeratePointer: UnsafeMutablePointer<ifaddrs>? = headPointer
        while let address = enumeratePointer {
            defer {
                enumeratePointer = address.pointee.ifa_next
            }
            let flags = Int32(address.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_RUNNING) == IFF_RUNNING else {
                continue
            }
            let name = String(cString: address.pointee.ifa_name)
            guard name.hasPrefix("en") else {
                continue
            }
            guard let socketAddress = address.pointee.ifa_addr else {
                continue
            }
            guard socketAddress.pointee.sa_family == AF_INET else {
                continue
            }
            var hostBuffer = Array<CChar>(repeating: 0, count: .init(NI_MAXHOST))
            let getNameInfoResult = getnameinfo(
                address.pointee.ifa_addr,
                .init(socketAddress.pointee.sa_len),
                &hostBuffer,
                .init(hostBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard getNameInfoResult == .zero else {
                switch getNameInfoResult {
                case EAI_SYSTEM: throw Errno(rawValue: errno)
                default: throw Errno(rawValue: getNameInfoResult)
                }
            }
            guard let host = String(cString: hostBuffer, encoding: .utf8) else {
                continue
            }
            results.append(host)
        }
        return results
    }
}

fileprivate extension WebServiceSettings {
    struct Storage {
        @AppStorage("WebService.Port") var port = 3003
        @AppStorage("WebService.StartWhenInitialized") var startWhenInitialized = false
    }
}
