//
//  DIContainer.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import FactoryKit

extension Container {
    func preInit() {
        _ = appActionHandler()
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
                                 initialState: AppState()) }
        .singleton
    }

    var appActionHandler: Factory<AppActionHandler> {
        Factory(self) { AppActionHandler(actionBus: self.actionBus(), store: self.appStore()) }
            .singleton
    }

    var systemService: Factory<SystemService> {
        Factory(self) { DefaultSystemService(actionBus: self.actionBus()) }
            .singleton
    }
    
    var deviceManager: Factory<DeviceManaging> {
        Factory(self) { DefaultDeviceManager(dispatcher: self.actionDispatcher()) }
            .singleton
    }
    
    var multiPeerService: Factory<MultiPeerService> {
        Factory(self) { DefaultMultiPeerService(deviceManager: self.deviceManager()) }
            .singleton
    }
    
    var bluetoothService: Factory<BluetoothConnectivityService> {
        Factory(self) { DefaultBluetoothConnectivityService(deviceManager: self.deviceManager()) }
            .singleton
    }
}
