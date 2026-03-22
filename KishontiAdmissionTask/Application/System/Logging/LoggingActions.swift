//
//  LoggingActions.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation

extension AppAction {
    static func createLogAction(from action: AppAction) -> AppAction {
        switch action {
        case .setServiceActive(let bool):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Your app", secondaryText: "\(bool ? "started" : "stopped") services", date: Date(), severity: bool ? .info : .error))
        case .transportDiscovered(let peer, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "discovered (\(transport.rawValue))", date: Date(), severity: .info))
        case .transportLost(let peer, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "lost (\(transport.rawValue))", date: Date(), severity: .error))
        case .peerConnected(let peer, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "connected (\(transport.rawValue))", date: Date(), severity: .info))
        case .peerDisconnected(let peer, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "disconnected (\(transport.rawValue))", date: Date(), severity: .error))
        case .addToEventLog(_):
            return action
        case .invitationReceived(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Recieved invitation from \(peer.name)", secondaryText: "", date: Date(), severity: .info))
        case .invitationCleared:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Invitation cleared", secondaryText: "", date: Date(), severity: .info))
        case .setHeartbeatInterval(let interval):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Heartbeat interval", secondaryText: "\(Int(interval))s", date: Date(), severity: .info))
        case .setHeartbeatRetentionHours(let hours):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Heartbeat retention", secondaryText: "\(hours)h", date: Date(), severity: .info))
        case .heartbeatDetected:
            return action
        case .resetStorage:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Reseting store", secondaryText: "", date: Date(), severity: .error))
        case .resetLog:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Clearing logs", secondaryText: "", date: Date(), severity: .error))
        }
    }
}

extension DeviceAction {
    static func createLogAction(from action: DeviceAction) -> AppAction {
        switch action {
        case .invite(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "invited", date: Date(), severity: .warning))
        case .disconnect(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "disconnected", date: Date(), severity: .error))
        case .acceptInvitation:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Accepted invitation", secondaryText: "", date: Date(), severity: .info))
        case .declineInvitation:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Declined invitation", secondaryText: "", date: Date(), severity: .error))
        }
    }
}
