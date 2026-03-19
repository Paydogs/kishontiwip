//
//  DIContainer.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import FactoryKit

extension Container {
    func preInit() {
        _ = appStore()
    }

    var actionBus: Factory<ActionBus> {
        Factory(self) { ActionBus() }
            .singleton
    }

    var actionDispatcher: Factory<ActionDispatcher> {
        Factory(self) { ActionDispatcher(self.actionBus()) }
            .singleton
    }

    var appStore: Factory<AppStore> {
        Factory(self) { AppStore(actionBus: self.actionBus(),
                                 persistence: UserDefaultsPersistence(key: "AppStore"),
                                 initial: AppState.initialValue()) }
        .singleton
    }

    var systemService: Factory<SystemService> {
        Factory(self) { DefaultSystemService() }
            .singleton
    }
    
    var multiPeerService: Factory<MultiPeerService> {
        Factory(self) { DefaultMultiPeerService() }
            .singleton
    }
}
