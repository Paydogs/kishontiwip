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
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logServicePrimary, secondaryText: bool ? Keys.logServiceStartedSecondary : Keys.logServiceStoppedSecondary, date: Date(), severity: bool ? .info : .error))
        case .transportDiscovered(let peer, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: Keys.logTransportDiscoveredSecondary(transport.localizedName), date: Date(), severity: .info))
        case .transportLost(let peerId, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peerId, secondaryText: Keys.logTransportLostSecondary(transport.localizedName), date: Date(), severity: .error))
        case .peerConnected(let peer, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: Keys.logPeerConnectedSecondary(transport.localizedName), date: Date(), severity: .info))
        case .peerDisconnected(let peerId, let transport):
            return .addToEventLog(NetworkEventLogItem(primaryText: peerId, secondaryText: Keys.logPeerDisconnectedSecondary(transport.localizedName), date: Date(), severity: .error))
        case .addToEventLog(_):
            return action
        case .invitationReceived(let peerId):
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logInvitationReceivedPrimary(peerId), secondaryText: "", date: Date(), severity: .info))
        case .invitationCleared:
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logInvitationClearedPrimary, secondaryText: "", date: Date(), severity: .info))
        case .setHeartbeatInterval(let interval):
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logHeartbeatIntervalPrimary, secondaryText: Keys.logHeartbeatIntervalSecondary(Int(interval)), date: Date(), severity: .info))
        case .setHeartbeatRetentionHours(let hours):
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logHeartbeatRetentionPrimary, secondaryText: Keys.logHeartbeatRetentionSecondary(hours), date: Date(), severity: .info))
        case .heartbeatDetected:
            return action
        case .resetStorage:
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logResetStoragePrimary, secondaryText: "", date: Date(), severity: .error))
        case .resetLog:
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logClearLogsPrimary, secondaryText: "", date: Date(), severity: .error))
        case .peerPaired(_):
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logPeerPairedPrimary, secondaryText: "", date: Date(), severity: .info))
        case .peerUnpaired(_):
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logPeerUnpairedPrimary, secondaryText: "", date: Date(), severity: .error))
        }
    }
}

extension DeviceAction {
    static func createLogAction(from action: DeviceAction) -> AppAction {
        switch action {
        case .invite(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: Keys.logDeviceInvitedSecondary, date: Date(), severity: .warning))
        case .unpair(let peer):
            return .addToEventLog(NetworkEventLogItem(primaryText: peer.name, secondaryText: Keys.logDeviceUnpairedSecondary, date: Date(), severity: .error))
        case .acceptInvitation:
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logInvitationAcceptedPrimary, secondaryText: "", date: Date(), severity: .info))
        case .declineInvitation:
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logInvitationDeclinedPrimary, secondaryText: "", date: Date(), severity: .error))
        case .remoteUnpair(_):
            return .addToEventLog(NetworkEventLogItem(primaryText: Keys.logRemoteUnpairedPrimary, secondaryText: "", date: Date(), severity: .error))
        }
    }
}
