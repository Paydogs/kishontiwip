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
    func showLog(logItem: NetworkEventLogItem)
}

// MARK: - Implementation
final class DefaultDeviceManager: DeviceManaging {
    private let dispatcher: ActionDispatching
    private let lock = NSLock()
    private var transports: [PeerIdentifier: Set<Transport>] = [:]
    private var peers: [PeerIdentifier: Peer] = [:]

    init(dispatcher: ActionDispatching) {
        self.dispatcher = dispatcher
    }

    func peerDiscovered(_ peer: Peer, via transport: Transport) {
        lock.withLock {
            let isNew = transports[peer.peerId] == nil
            transports[peer.peerId, default: []].insert(transport)
            let updated = updated(peer, transports: transports[peer.peerId]!)
            peers[peer.peerId] = updated
            let action = isNew ? AppAction.peerDiscovered(updated) : AppAction.peerUpdated(updated)
            dispatcher.dispatch(action)
            dispatcher.dispatch(AppAction.createLogAction(from: action))
        }
    }

    func peerLost(_ peer: Peer, via transport: Transport) {
        lock.withLock {
            transports[peer.peerId]?.remove(transport)
            if transports[peer.peerId]?.isEmpty ?? true {
                transports.removeValue(forKey: peer.peerId)
                peers.removeValue(forKey: peer.peerId)
                
                let action = AppAction.peerLost(peer)
                dispatcher.dispatch(action)
                dispatcher.dispatch(AppAction.createLogAction(from: action))
            } else {
                let updated = updated(peers[peer.peerId] ?? peer, transports: transports[peer.peerId]!)
                peers[peer.peerId] = updated
                
                let action = AppAction.peerUpdated(updated)
                dispatcher.dispatch(action)
                dispatcher.dispatch(AppAction.createLogAction(from: action))
            }
        }
    }

    func peerConnected(_ peer: Peer, via transport: Transport) {
        lock.withLock {
            transports[peer.peerId, default: []].insert(transport)
            let updated = updated(peer, transports: transports[peer.peerId]!)
            peers[peer.peerId] = updated
            
            let action = AppAction.peerConnected(updated)
            dispatcher.dispatch(action)
            dispatcher.dispatch(AppAction.createLogAction(from: action))
        }
    }

    func peerDisconnected(_ peer: Peer, via transport: Transport) {
        lock.withLock {
            transports[peer.peerId]?.remove(transport)
            if transports[peer.peerId]?.isEmpty ?? true {
                transports.removeValue(forKey: peer.peerId)
                peers.removeValue(forKey: peer.peerId)

                let action = AppAction.peerDisconnected(peer)
                dispatcher.dispatch(action)
                dispatcher.dispatch(AppAction.createLogAction(from: action))
            } else {
                let updated = updated(peers[peer.peerId] ?? peer, transports: transports[peer.peerId]!)
                peers[peer.peerId] = updated
                
                let action = AppAction.peerUpdated(updated)
                dispatcher.dispatch(action)
                dispatcher.dispatch(AppAction.createLogAction(from: action))
            }
        }
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

    func showLog(logItem: NetworkEventLogItem) {
        dispatcher.dispatch(AppAction.addToEventLog(logItem))
    }
}

private extension DefaultDeviceManager {
    func updated(_ peer: Peer, transports: Set<Transport>) -> Peer {
        Peer(peerId: peer.peerId, name: peer.name, activeTransports: transports)
    }
}
