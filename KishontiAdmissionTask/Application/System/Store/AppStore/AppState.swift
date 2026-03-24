//
//  AppState.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public typealias PeerIdentifier = String

public struct AppState: StoreState {
    /// Shows if the application is active
    public var isServiceActive: Bool
    /// List of known peers, with its data, name, etc.
    public var peerList: [PeerIdentifier: Peer]
    /// Peers in discovered state
    public var discoveredPeers: Set<PeerIdentifier>
    /// Peers in connected state
    public var connectedPeers: Set<PeerIdentifier>
    /// Paired peers
    public var pairedPeerIds: Set<PeerIdentifier>
    /// Pending invitations
    public var pendingInvitation: PeerIdentifier?
    /// Log items
    public var logs: [NetworkEventLogItem]
    /// Current heartbeat interval
    public var heartbeatInterval: TimeInterval
    /// Current heartbeat retention hours
    public var heartbeatRetentionHours: Int
    /// List of heartbeats per peer
    public var heartbeats: [PeerIdentifier: [PeerHeartbeat]]

    public init(isServiceActive: Bool = false,
                peerList: [PeerIdentifier: Peer] = [:],
                discoveredPeers: Set<PeerIdentifier> = [],
                connectedPeers: Set<PeerIdentifier> = [],
                pairedPeerIds: Set<PeerIdentifier> = [],
                pendingInvitation: PeerIdentifier? = nil,
                logs: [NetworkEventLogItem] = [],
                heartbeatInterval: TimeInterval = Constants.defaultHeartbeatInterval,
                heartbeatRetentionHours: Int = Constants.defaultHeartbeatRetentionHours,
                heartbeats: [PeerIdentifier: [PeerHeartbeat]] = [:]) {
        self.isServiceActive = isServiceActive
        self.peerList = peerList
        self.discoveredPeers = discoveredPeers
        self.connectedPeers = connectedPeers
        self.pairedPeerIds = pairedPeerIds
        self.pendingInvitation = pendingInvitation
        self.logs = logs
        self.heartbeatInterval = heartbeatInterval
        self.heartbeatRetentionHours = heartbeatRetentionHours
        self.heartbeats = heartbeats
    }

    ///
    /// These values will be persisted
    ///
    private enum CodingKeys: String, CodingKey {
        case isServiceActive
        case pairedPeerIds
        case heartbeatInterval
        case heartbeatRetentionHours
        case heartbeats
    }

    ///
    /// This controls when the system needs to save
    ///
    public func needsPersistence(comparedTo previous: AppState) -> Bool {
        self.isServiceActive != previous.isServiceActive ||
        self.pairedPeerIds != previous.pairedPeerIds ||
        self.heartbeatInterval != previous.heartbeatInterval ||
        self.heartbeatRetentionHours != previous.heartbeatRetentionHours ||
        self.heartbeats != previous.heartbeats
    }

    ///
    /// Init from stored persisted data
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isServiceActive = (try? container.decode(Bool.self, forKey: .isServiceActive)) ?? false
        peerList = [:]
        discoveredPeers = []
        connectedPeers = []
        pendingInvitation = nil
        logs = []
        pairedPeerIds = (try? container.decode(Set<PeerIdentifier>.self, forKey: .pairedPeerIds)) ?? []
        heartbeatInterval = (try? container.decode(TimeInterval.self, forKey: .heartbeatInterval)) ?? Constants.defaultHeartbeatInterval
        heartbeatRetentionHours = (try? container.decode(Int.self, forKey: .heartbeatRetentionHours)) ?? Constants.defaultHeartbeatRetentionHours
        heartbeats = (try? container.decode([PeerIdentifier: [PeerHeartbeat]].self, forKey: .heartbeats)) ?? [:]
    }
}
