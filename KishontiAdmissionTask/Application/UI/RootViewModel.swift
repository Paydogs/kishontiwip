//
//  RootViewModel.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import FactoryKit
import Foundation

final class RootViewModel: ObservableObject {
    private let store = Container.shared.appStore()
    private let dispatcher = Container.shared.actionDispatcher()
    
    @Published private(set) var isActive: Bool = false
    @Published private(set) var connectedPeers: [Peer] = []
    @Published private(set) var discoveredPeers: [Peer] = []
    @Published private(set) var pendingInvitation: Peer? = nil
    @Published private(set) var messages: [NetworkEventLogItem] = []
    @Published private(set) var heartbeats: [PeerIdentifier: [PeerHeartbeat]] = [:]
    
    private var observationTask: Task<Void, Never>?
    
    func load() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let stream = await self?.store.stateStream() else { return }
            for await state in stream {
                // due to lack of @Observable
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.connectedPeers = state.connectedPeers.compactMap { state.peerList[$0] }
                    self.isActive = state.isServiceActive
                    self.discoveredPeers = state.discoveredPeers.subtracting(state.connectedPeers).compactMap { state.peerList[$0] }
                    self.pendingInvitation = state.pendingInvitation.map { state.peerList[$0] ?? Peer(peerId: $0, name: $0) }
                    self.messages = Array(state.logs.sorted { $0.date > $1.date }.prefix(20))
                    self.heartbeats = state.heartbeats
                }
            }
        }
    }
    
    deinit {
        observationTask?.cancel()
    }
    
    func heartbeats(for peer: Peer) -> [PeerHeartbeat] {
        heartbeats[peer.peerId] ?? []
    }

    func toggleServiceActivity() {
        let action = AppAction.setServiceActive(!isActive)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }
    
    func pair(peer: Peer) {
        let action = DeviceAction.invite(peer)
        dispatcher.dispatch(action)
        dispatcher.dispatch(DeviceAction.createLogAction(from: action))
    }
    
    func unpair(peer: Peer) {
        let action = DeviceAction.unpair(peer)
        dispatcher.dispatch(action)
        dispatcher.dispatch(DeviceAction.createLogAction(from: action))
    }

    func acceptInvitation() {
        dispatcher.dispatch(DeviceAction.acceptInvitation)
    }

    func declineInvitation() {
        dispatcher.dispatch(DeviceAction.declineInvitation)
    }
    
    func resetLog() {
        dispatcher.dispatch(AppAction.resetLog)
    }

    func resetStorage() {
        dispatcher.dispatch(AppAction.resetStorage)
    }
}
