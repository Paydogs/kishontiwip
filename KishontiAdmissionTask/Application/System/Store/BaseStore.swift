//
//  BaseStore.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

// MARK: Public Store interfaces
public protocol StoreState: Sendable, Equatable, Codable {
    func needsPersistence(comparedTo previous: Self) -> Bool
}

public protocol StorableProperty: Codable, Hashable, Equatable, Sendable {}

public protocol StoreProtocol: Actor {
    associatedtype StoreState: Sendable & Equatable

    var currentState: StoreState { get }
    func stateStream() -> AsyncStream<StoreState>
}

// MARK: Public BaseStore implementation
public final actor BaseStore<State: StoreState, Action: Intent>: StoreProtocol {
    public var currentState: State { _state }
    public var subscriberCount: Int { subscribers.count }
    
    private var _actionBus: ActionSource
    private var _persistence: (any StatePersisting<State>)?
    private var _state: State
    private var subscribers: [UUID: AsyncStream<State>.Continuation] = [:]
    private var saveTask: Task<Void, Never>?

    public init(actionBus: ActionSource, persistence: (any StatePersisting<State>)? = nil, initialState: State) {
        _actionBus = actionBus
        _persistence = persistence
        _state = initialState
        
        if persistence != nil {
            Task {
                do {
                    try await self.load()
                } catch {
                    Log.error("Loading error: \(error)")
                    Log.error("Clearing...")
                    try await clear()
                }
            }
        }
    }

    deinit {
        saveTask?.cancel()
        for (_, subscriber) in subscribers {
            subscriber.finish()
        }
    }

    public func stateStream() -> AsyncStream<State> {
        AsyncStream { continuation in
            let subscriber = UUID()
            Log.debug("New subscriber: \(subscriber)")
            subscribers[subscriber] = continuation
            Log.debug("Subscriber count: \(subscribers.count)")

            continuation.onTermination = { [weak self] _ in
                Log.debug("Removing subscriber: \(subscriber)")
                Task { await self?.removeSubscriber(subscriber) }
            }

            continuation.yield(_state)
        }
    }

    public func update(_ mutation: @Sendable (inout State) -> Void) {
        var newState = _state
        mutation(&newState)
        guard newState != _state else { return }
        
        let oldState = _state
        _state = newState
        for (_, subscriber) in subscribers {
            subscriber.yield(_state)
        }
        if _persistence != nil, newState.needsPersistence(comparedTo: oldState) {
            debounceSave()
        }
    }
}

private extension BaseStore {
    func save() async {
        try? await _persistence?.save(_state)
    }
    
    func load() async throws {
        if let saved = try await _persistence?.load(), saved != _state {
            _state = saved
            for (_, s) in subscribers {
                s.yield(_state)
            }
        }
    }
    
    func clear() async throws {
        try await _persistence?.clear()
    }
    
    func debounceSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            try? await _persistence?.save(_state)
            Log.debug("Changes saved...")
        }
    }
    
    func removeSubscriber(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }
}

extension StoreState {
    public func needsPersistence(comparedTo previous: Self) -> Bool { self != previous }
}
