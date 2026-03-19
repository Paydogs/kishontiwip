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
    
    public init(actionBus: ActionSource) {
        actionBus.register(DeviceAction.self, handler: self)
    }
    
    func start() {
        Log.debug("SystemService started")
        listenStoreChanges()
    }
    
    deinit {
        observationTask?.cancel()
    }
}

extension DefaultSystemService: ActionHandler {
    public func handleAction(_ action: any Intent) async {
        guard let action = action as? DeviceAction else { return }
        switch action {
        case .invite(let peer):
            multiPeerService.invite(peer: peer)
        case .disconnect(let peer):
            multiPeerService.disconnect(peer: peer)
        case .acceptInvitation:
            multiPeerService.acceptInvitation()
        case .declineInvitation:
            multiPeerService.declineInvitation()
        }
    }
}

private extension DefaultSystemService {
    func listenStoreChanges() {
        Log.debug("listenServerStatus started")
        observationTask?.cancel()
        observationTask = Task {
            let stream = await store.stream(\.isMultiPeerServiceActive, \.isBluetoothServiceActive)
            for await state in stream {
                Log.debug("State Changed (SystemService)")
                if state.isMultiPeerServiceActive {
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
