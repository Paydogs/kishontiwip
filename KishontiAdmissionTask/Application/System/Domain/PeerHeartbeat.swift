//
//  PeerHeartbeat.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 21..
//

import Foundation

public enum PeerHeartbeat: Codable, Hashable, Sendable {
    case bluetooth(Date)
    case multipeer(Date)
    case none(Date)

    public var date: Date {
        switch self {
        case .bluetooth(let date), .multipeer(let date), .none(let date): return date
        }
    }

    public var transport: Transport? {
        switch self {
        case .bluetooth: return .bluetooth
        case .multipeer: return .multipeer
        case .none: return nil
        }
    }
}

extension  PeerHeartbeat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bluetooth(let date):
            "Bluetooth Heartbeat at \(date)"
        case .multipeer(let date):
            "Multipeer Heartbeat at \(date)"
        case .none(let date):
            "No Heartbeat at \(date)"
        }
    }
}
