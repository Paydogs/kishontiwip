//
//  Peer.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public struct Peer: StorableProperty, Identifiable {
    public var id: PeerIdentifier { peerId }
    
    public var peerId: PeerIdentifier
    public var name: String
    public var activeTransports: Set<Transport>

    public init(peerId: PeerIdentifier, name: String, activeTransports: Set<Transport> = []) {
        self.peerId = peerId
        self.name = name
        self.activeTransports = activeTransports
    }

    private enum CodingKeys: String, CodingKey {
        case peerId, name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        peerId = try container.decode(PeerIdentifier.self, forKey: .peerId)
        name = try container.decode(String.self, forKey: .name)
        activeTransports = []
    }
}

extension Peer {
    var transportLabel: String {
        activeTransports
            .sorted(by: { $0.rawValue < $1.rawValue })
            .map { transport in
                switch transport {
                case .bluetooth: return "Bluetooth"
                case .multipeer: return "MultiPeer"
                }
            }
            .joined(separator: ", ")
    }
}
