//
//  Persistence.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 05..
//

import Foundation
import CoreData

// Protocol
public protocol StatePersisting<State>: Sendable {
    associatedtype State: Sendable
    
    func save(_ state: State) async throws
    func load() async throws -> State?
    func clear() async throws
}

// No-op
struct NoOpPersistence<State: Sendable>: StatePersisting {
    func save(_ state: State) async throws {}
    func load() async throws -> State? { nil }
    func clear() async throws {}
}

// File-based
struct FilePersistence<State: Sendable & Codable>: StatePersisting {
    let url: URL
    
    func save(_ state: State) async throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: .atomic)
    }
    
    func load() async throws -> State? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try JSONDecoder().decode(State.self, from: data)
    }
    
    func clear() async throws {
        try FileManager.default.removeItem(at: url)
    }
}

// UserDefaults
struct UserDefaultsPersistence<State: Sendable & Codable>: StatePersisting {
    let key: String
    nonisolated(unsafe) let defaults: UserDefaults
    
    init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }
    
    func save(_ state: State) async throws {
        let data = try JSONEncoder().encode(state)
        defaults.set(data, forKey: key)
    }
    
    func load() async throws -> State? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(State.self, from: data)
    }
    
    func clear() async throws {
        defaults.removeObject(forKey: key)
    }
}
