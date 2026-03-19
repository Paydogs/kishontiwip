//
//  AppStore.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

public final class AppStore: ActionHandler {
    private let store: BaseStore<AppState, AppAction>

    public init(actionBus: ActionSource, persistence: (any StatePersisting<AppState>)? = nil, initial: AppState = .initialValue()) {
        self.store = BaseStore(actionBus: actionBus, persistence: persistence, initialState: initial)
        actionBus.register(AppAction.self, handler: self)
    }

    public func stateStream() async -> AsyncStream<AppState> {
        await store.stateStream()
    }

    public func snapshot() async -> AppState {
        await store.currentState()
    }

    public func handleAction(_ action: any Intent) async {
        guard let action = action as? AppAction else { return }
        switch action {
        case .setAdvertising(let value):
            await store.update { $0.isAdvertising = value }
        case .setBrowsing(let value):
            await store.update { $0.isBrowsing = value }
        case .peerDiscovered(let peer):
            await store.update { $0.discoveredPeers[peer.peerId] = peer }
        case .peerLost(let peer):
            await store.update { $0.discoveredPeers.removeValue(forKey: peer.peerId) }
        case .peerConnected(let peer):
            await store.update { state in
                state.connectedPeers[peer.peerId] = peer
                state.discoveredPeers.removeValue(forKey: peer.peerId)
            }
        case .peerDisconnected(let peer):
            await store.update { $0.connectedPeers.removeValue(forKey: peer.peerId) }
        case .eventLogReceived(let message):
            await store.update { $0.messages.append(message) }
        }
    }
}
