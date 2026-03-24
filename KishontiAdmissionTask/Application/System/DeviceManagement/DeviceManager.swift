//
//  DeviceManager.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation

// MARK: - Protocol
protocol DeviceManaging {
    func peerDiscovered(_ peerId: PeerIdentifier, via transport: Transport)
    func peerLost(_ peerId: PeerIdentifier, via transport: Transport)
    func peerConnected(_ peerId: PeerIdentifier, via transport: Transport)
    func peerDisconnected(_ peerId: PeerIdentifier, via transport: Transport)
    func invitationReceived(from peerId: PeerIdentifier)
    func invitationCleared()
    func heartbeatDetected(_ peerId: PeerIdentifier, _ heartbeat: PeerHeartbeat)
    func pair(peerId: PeerIdentifier)
    func unpair(peerId: PeerIdentifier)
    func remoteActionReceived(_ action: RemoteAction, from peerId: PeerIdentifier)
    func showLog(logItem: NetworkEventLogItem)
    func updatePeerList(_ peerList: [PeerIdentifier: Peer])
}

// MARK: - Implementation
final class DefaultDeviceManager: DeviceManaging {
    private let dispatcher: ActionDispatching
    private var peerList: [PeerIdentifier: Peer] = [:]

    init(dispatcher: ActionDispatching) {
        self.dispatcher = dispatcher
    }

    func updatePeerList(_ peerList: [PeerIdentifier: Peer]) {
        self.peerList = peerList
    }

    func peerDiscovered(_ peerId: PeerIdentifier, via transport: Transport) {
        let action = AppAction.transportDiscovered(peer(for: peerId), transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func peerLost(_ peerId: PeerIdentifier, via transport: Transport) {
        let action = AppAction.transportLost(peerId, transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func peerConnected(_ peerId: PeerIdentifier, via transport: Transport) {
        let action = AppAction.peerConnected(peer(for: peerId), transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func peerDisconnected(_ peerId: PeerIdentifier, via transport: Transport) {
        let action = AppAction.peerDisconnected(peerId, transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func invitationReceived(from peerId: PeerIdentifier) {
        let action = AppAction.invitationReceived(peerId)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func invitationCleared() {
        let action = AppAction.invitationCleared
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func heartbeatDetected(_ peerId: PeerIdentifier, _ heartbeat: PeerHeartbeat) {
        dispatcher.dispatch(AppAction.heartbeatDetected(peerId, heartbeat))
        
        let peer = peer(for: peerId)
        if let transport = heartbeat.transport,
            !peer.activeTransports.contains(transport) {
            dispatcher.dispatch(AppAction.transportDiscovered(peer, transport))
        }
    }

    func pair(peerId: PeerIdentifier) {
        let action = AppAction.peerPaired(peerId)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func unpair(peerId: PeerIdentifier) {
        let action = AppAction.peerUnpaired(peerId)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func remoteActionReceived(_ action: RemoteAction, from peerId: PeerIdentifier) {
        let peer = peer(for: peerId)
        switch action {
        case .unpair:
            let action = DeviceAction.remoteUnpair(peer)
            dispatcher.dispatch(action)
            dispatcher.dispatch(DeviceAction.createLogAction(from: action))
        case .message(let text):
            let logItem = NetworkEventLogItem(primaryText: peer.name, secondaryText: text, date: Date(), severity: .info)
            dispatcher.dispatch(AppAction.addToEventLog(logItem))
        }
    }

    func showLog(logItem: NetworkEventLogItem) {
        dispatcher.dispatch(AppAction.addToEventLog(logItem))
    }
}

private extension DefaultDeviceManager {
    func peer(for peerId: PeerIdentifier) -> Peer {
        peerList[peerId] ?? Peer(peerId: peerId, name: peerId)
    }
}
