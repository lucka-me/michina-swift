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
        alertAction(.localized(error: Message(message)))
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
        } catch {
            alertAction(.generic(error: error))
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

extension AlertAction {
    struct Message : LocalizedError {
        let errorDescription: String?
        
        init(_ message: String) {
            self.errorDescription = message
        }
    }
}

extension EnvironmentValues {
    @Entry var alert = AlertAction { _ in }
}

extension View {
    func alertable() -> some View {
        modifier(AlertableModifier())
    }
}

fileprivate enum AlertableError: LocalizedError {
    case localized(error: LocalizedError)
    case generic(error: Error)
    
    var errorDescription: String? {
        switch self {
        case .localized(let error):
            error.errorDescription ?? error.localizedDescription
        case .generic(let error):
            error.localizedDescription
        }
    }
        
    var failureReason: String? {
        switch self {
        case .localized(let error): error.failureReason
        default: nil
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
