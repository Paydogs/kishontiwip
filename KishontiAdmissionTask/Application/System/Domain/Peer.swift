//
//  Peer.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public struct Peer: StorableProperty {
    public var peerId: PeerIdentifier
    public var name: String

    public init(peerId: PeerIdentifier, name: String) {
        self.peerId = peerId
        self.name = name
    }
}
