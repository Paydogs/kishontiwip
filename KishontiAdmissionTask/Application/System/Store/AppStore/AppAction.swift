//
//  AppAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

enum AppAction: Intent {
    case setAdvertising(Bool)
    case peerDiscovered(Peer)
    case peerLost(Peer)
    case peerConnected(Peer)
    case peerDisconnected(Peer)
    case eventLogReceived(NetworkEventLogItem)
}
