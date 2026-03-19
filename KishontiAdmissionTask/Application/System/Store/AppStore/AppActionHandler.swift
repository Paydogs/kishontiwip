//
//  AppActionHandler.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

public final class AppActionHandler: ActionHandler {
    private let store: AppStore
    
    public init(actionBus: ActionSource, store: AppStore) {
        self.store = store
        actionBus.register(AppAction.self, handler: self)
    }
    
    public func handleAction(_ action: any Intent) async {
        guard let action = action as? AppAction else { return }
        switch action {
        case .setMultiPeerServiceActive(let value):
            await store.update { $0.isMultiPeerServiceActive = value }
        case .setBluetoothServiceActive(let value):
            await store.update { $0.isBluetoothServiceActive = value }
        case .peerDiscovered(let peer):
            await store.update { $0.discoveredPeers[peer.peerId] = peer }
        case .peerUpdated(let peer):
            await store.update { state in
                if state.discoveredPeers[peer.peerId] != nil {
                    state.discoveredPeers[peer.peerId] = peer
                } else if state.connectedPeers[peer.peerId] != nil {
                    state.connectedPeers[peer.peerId] = peer
                }
            }
        case .peerLost(let peer):
            await store.update { state in
                state.discoveredPeers.removeValue(forKey: peer.peerId)
                state.connectedPeers.removeValue(forKey: peer.peerId)
            }
        case .peerConnected(let peer):
            await store.update { state in
                state.connectedPeers[peer.peerId] = peer
                state.discoveredPeers.removeValue(forKey: peer.peerId)
            }
        case .peerDisconnected(let peer):
            await store.update { state in
                state.connectedPeers.removeValue(forKey: peer.peerId)
                state.discoveredPeers.removeValue(forKey: peer.peerId)
            }
        case .invitationReceived(let peer):
            await store.update { $0.pendingInvitation = peer }
        case .invitationCleared:
            await store.update { $0.pendingInvitation = nil }
        case .addToEventLog(let message):
            await store.update { $0.messages.append(message) }
        case .resetStorage:
            await store.update { state in
                state.connectedPeers.removeAll()
                state.discoveredPeers.removeAll()
            }
        }
    }
}
