//
//  AppStore.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public final class AppStore: ActionHandler {
    private let store: BaseStore<AppState, AppAction>
    
    public init(actionBus: ActionSource, persistence: (any StatePersisting<AppState>)? = nil, initialState: AppState = AppState()) {
        self.store = BaseStore(actionBus: actionBus, persistence: persistence, initialState: initialState)
        actionBus.register(AppAction.self, handler: self)
    }
    
    // MARK: - Read-only interface
    
    var currentState: AppState {
        get async { await store.currentState }
    }
    
    func stateStream() async -> AsyncStream<AppState> {
        await store.stateStream()
    }
    
    func stream<A: Equatable>(_ kp1: KeyPath<AppState, A>) async -> AsyncStream<AppState> {
        await store.stream(kp1)
    }
    
    func stream<A: Equatable, B: Equatable>(
        _ kp1: KeyPath<AppState, A>,
        _ kp2: KeyPath<AppState, B>
    ) async -> AsyncStream<AppState> {
        await store.stream(kp1, kp2)
    }
    
    func stream<A: Equatable, B: Equatable, C: Equatable>(
        _ kp1: KeyPath<AppState, A>,
        _ kp2: KeyPath<AppState, B>,
        _ kp3: KeyPath<AppState, C>
    ) async -> AsyncStream<AppState> {
        await store.stream(kp1, kp2, kp3)
    }
    
    // MARK: - Action handling
    
    public func handleAction(_ action: any Intent) async {
        guard let action = action as? AppAction else { return }
        switch action {
        // Service status changes
        case .setServiceActive(let value):
            await store.update { state in
                state.isServiceActive = value
            }
        // Transport discovered for peer
        case .transportDiscovered(let peer, let transport):
            await store.update { state in
                var updated = state.peerList[peer.peerId] ?? peer
                updated.activeTransports.insert(transport)
                state.peerList[peer.peerId] = updated
                state.discoveredPeers.insert(peer.peerId)
                Log.debug("[Store] transportDiscovered Updated peerList: \(state.peerList)")
            }
        // Transport lost for peer
        case .transportLost(let peerId, let transport):
            await store.update { state in
                guard var existing = state.peerList[peerId] else { return }
                existing.activeTransports.remove(transport)
                state.peerList[peerId] = existing
                if existing.activeTransports.isEmpty && !state.pairedPeerIds.contains(peerId) {
                    state.connectedPeers.remove(peerId)
                }
                Log.debug("[Store] transportLost Updated peerList: \(state.peerList)")
            }
        // Peer connected
        case .peerConnected(let peer, let transport):
            await store.update { state in
                var updated = state.peerList[peer.peerId] ?? peer
                updated.activeTransports.insert(transport)
                state.peerList[peer.peerId] = updated
                state.connectedPeers.insert(peer.peerId)
                state.discoveredPeers.remove(peer.peerId)
                Log.debug("[Store] peerConnected, Updated peerList: \(state.peerList)")
            }
        // Peer disconnected
        case .peerDisconnected(let peerId, let transport):
            await store.update { state in
                guard var existing = state.peerList[peerId] else { return }
                existing.activeTransports.remove(transport)
                state.peerList[peerId] = existing
                if existing.activeTransports.isEmpty && !state.pairedPeerIds.contains(peerId) {
                    state.connectedPeers.remove(peerId)
                }
                Log.debug("[Store] peerDisconnected, Updated peerList: \(state.peerList)")
            }
        // Invitation received from peer
        case .invitationReceived(let peerId):
            await store.update { state in
                state.pendingInvitation = peerId
                Log.debug("[Store] invitationReceived from \(peerId)")
            }
        // Invitation handled
        case .invitationCleared:
            await store.update { state in
                state.pendingInvitation = nil
                Log.debug("[Store] invitationCleared")
            }
        // New item for the Event Log
        case .addToEventLog(let message):
            await store.update { state in
                state.logs.append(message)
            }
        // Setting new Heartbeat interval
        case .setHeartbeatInterval(let interval):
            await store.update { state in
                state.heartbeatInterval = interval
            }
        // Setting new Heartbeat retention hours
        case .setHeartbeatRetentionHours(let hours):
            await store.update { state in
                state.heartbeatRetentionHours = hours
                // Clear entries older than the new retention end date
                let newRetentionEndDate = Date().addingTimeInterval(-.hours(hours))
                for (id, entries) in state.heartbeats {
                    state.heartbeats[id] = entries.filter { $0.date > newRetentionEndDate }
                }
            }
        // New heartbeat received
        case .heartbeatDetected(let peerId, let heartbeat):
            await store.update { state in
                Log.debug("[Store] \(heartbeat) received from \(peerId)")
                let retentionEndDate = Date().addingTimeInterval(-.hours(state.heartbeatRetentionHours))
                var entries = state.heartbeats[peerId, default: []]
                entries.append(heartbeat)
                state.heartbeats[peerId] = entries.filter { $0.date > retentionEndDate }
            }
        // Peer paired
        case .peerPaired(let peerId):
            await store.update { state in
                state.pairedPeerIds.insert(peerId)
                Log.debug("[Store] New paired peer: \(peerId), current paired peers: \(state.pairedPeerIds)")
            }
        // Peer unpaired
        case .peerUnpaired(let peerId):
            await store.update { state in
                state.pairedPeerIds.remove(peerId)
                state.connectedPeers.remove(peerId)
                Log.debug("[Store] \(peerId) unpaired, current paired peers: \(state.pairedPeerIds), current connected peers: \(state.connectedPeers)")
            }
        // Reset logs
        case .resetLog:
            await store.update { state in
                state.logs.removeAll()
            }
        // Reset all data
        case .resetStorage:
            await store.update { state in
                Log.debug("Reseting storage")
                state.peerList.removeAll()
                state.connectedPeers.removeAll()
                state.discoveredPeers.removeAll()
                state.pairedPeerIds.removeAll()
                state.heartbeats.removeAll()
                state.pendingInvitation = nil
                state.heartbeatInterval = Constants.defaultHeartbeatInterval
                state.heartbeatRetentionHours = Constants.defaultHeartbeatRetentionHours
                state.logs.removeAll()
            }
        }
    }
}
