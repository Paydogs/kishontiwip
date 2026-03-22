//
//  SystemService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation
import FactoryKit

protocol SystemService: Actor {
    func start()
}

actor DefaultSystemService: SystemService {
    private let store = Container.shared.appStore()
    private let deviceManager = Container.shared.deviceManager()
    private let multiPeerService = Container.shared.multiPeerService()
    private let bluetoothService = Container.shared.bluetoothService()
    
    private var observationTask: Task<Void, Never>?
    private var heartbeatObservationTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var pairingObservationTask: Task<Void, Never>?
    private var reconnectObservationTask: Task<Void, Never>?
    private var pairedPeerIds: Set<String> = []

    public init(actionBus: ActionSource) {
        actionBus.register(DeviceAction.self, handler: self)
    }

    func start() {
        Log.debug("SystemService started")
        listenStoreChanges()
        listenHeartbeatInterval()
        listenPairedPeers()
        listenForAutoReconnect()
    }
    
    deinit {
        observationTask?.cancel()
        heartbeatObservationTask?.cancel()
        heartbeatTask?.cancel()
        pairingObservationTask?.cancel()
        reconnectObservationTask?.cancel()
    }
}

extension DefaultSystemService: ActionHandler {
    public func handleAction(_ action: any Intent) async {
        guard let action = action as? DeviceAction else { return }
        switch action {
        case .invite(let peer):
            multiPeerService.invite(peer: peer)
        case .disconnect(let peer):
            pairedPeerIds.remove(peer.peerId)
            multiPeerService.disconnect(peer: peer)
            bluetoothService.disconnect(peer: peer)
            await store.update { state in
                state.connectedPeers.removeValue(forKey: peer.peerId)
                state.discoveredPeers.removeValue(forKey: peer.peerId)
            }
        case .acceptInvitation:
            multiPeerService.acceptInvitation()
        case .declineInvitation:
            multiPeerService.declineInvitation()
        }
    }
}

private extension DefaultSystemService {
    func listenHeartbeatInterval() {
        heartbeatObservationTask?.cancel()
        heartbeatObservationTask = Task {
            let stream = await store.stream(\.heartbeatInterval, \.isServiceActive)
            for await state in stream {
                heartbeatTask?.cancel()
                guard state.isServiceActive, state.heartbeatInterval > 0 else { continue }
                let interval = state.heartbeatInterval
                heartbeatTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(interval))
                        guard !Task.isCancelled else { return }
                        multiPeerService.sendHeartbeats()
                        bluetoothService.sendHeartbeats()
                    }
                }
            }
        }
    }

    func listenPairedPeers() {
        pairingObservationTask?.cancel()
        pairingObservationTask = Task {
            let stream = await store.stream(\.connectedPeers)
            for await state in stream {
                let currentPeerIds = Set(state.connectedPeers.keys)
                let newPeers = currentPeerIds.subtracting(pairedPeerIds)
                for peerId in newPeers {
                    pairedPeerIds.insert(peerId)
                    if let peer = state.connectedPeers[peerId] {
                        bluetoothService.allowReconnect(peer: peer)
                    }
                }
            }
        }
    }

    func listenForAutoReconnect() {
        reconnectObservationTask?.cancel()
        reconnectObservationTask = Task {
            let stream = await store.stream(\.discoveredPeers)
            for await state in stream {
                for (peerId, peer) in state.discoveredPeers {
                    guard let paired = state.connectedPeers[peerId],
                          paired.activeTransports.isEmpty else { continue }
                    Log.debug("Auto-reconnecting to \(peer.name)")
                    multiPeerService.invite(peer: peer)
                }
            }
        }
    }

    func listenStoreChanges() {
        Log.debug("listenServerStatus started")
        observationTask?.cancel()
        observationTask = Task {
            let stream = await store.stream(\.isServiceActive)
            for await state in stream {
                Log.debug("State Changed (SystemService)")
                if state.isServiceActive {
                    multiPeerService.startService()
                    bluetoothService.startService()
                } else {
                    multiPeerService.stopService()
                    bluetoothService.stopService()
                }
            }
        }
    }
}
