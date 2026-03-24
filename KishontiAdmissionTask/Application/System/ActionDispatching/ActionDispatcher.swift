//
//  ActionDispatcher.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 05..
//

import SwiftUI

// MARK: Protocols
public protocol Intent: Hashable {}
public protocol ActionSource {
    func register<Action: Intent>(_ type: Action.Type, handler: any ActionHandler)
}
public protocol ActionDispatching {
    func dispatch(_ action: any Intent)
    func dispatchConcurrently(_ actions: any Intent...)
}
public protocol ActionHandler {
    func handleAction(_ action: any Intent) async
}

// MARK: Action bus for States
public final class ActionBus: ActionSource {
    private let lock = NSLock()
    private var handlers: [ObjectIdentifier: any ActionHandler] = [:]
    private let continuation: AsyncStream<any Intent>.Continuation
    
    public init() {
        let (stream, continuation) = AsyncStream<any Intent>.makeStream()
        self.continuation = continuation
        Task { [weak self] in
            for await action in stream {
                guard let self else { return }
                let key = ObjectIdentifier(Swift.type(of: action))
                let handler = self.lock.withLock { self.handlers[key] }
                await handler?.handleAction(action)
            }
        }
    }
    
    public func register<Action: Intent>(_ type: Action.Type, handler: ActionHandler) {
        lock.withLock { handlers[ObjectIdentifier(type)] = handler }
    }
    
    internal func dispatch(_ action: any Intent) {
        continuation.yield(action)
    }
    
    internal func dispatchConcurrently(_ actions: [any Intent]) {
        let snapshot = lock.withLock { handlers }
        Task {
            await withTaskGroup(of: Void.self) { group in
                for action in actions {
                    let key = ObjectIdentifier(Swift.type(of: action))
                    if let handler = snapshot[key] {
                        group.addTask { await handler.handleAction(action) }
                    }
                }
            }
        }
    }
}

// MARK: Provide only dispatching capability to the user
final class ActionDispatcher: ObservableObject, ActionDispatching {
    private let actionBus: ActionBus
    
    init(_ bus: ActionBus) {
        self.actionBus = bus
    }
    
    func dispatch(_ action: any Intent) {
        actionBus.dispatch(action)
    }
    
    func dispatchConcurrently(_ actions: any Intent...) {
        actionBus.dispatchConcurrently(actions)
    }
}
