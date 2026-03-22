//
//  AppActionHandler.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public final class AppActionHandler: ActionHandler {
    private let store: AppStore

    public init(actionBus: ActionSource, store: AppStore) {
        self.store = store
        actionBus.register(AppAction.self, handler: self)
    }

    public func handleAction(_ action: any Intent) async {
        guard let action = action as? AppAction else { return }
        switch action {
        case .setServiceActive(let value):
            await store.update { $0.isServiceActive = value }
        case .transportDiscovered(let peer, let transport):
            await store.update { state in
                let existing = state.discoveredPeers[peer.peerId] ?? state.connectedPeers[peer.peerId]
                var updated = existing ?? peer
                updated.activeTransports.insert(transport)
                if state.connectedPeers[peer.peerId] != nil {
                    state.connectedPeers[peer.peerId] = updated
                } else {
                    state.discoveredPeers[peer.peerId] = updated
                }
            }
        case .transportLost(let peer, let transport):
            await store.update { state in
                if var existing = state.discoveredPeers[peer.peerId] {
                    existing.activeTransports.remove(transport)
                    if existing.activeTransports.isEmpty {
                        state.discoveredPeers.removeValue(forKey: peer.peerId)
                    } else {
                        state.discoveredPeers[peer.peerId] = existing
                    }
                } else if var existing = state.connectedPeers[peer.peerId] {
                    existing.activeTransports.remove(transport)
                    if existing.activeTransports.isEmpty {
                        state.connectedPeers.removeValue(forKey: peer.peerId)
                    } else {
                        state.connectedPeers[peer.peerId] = existing
                    }
                }
            }
        case .peerConnected(let peer, let transport):
            await store.update { state in
                var updated = state.discoveredPeers[peer.peerId] ?? state.connectedPeers[peer.peerId] ?? peer
                updated.activeTransports.insert(transport)
                state.connectedPeers[peer.peerId] = updated
                state.discoveredPeers.removeValue(forKey: peer.peerId)
            }
        case .peerDisconnected(let peer, let transport):
            await store.update { state in
                guard var existing = state.connectedPeers[peer.peerId] else { return }
                existing.activeTransports.remove(transport)
                state.connectedPeers[peer.peerId] = existing
            }
        case .invitationReceived(let peer):
            await store.update { $0.pendingInvitation = peer }
        case .invitationCleared:
            await store.update { $0.pendingInvitation = nil }
        case .addToEventLog(let message):
            await store.update { $0.messages.append(message) }
        case .setHeartbeatInterval(let interval):
            await store.update { $0.heartbeatInterval = interval }
        case .setHeartbeatRetentionHours(let hours):
            await store.update { state in
                state.heartbeatRetentionHours = hours
                let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
                for (id, entries) in state.heartbeats {
                    state.heartbeats[id] = entries.filter { $0.date > cutoff }
                }
            }
        case .heartbeatDetected(let peer, let transport):
            await store.update { state in
                let cutoff = Date().addingTimeInterval(-Double(state.heartbeatRetentionHours) * 3600)
                let heartbeat: PeerHeartbeat = transport == .bluetooth ? .bluetooth(Date()) : .multipeer(Date())
                var entries = state.heartbeats[peer.peerId, default: []]
                entries.append(heartbeat)
                state.heartbeats[peer.peerId] = entries.filter { $0.date > cutoff }
            }
        case .resetStorage:
            await store.update { state in
                state.connectedPeers.removeAll()
                state.discoveredPeers.removeAll()
                state.heartbeats.removeAll()
                state.heartbeatInterval = Constants.defaultHeartbeatInterval
                state.heartbeatRetentionHours = Constants.defaultHeartbeatRetentionHours
                state.messages.removeAll()
            }
        case .resetLog:
            await store.update { state in
                state.messages.removeAll()
            }
        }
    }
}
