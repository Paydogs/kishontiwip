//
//  AppState.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public typealias PeerIdentifier = String

public struct AppState: StoreState {
    public var isMultiPeerServiceActive: Bool
    public var isBluetoothServiceActive: Bool
    public var discoveredPeers: [PeerIdentifier: Peer]
    public var connectedPeers: [PeerIdentifier: Peer]
    public var pendingInvitation: Peer?
    public var messages: [NetworkEventLogItem]

    public init(isMultiPeerServiceActive: Bool = false,
                isBluetoothServiceActive: Bool = false,
                discoveredPeers: [PeerIdentifier: Peer] = [:],
                connectedPeers: [PeerIdentifier: Peer] = [:],
                pendingInvitation: Peer? = nil,
                messages: [NetworkEventLogItem] = []) {
        self.isMultiPeerServiceActive = isMultiPeerServiceActive
        self.isBluetoothServiceActive = isBluetoothServiceActive
        self.discoveredPeers = discoveredPeers
        self.connectedPeers = connectedPeers
        self.pendingInvitation = pendingInvitation
        self.messages = messages
    }

    // For persisting
    private enum CodingKeys: String, CodingKey {
        case connectedPeers
    }
    
    public func needsPersistence(comparedTo previous: AppState) -> Bool {
//        false
        self.connectedPeers != previous.connectedPeers
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isMultiPeerServiceActive = false
        isBluetoothServiceActive = false
        discoveredPeers = [:]
        connectedPeers = try container.decode([String: Peer].self, forKey: .connectedPeers)
        pendingInvitation = nil
        messages = []
    }
}
