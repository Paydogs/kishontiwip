//
//  AppState.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public typealias PeerIdentifier = String

public struct AppState: StoreState {
    public var isServiceActive: Bool
    public var discoveredPeers: [PeerIdentifier: Peer]
    public var connectedPeers: [PeerIdentifier: Peer]
    public var pendingInvitation: Peer?
    public var messages: [NetworkEventLogItem]
    public var heartbeatInterval: TimeInterval
    public var heartbeatRetentionHours: Int
    public var heartbeats: [PeerIdentifier: [PeerHeartbeat]]

    public init(isServiceActive: Bool = false,
                discoveredPeers: [PeerIdentifier: Peer] = [:],
                connectedPeers: [PeerIdentifier: Peer] = [:],
                pendingInvitation: Peer? = nil,
                messages: [NetworkEventLogItem] = [],
                heartbeatInterval: TimeInterval = Constants.defaultHeartbeatInterval,
                heartbeatRetentionHours: Int = Constants.defaultHeartbeatRetentionHours,
                heartbeats: [PeerIdentifier: [PeerHeartbeat]] = [:],
                lastHeartbeatTick: Date? = nil) {
        self.isServiceActive = isServiceActive
        self.discoveredPeers = discoveredPeers
        self.connectedPeers = connectedPeers
        self.pendingInvitation = pendingInvitation
        self.messages = messages
        self.heartbeatInterval = heartbeatInterval
        self.heartbeatRetentionHours = heartbeatRetentionHours
        self.heartbeats = heartbeats
    }

    // For persisting
    private enum CodingKeys: String, CodingKey {
        case isServiceActive
        case connectedPeers
        case heartbeatInterval
        case heartbeatRetentionHours
        case heartbeats
    }

    public func needsPersistence(comparedTo previous: AppState) -> Bool {
        self.isServiceActive != previous.isServiceActive ||
        self.connectedPeers != previous.connectedPeers ||
        self.heartbeatInterval != previous.heartbeatInterval ||
        self.heartbeatRetentionHours != previous.heartbeatRetentionHours ||
        self.heartbeats != previous.heartbeats
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isServiceActive = (try? container.decode(Bool.self, forKey: .isServiceActive)) ?? false
        discoveredPeers = [:]
        connectedPeers = try container.decode([String: Peer].self, forKey: .connectedPeers)
        pendingInvitation = nil
        messages = []
        heartbeatInterval = (try? container.decode(TimeInterval.self, forKey: .heartbeatInterval)) ?? Constants.defaultHeartbeatInterval
        heartbeatRetentionHours = (try? container.decode(Int.self, forKey: .heartbeatRetentionHours)) ?? Constants.defaultHeartbeatRetentionHours
        heartbeats = (try? container.decode([PeerIdentifier: [PeerHeartbeat]].self, forKey: .heartbeats)) ?? [:]
    }
}
