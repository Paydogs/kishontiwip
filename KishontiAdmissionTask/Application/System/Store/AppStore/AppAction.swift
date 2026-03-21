//
//  AppAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//
import Foundation

public enum AppAction: Intent {
    case setServiceActive(Bool)
    case transportDiscovered(Peer, Transport)
    case transportLost(Peer, Transport)
    case peerConnected(Peer, Transport)
    case peerDisconnected(Peer, Transport)
    case invitationReceived(Peer)
    case invitationCleared
    case addToEventLog(NetworkEventLogItem)
    case setHeartbeatInterval(TimeInterval)
    case setHeartbeatRetentionHours(Int)
    case heartbeatDetected(Peer, Transport)
    case resetLog
    case resetStorage
}
