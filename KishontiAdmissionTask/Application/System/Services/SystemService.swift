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
    
    private var observationTask: Task<Void, Never>?

    func start() {
        Log.debug("SystemService started")
        listenServerStatus()
    }

    deinit {
        observationTask?.cancel()
    }
}

private extension DefaultSystemService {
    func listenServerStatus() {
        Log.debug("listenServerStatus started")
        observationTask?.cancel()
        observationTask = Task {
            let stream = await store.stream(\.isAdvertising)
            for await state in stream {
                Log.debug("State Changed (SystemService)")
                if state.isAdvertising {
                    multiPeerService.startService()
                } else {
                    multiPeerService.stopService()
                }
            }
        }
    }
}
