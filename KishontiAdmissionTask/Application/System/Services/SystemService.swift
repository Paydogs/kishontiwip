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
    private let multiPeerService = Container.shared.multiPeerService()
    private let bluetoothService = Container.shared.bluetoothService()
    private let deviceService = Container.shared.deviceManager()
    
    private var serviceStatusObservationTask: Task<Void, Never>?
    private var heartbeatSettingsObservationTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var pairingObservationTask: Task<Void, Never>?
//    private var reconnectObservationTask: Task<Void, Never>?
    private var inviteConfirmationTask: Task<Void, Never>?
    private var peerListObservationTask: Task<Void, Never>?
    private var pendingManualInvites: Set<String> = []

    public init(actionBus: ActionSource) {
        actionBus.register(DeviceAction.self, handler: self)
    }

    func start() {
        Log.debug("SystemService started")
        listenServiceStatusChanges()
        runHeartbeatTasks()
        listenPairedPeers()
//        listenForAutoReconnect()
        listenForInviteConfirmation()
        listenPeerListChanges()
    }
    
    deinit {
        serviceStatusObservationTask?.cancel()
        heartbeatSettingsObservationTask?.cancel()
        heartbeatTask?.cancel()
        pairingObservationTask?.cancel()
//        reconnectObservationTask?.cancel()
        inviteConfirmationTask?.cancel()
        peerListObservationTask?.cancel()
    }
}

extension DefaultSystemService: ActionHandler {
    public func handleAction(_ action: any Intent) async {
        guard let action = action as? DeviceAction else { return }
        switch action {
        case .invite(let peer):
            pendingManualInvites.insert(peer.peerId)
            multiPeerService.invite(peer: peer)
        case .unpair(let peer):
            multiPeerService.send(action: .unpair, to: peer)
            multiPeerService.disconnect(peer: peer)
            bluetoothService.disconnect(peer: peer)
            deviceService.unpair(peerId: peer.peerId)
        case .remoteUnpair(let peer):
            multiPeerService.disconnect(peer: peer)
            bluetoothService.disconnect(peer: peer)
            deviceService.unpair(peerId: peer.peerId)
        case .acceptInvitation:
            if let peerId = await store.currentState.pendingInvitation {
                pendingManualInvites.insert(peerId)
            }
            multiPeerService.acceptInvitation()
        case .declineInvitation:
            multiPeerService.declineInvitation()
        }
    }
}

private extension DefaultSystemService {
    func runHeartbeatTasks() {
        heartbeatSettingsObservationTask?.cancel()
        heartbeatSettingsObservationTask = Task {
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
            var knownPairedIds: Set<String> = []
            let stream = await store.stream(\.pairedPeerIds)
            for await state in stream {
                let currentPairs = state.pairedPeerIds
                let newPeers = currentPairs.subtracting(knownPairedIds)
                let unpairedPeers = knownPairedIds.subtracting(currentPairs)
                knownPairedIds = currentPairs
                
                for peerId in unpairedPeers {
                    guard let peer = state.peerList[peerId] else { continue }
                    bluetoothService.disconnect(peer: peer)
                }
                
                for peerId in newPeers {
                    guard let peer = state.peerList[peerId] else { continue }
                    bluetoothService.reconnectKnownPeer(peer: peer)
                    multiPeerService.reconnectKnownPeer(peer: peer)
                }
//                let added = state.pairedPeerIds.subtracting(knownPairedIds)
//                let removed = knownPairedIds.subtracting(state.pairedPeerIds)
//                knownPairedIds = state.pairedPeerIds
//                for peerId in removed {
//                    let peer = state.peerList[peerId] ?? Peer(peerId: peerId, name: peerId)
//                    bluetoothService.disconnect(peer: peer)
//                }
//                for peerId in added {
//                    let peer = state.peerList[peerId] ?? Peer(peerId: peerId, name: peerId)
//                    bluetoothService.allowReconnect(peer: peer)
//                    if state.discoveredPeers.contains(peerId) {
//                        multiPeerService.invite(peer: peer)
//                    }
//                }
            }
        }
    }

//    func listenForAutoReconnect() {
//        reconnectObservationTask?.cancel()
//        reconnectObservationTask = Task {
//            let stream = await store.stream(\.discoveredPeers, \.pairedPeerIds)
//            for await state in stream {
//                for peerId in state.discoveredPeers {
//                    guard state.pairedPeerIds.contains(peerId),
//                          let peer = state.peerList[peerId] else { continue }
//                    Log.debug("Auto-reconnecting to \(peer.name)")
//                    multiPeerService.invite(peer: peer)
//                }
//            }
//        }
//    }

    // If a new connectedPeer appears, remove the
    func listenForInviteConfirmation() {
        inviteConfirmationTask?.cancel()
        inviteConfirmationTask = Task {
            let stream = await store.stream(\.connectedPeers)
            for await state in stream {
                for peerId in state.connectedPeers {
                    let isPendingManualInvite = pendingManualInvites.contains(peerId)
                    guard isPendingManualInvite else { continue }

                    pendingManualInvites.remove(peerId)
                    deviceService.pair(peerId: peerId)
                }
            }
        }
    }

    func listenPeerListChanges() {
        peerListObservationTask?.cancel()
        peerListObservationTask = Task {
            let stream = await store.stream(\.peerList)
            for await state in stream {
                deviceService.updatePeerList(state.peerList)
            }
        }
    }

    func listenServiceStatusChanges() {
        serviceStatusObservationTask?.cancel()
        serviceStatusObservationTask = Task {
            let stream = await store.stream(\.isServiceActive)
            for await state in stream {
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
