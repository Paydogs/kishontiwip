//
//  BaseStore+Extensions.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

public extension BaseStore {
    func stream<A: Equatable>(
        _ kp1: KeyPath<State, A>
    ) -> AsyncStream<State> {
        AsyncStream { continuation in
            let task = Task {
                var prev: State? = nil
                for await state in self.stateStream() {
                    defer { prev = state }
                    guard let prev else { continuation.yield(state); continue }
                    guard state[keyPath: kp1] != prev[keyPath: kp1] else { continue }
                    continuation.yield(state)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    func stream<A: Equatable, B: Equatable>(
        _ kp1: KeyPath<State, A>,
        _ kp2: KeyPath<State, B>
    ) -> AsyncStream<State> {
        AsyncStream { continuation in
            let task = Task {
                var prev: State? = nil
                for await state in self.stateStream() {
                    defer { prev = state }
                    guard let prev else { continuation.yield(state); continue }
                    guard state[keyPath: kp1] != prev[keyPath: kp1] ||
                            state[keyPath: kp2] != prev[keyPath: kp2]
                    else { continue }
                    continuation.yield(state)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    func stream<A: Equatable, B: Equatable, C: Equatable>(
        _ kp1: KeyPath<State, A>,
        _ kp2: KeyPath<State, B>,
        _ kp3: KeyPath<State, C>
    ) -> AsyncStream<State> {
        AsyncStream { continuation in
            let task = Task {
                var prev: State? = nil
                for await state in self.stateStream() {
                    defer { prev = state }
                    guard let prev else { continuation.yield(state); continue }
                    guard state[keyPath: kp1] != prev[keyPath: kp1] ||
                            state[keyPath: kp2] != prev[keyPath: kp2] ||
                            state[keyPath: kp3] != prev[keyPath: kp3]
                    else { continue }
                    continuation.yield(state)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
