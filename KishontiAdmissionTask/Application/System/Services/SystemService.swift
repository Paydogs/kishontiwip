//
//  SystemService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation
import UIKit
import FactoryKit

protocol SystemService: Actor {
    /// Wires up all store observation tasks: service activation, heartbeat scheduling, pairing changes, auto-reconnect, foreground resume, invite confirmation, and peer-list sync.
    func start()
}

actor DefaultSystemService: SystemService {
    // MARK: DI Injections
    private let store = Container.shared.appStore()
    private let multiPeerService = Container.shared.multiPeerService()
    private let bluetoothService = Container.shared.bluetoothService()
    private let deviceService = Container.shared.deviceManager()

    // MARK: Async tasks
    private var serviceStatusObservationTask: Task<Void, Never>?
    private var heartbeatSettingsObservationTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var pairingObservationTask: Task<Void, Never>?
    private var reconnectObservationTask: Task<Void, Never>?
    private var foregroundObservationTask: Task<Void, Never>?
    private var inviteConfirmationTask: Task<Void, Never>?
    private var peerListObservationTask: Task<Void, Never>?

    // MARK: Local variables
    private var pendingManualInvites: Set<String> = []

    public init(actionBus: ActionSource) {
        actionBus.register(DeviceAction.self, handler: self)
    }

    func start() {
        Log.debug("SystemService started")
        listenServiceStatusChanges()
        runHeartbeatTasks()
        listenPairedPeers()
        listenForAutoReconnect()
        listenForInviteConfirmation()
        listenPeerListChanges()
        listenForForegroundReentry()
    }
    
    deinit {
        serviceStatusObservationTask?.cancel()
        heartbeatSettingsObservationTask?.cancel()
        heartbeatTask?.cancel()
        pairingObservationTask?.cancel()
        reconnectObservationTask?.cancel()
        foregroundObservationTask?.cancel()
        inviteConfirmationTask?.cancel()
        peerListObservationTask?.cancel()
    }
}

// MARK: DeviceAction handling
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
            multiPeerService.rediscover()
            bluetoothService.rediscover()
        case .remoteUnpair(let peer):
            multiPeerService.disconnect(peer: peer)
            bluetoothService.disconnect(peer: peer)
            deviceService.unpair(peerId: peer.peerId)
            multiPeerService.rediscover()
            bluetoothService.rediscover()
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

// MARK: Task implementations
private extension DefaultSystemService {
    ///
    /// Handles the service start and stop
    ///
    /// Observes `isServiceActive`
    ///
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
    
    ///
    /// Runs a periodic task that fires heartbeats on both transports at the configured interval.
    /// Handles if the interval change.
    /// Cancels the task when the service is inactive or interval is zero.
    ///
    /// Observes `heartbeatInterval` and `isServiceActive`;
    ///
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
                        let currentState = await store.currentState
                        for peerId in currentState.pairedPeerIds {
                            guard let peer = currentState.peerList[peerId],
                                  peer.activeTransports.isEmpty else { continue }
                            deviceService.heartbeatDetected(peerId, .none(Date()))
                        }
                    }
                }
            }
        }
    }

    ///
    /// Watches for pairing changes.
    /// Disconnects newly unpaired peers via Bluetooth.
    /// Enables Bluetooth reconnect for newly paired peers.
    ///
    /// Observes `pairedPeerIds`;
    ///
    func listenPairedPeers() {
        pairingObservationTask?.cancel()
        pairingObservationTask = Task {
            var knownPairedIds: Set<String> = []
            
            let stream = await store.stream(\.pairedPeerIds)
            for await state in stream {
                let currentPairs = state.pairedPeerIds
                multiPeerService.updatePairedPeers(currentPairs)
                
                let newPeers = currentPairs.subtracting(knownPairedIds)
                let unpairedPeers = knownPairedIds.subtracting(currentPairs)
                knownPairedIds = currentPairs

                for peerId in unpairedPeers {
                    guard let peer = state.peerList[peerId] else { continue }
                    bluetoothService.disconnect(peer: peer)
                }

                guard state.isServiceActive else { continue }

                for peerId in newPeers {
                    guard let peer = state.peerList[peerId] else { continue }
                    bluetoothService.reconnectKnownPeer(peer: peer)
                }
            }
        }
    }

    ///
    /// Automatically re-invites any discovered peer that is already paired.
    ///
    /// Observes `discoveredPeers` and `pairedPeerIds`;
    ///
    func listenForAutoReconnect() {
        reconnectObservationTask?.cancel()
        reconnectObservationTask = Task {
            let stream = await store.stream(\.discoveredPeers, \.pairedPeerIds)
            for await state in stream {
                guard state.isServiceActive else { continue }
                
                for peerId in state.discoveredPeers {
                    guard state.pairedPeerIds.contains(peerId),
                          let peer = state.peerList[peerId] else { continue }
                    Log.debug("reconnectObservationTask Auto-reconnecting to \(peer.name)")
                    multiPeerService.reconnectKnownPeer(peer: peer)
                }
            }
        }
    }

    ///
    /// Re-invites all paired peers on Multipeer when the service is active, recovering connections dropped while the app was backgrounded.
    ///
    /// Listens for `didBecomeActive` notifications
    ///
    func listenForForegroundReentry() {
        foregroundObservationTask?.cancel()
        foregroundObservationTask = Task {
            let notifications = NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification)
            for await _ in notifications {
                let state = await store.currentState
                guard state.isServiceActive else { continue }
                multiPeerService.rediscover()
                bluetoothService.rediscover()
                for peerId in state.pairedPeerIds {
                    guard let peer = state.peerList[peerId] else { continue }
                    Log.debug("foregroundObservationTask Auto-reconnecting to \(peer.name)")
                    multiPeerService.reconnectKnownPeer(peer: peer)
                }
            }
        }
    }

    ///
    /// When a peer from `pendingManualInvites` connects, removes it from the pending set and pairs it via the device service.
    ///
    /// Observes `connectedPeers`
    ///
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

    ///
    /// Forwards every update to the device service to keep its local cache in sync.
    ///
    /// Observes `peerList`
    ///
    func listenPeerListChanges() {
        peerListObservationTask?.cancel()
        peerListObservationTask = Task {
            let stream = await store.stream(\.peerList)
            for await state in stream {
                deviceService.updatePeerList(state.peerList)
            }
        }
    }
}
