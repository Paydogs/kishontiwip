//
//  AppState.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public typealias PeerIdentifier = String

public struct AppState: StoreState {
    public var isAdvertising: Bool = false
    public var isBrowsing: Bool = false
    public var discoveredPeers: [PeerIdentifier: Peer] = [:]
    public var connectedPeers: [PeerIdentifier: Peer]
    public var messages: [NetworkEventLogItem] = []
    
    public init(connectedPeers: [PeerIdentifier: Peer], ) {
        self.connectedPeers = connectedPeers
    }

    // For persisting
    private enum CodingKeys: String, CodingKey {
        case connectedPeers
    }
    
    public func needsPersistence(comparedTo previous: AppState) -> Bool {
        self.connectedPeers != previous.connectedPeers
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectedPeers = try container.decode([String: Peer].self, forKey: .connectedPeers)
    }
    
    public static func initialValue() -> Self {
        return .init(connectedPeers: [:])
    }
}
