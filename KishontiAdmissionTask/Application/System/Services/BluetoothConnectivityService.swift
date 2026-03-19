//
//  BluetoothConnectivityService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation

protocol BluetoothConnectivityService {
    func startService()
    func stopService()
}

// MARK: - PeerService
final class DefaultBluetoothConnectivityService: NSObject, BluetoothConnectivityService {
    private var isActive = false
    private let deviceManager: DeviceManaging
    
    init(deviceManager: DeviceManaging) {
        self.deviceManager = deviceManager
        super.init()
    }
    
    func startService() {
        guard !isActive else { return }
        Log.debug("Starting Bluetooth service")

        Log.debug("Bluetooth service started")
    }
    
    func stopService() {
        guard isActive else { return }
        Log.debug("Stopping Bluetooth service")

        Log.debug("Bluetooth service stopped")
    }
}
