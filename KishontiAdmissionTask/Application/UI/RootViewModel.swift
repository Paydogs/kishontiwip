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
    
    @Published private(set) var isAdvertising: Bool = false
    @Published private(set) var connectedPeers: [Peer] = []
    @Published private(set) var discoveredPeers: [Peer] = []
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
                    self.isAdvertising = state.isAdvertising
                    self.connectedPeers = Array(state.connectedPeers.values)
                    self.discoveredPeers = Array(state.discoveredPeers.values)
                    self.messages = Array(state.messages.sorted { $0.date > $1.date }.prefix(20))
                }
            }
        }
    }
    
    deinit {
        observationTask?.cancel()
    }
    
    func toggleAdvertising(_ active: Bool) {
        dispatcher.dispatch(AppAction.setAdvertising(active))
        
        dispatcher.dispatch(AppAction.eventLogReceived(.init(
            primaryText: "Your app",
            secondaryText: active ? "started watching" : "stopped watching",
            date: Date(),
            severity: active ? .Good : .Error)
        ))
    }
}
