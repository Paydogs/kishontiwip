//
//  DeviceManager.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation

// MARK: - Protocol
protocol DeviceManaging {
    func peerDiscovered(_ peer: Peer, via transport: Transport)
    func peerLost(_ peer: Peer, via transport: Transport)
    func peerConnected(_ peer: Peer, via transport: Transport)
    func peerDisconnected(_ peer: Peer, via transport: Transport)
    func invitationReceived(from peer: Peer)
    func invitationCleared()
    func heartbeatDetected(_ peer: Peer, via transport: Transport)
    func showLog(logItem: NetworkEventLogItem)
}

// MARK: - Implementation
final class DefaultDeviceManager: DeviceManaging {
    private let dispatcher: ActionDispatching

    init(dispatcher: ActionDispatching) {
        self.dispatcher = dispatcher
    }

    func peerDiscovered(_ peer: Peer, via transport: Transport) {
        let action = AppAction.transportDiscovered(peer, transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func peerLost(_ peer: Peer, via transport: Transport) {
        let action = AppAction.transportLost(peer, transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func peerConnected(_ peer: Peer, via transport: Transport) {
        let action = AppAction.peerConnected(peer, transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func peerDisconnected(_ peer: Peer, via transport: Transport) {
        let action = AppAction.peerDisconnected(peer, transport)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func invitationReceived(from peer: Peer) {
        let action = AppAction.invitationReceived(peer)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func invitationCleared() {
        let action = AppAction.invitationCleared
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }

    func heartbeatDetected(_ peer: Peer, via transport: Transport) {
        dispatcher.dispatch(AppAction.heartbeatDetected(peer, transport))
    }

    func showLog(logItem: NetworkEventLogItem) {
        dispatcher.dispatch(AppAction.addToEventLog(logItem))
    }
}
