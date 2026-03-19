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
        case .setMultiPeerServiceActive(let bool):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Your app", secondaryText: "\(bool ? "started" : "stopped") watching on MultiPeer service", date: Date(), severity: bool ? .info : .error))
        case .setBluetoothServiceActive(let bool):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Your app", secondaryText: "\(bool ? "started" : "stopped") watching on Bluetooth service", date: Date(), severity: bool ? .info : .error))
        case .peerDiscovered(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "discovered (\(peer.transportLabel))", date: Date(), severity: .info))
        case .peerLost(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "lost", date: Date(), severity: .error))
        case .peerConnected(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "connected", date: Date(), severity: .info))
        case .peerDisconnected(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "disconnected", date: Date(), severity: .error))
        case .addToEventLog(_):
            return action
        case .peerUpdated(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: "updated (\(peer.transportLabel))", date: Date(), severity: .info))
        case .invitationReceived(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: "Recieved invitation from \(peer.name)", secondaryText: "", date: Date(), severity: .info))
        case .invitationCleared:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Invitation cleared", secondaryText: "", date: Date(), severity: .info))
        case .resetStorage:
            return .addToEventLog(NetworkEventLogItem(primaryText: "Reseting store", secondaryText: "", date: Date(), severity: .error))
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
