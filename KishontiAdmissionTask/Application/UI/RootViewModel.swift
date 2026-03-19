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
    
    private var observationTask: Task<Void, Never>?
    
    func load() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let stream = await self?.store.stateStream() else { return }
            for await state in stream {
                // due to lack of @Observable
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isActive = state.isMultiPeerServiceActive
                    self.connectedPeers = Array(state.connectedPeers.values)
                    self.discoveredPeers = Array(state.discoveredPeers.values)
                    self.pendingInvitation = state.pendingInvitation
                    self.messages = Array(state.messages.sorted { $0.date > $1.date }.prefix(20))
                }
            }
        }
    }
    
    deinit {
        observationTask?.cancel()
    }
    
    func toggleServiceActivity() {
        let action = AppAction.setMultiPeerServiceActive(!isActive)
        dispatcher.dispatch(action)
        dispatcher.dispatch(AppAction.createLogAction(from: action))
    }
    
    func connect(peer: Peer) {
        let action = DeviceAction.invite(peer)
        dispatcher.dispatch(action)
        dispatcher.dispatch(DeviceAction.createLogAction(from: action))
    }
    
    func disconnect(peer: Peer) {
        let action = DeviceAction.disconnect(peer)
        dispatcher.dispatch(action)
        dispatcher.dispatch(DeviceAction.createLogAction(from: action))
    }

    func acceptInvitation() {
        dispatcher.dispatch(DeviceAction.acceptInvitation)
    }

    func declineInvitation() {
        dispatcher.dispatch(DeviceAction.declineInvitation)
    }
}
