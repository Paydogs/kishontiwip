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
}
public protocol ActionHandler {
    func handleAction(_ action: any Intent) async
}

// MARK: Action bus for States
public final class ActionBus: ActionSource, ActionDispatching {
    private var handlers: [ObjectIdentifier: any ActionHandler] = [:]
    
    public func register<Action: Intent>(_ type: Action.Type, handler: ActionHandler) {
        handlers[ObjectIdentifier(type)] = handler
    }
    
    public func dispatch(_ action: any Intent) {
        let key = ObjectIdentifier(Swift.type(of: action))
        Task {
            await handlers[key]?.handleAction(action)
        }
    }
}

// MARK: Dispatching action
final class ActionDispatcher: ObservableObject, ActionDispatching {
    private let _dispatch: (any Intent) -> Void
    
    init(_ dispatcher: ActionDispatching) {
        self._dispatch = dispatcher.dispatch
    }
    
    func dispatch(_ action: any Intent) {
        _dispatch(action)
    }
}
