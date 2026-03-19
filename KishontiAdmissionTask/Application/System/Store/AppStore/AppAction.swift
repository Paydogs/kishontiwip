//
//  AppAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

public enum AppAction: Intent {
    case setMultiPeerServiceActive(Bool)
    case setBluetoothServiceActive(Bool)
    case peerDiscovered(Peer)
    case peerUpdated(Peer)
    case peerLost(Peer)
    case peerConnected(Peer)
    case peerDisconnected(Peer)
    case invitationReceived(Peer)
    case invitationCleared
    case addToEventLog(NetworkEventLogItem)
    case resetStorage
}
