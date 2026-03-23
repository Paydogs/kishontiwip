//
//  AppAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//
import Foundation

public enum AppAction: Intent {
    // Change the service status
    case setServiceActive(Bool)
    // Transport type discovered
    case transportDiscovered(Peer, Transport)
    // Transport type lost
    case transportLost(PeerIdentifier, Transport)
    // Peer connected
    case peerConnected(Peer, Transport)
    // Peer disconnected
    case peerDisconnected(PeerIdentifier, Transport)
    // Invitation received from peer
    case invitationReceived(PeerIdentifier)
    // Invitation handled
    case invitationCleared
    // Add new event log
    case addToEventLog(NetworkEventLogItem)
    // Change heartbeat interval
    case setHeartbeatInterval(TimeInterval)
    // Change heartbeat retention hour
    case setHeartbeatRetentionHours(Int)
    // Add new heartbeat
    case heartbeatDetected(PeerIdentifier, PeerHeartbeat)
    // Peer paired
    case peerPaired(PeerIdentifier)
    // Peer unpaired
    case peerUnpaired(PeerIdentifier)
    // Reset log
    case resetLog
    // Reset all storage
    case resetStorage
}
