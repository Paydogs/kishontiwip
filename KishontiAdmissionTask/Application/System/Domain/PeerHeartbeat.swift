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

    public var date: Date {
        switch self {
        case .bluetooth(let date), .multipeer(let date): return date
        }
    }

    public var transport: Transport {
        switch self {
        case .bluetooth: return .bluetooth
        case .multipeer: return .multipeer
        }
    }
}
