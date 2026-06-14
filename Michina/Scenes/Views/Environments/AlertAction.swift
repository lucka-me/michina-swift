//
//  AlertAction.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import SwiftUI

@MainActor
struct AlertAction : Sendable {
    fileprivate typealias AlertAction = @MainActor (AlertableError) -> Void
    
    fileprivate let alertAction: AlertAction
    
    fileprivate nonisolated init(alertAction: @escaping AlertAction) {
        self.alertAction = alertAction
    }
    
    func callAsFunction(message: String) {
        alertAction(.message(content: message))
    }
    
    func callAsFunction(_ error: any Error) {
        if let error = error as? LocalizedError  {
            alertAction(.localized(error: error))
        } else {
            alertAction(.generic(error: error))
        }
    }
    
    func whenTrying(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch let error as LocalizedError {
            alertAction(.localized(error: error))
            return
        } catch {
            alertAction(.generic(error: error))
            return
        }
    }
    
    func whenTrying(
        name: String? = nil,
        priority: TaskPriority? = nil,
        _ operation: @Sendable @escaping () async throws -> Void
    ) {
        Task.detached(name: name, priority: priority) { @Sendable in
            do {
                try await operation()
            } catch let error as LocalizedError {
                await alertAction(.localized(error: error))
            } catch {
                await alertAction(.generic(error: error))
            }
        }
    }
}

extension EnvironmentValues {
    var alert: AlertAction {
        get { self[AlertEnvironmentKey.self] ?? .init() { _ in } }
        set { self[AlertEnvironmentKey.self] = newValue }
    }
}

extension View {
    func alertable() -> some View {
        modifier(AlertableModifier())
    }
}

fileprivate enum AlertableError: Error, LocalizedError {
    case localized(error: LocalizedError)
    case generic(error: Error)
    
    case message(content: String)
    
    var errorDescription: String? {
        switch self {
        case .localized(let error):
            error.errorDescription ?? error.localizedDescription
        case .generic(let error):
            error.localizedDescription
        case .message(let content):
            content
        }
    }
        
    var failureReason: String? {
        switch self {
        case .localized(let error):
            error.failureReason ?? error.localizedDescription
        case .generic(let error):
            error.localizedDescription
        case .message(_):
            nil
        }
    }
}

fileprivate struct AlertableModifier : ViewModifier {
    @State private var currentError: AlertableError? = nil
    @State private var isAlertPresented = false
    
    func body(content: Content) -> some View {
        content
            .environment(\.alert, .init(alertAction: makeAlert(_:)))
            .alert(
                isPresented: $isAlertPresented,
                error: currentError
            ) { _ in
            } message: { error in
                if let reason = error.failureReason {
                    Text(reason)
                }
            }
    }
    
    private func makeAlert(_ error: AlertableError) {
        currentError = error
        isAlertPresented = true
    }
}

fileprivate struct AlertEnvironmentKey : EnvironmentKey {
    static let defaultValue: AlertAction? = nil
}
