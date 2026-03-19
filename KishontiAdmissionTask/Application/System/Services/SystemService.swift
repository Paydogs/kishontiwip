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
    private var observationTask: Task<Void, Never>?

    func start() {
        Log.debug("SystemService started")
    }

    deinit {
        observationTask?.cancel()
    }
}
