//
//  BaseStore.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public protocol StoreState: Sendable, Equatable, Codable {
    func needsPersistence(comparedTo previous: Self) -> Bool
}
public protocol StorableProperty: Codable, Hashable, Equatable, Sendable {}

public protocol StoreProtocol: Actor {
    associatedtype StoreState: Sendable & Equatable
    
    func stateStream() -> AsyncStream<StoreState>
    func currentState() -> StoreState
    func update(_ mutation: @Sendable (inout StoreState) -> Void)
}

public final actor BaseStore<State: StoreState, Action: Intent>: StoreProtocol {
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

            continuation.yield(_state)

            continuation.onTermination = { [weak self] _ in
                Log.debug("Removing subscriber: \(subscriber)")
                Task { await self?.removeSubscriber(subscriber) }
            }
        }
    }

    public func update(_ mutation: @Sendable (inout State) -> Void) {
        var newState = _state
        mutation(&newState)
        guard newState != _state else { return }
        
        let oldState = _state
        _state = newState
        for (_, s) in subscribers {
            s.yield(_state)
        }
        if _persistence != nil, newState.needsPersistence(comparedTo: oldState) {
            debounceSave()
        }
    }

    public func currentState() -> State {
        return _state
    }
    
    public func save() async {
        try? await _persistence?.save(_state)
    }
    
    public func load() async throws {
        if let saved = try await _persistence?.load(), saved != _state {
            _state = saved
            for (_, s) in subscribers {
                s.yield(_state)
            }
        }
    }
    
    public func clear() async throws {
        try await _persistence?.clear()
    }
        
    private func debounceSave() {
        Log.debug("Saving...")
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            try? await _persistence?.save(_state)
            Log.debug("Saved (?!)")
        }
    }
}

extension BaseStore {
    fileprivate func removeSubscriber(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }
}

public extension BaseStore {
    func stream<A: Equatable>(
        _ kp1: KeyPath<State, A>
    ) -> AsyncStream<State> {
        AsyncStream { continuation in
            Task {
                var prev: State? = nil
                for await state in await self.stateStream() {
                    defer { prev = state }
                    guard let prev else { continuation.yield(state); continue }
                    guard state[keyPath: kp1] != prev[keyPath: kp1] else { continue }
                    continuation.yield(state)
                }
            }
        }
    }

    func stream<A: Equatable, B: Equatable>(
        _ kp1: KeyPath<State, A>,
        _ kp2: KeyPath<State, B>
    ) -> AsyncStream<State> {
        AsyncStream { continuation in
            Task {
                var prev: State? = nil
                for await state in await self.stateStream() {
                    defer { prev = state }
                    guard let prev else { continuation.yield(state); continue }
                    guard state[keyPath: kp1] != prev[keyPath: kp1] ||
                          state[keyPath: kp2] != prev[keyPath: kp2]
                    else { continue }
                    continuation.yield(state)
                }
            }
        }
    }

    func stream<A: Equatable, B: Equatable, C: Equatable>(
        _ kp1: KeyPath<State, A>,
        _ kp2: KeyPath<State, B>,
        _ kp3: KeyPath<State, C>
    ) -> AsyncStream<State> {
        AsyncStream { continuation in
            Task {
                var prev: State? = nil
                for await state in await self.stateStream() {
                    defer { prev = state }
                    guard let prev else { continuation.yield(state); continue }
                    guard state[keyPath: kp1] != prev[keyPath: kp1] ||
                          state[keyPath: kp2] != prev[keyPath: kp2] ||
                          state[keyPath: kp3] != prev[keyPath: kp3]
                    else { continue }
                    continuation.yield(state)
                }
            }
        }
    }
}

extension StoreState {
    public func needsPersistence(comparedTo previous: Self) -> Bool { self != previous }
}
