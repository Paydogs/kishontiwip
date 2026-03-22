//
//  BluetoothConnectivityService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation
import CoreBluetooth

protocol BluetoothConnectivityService {
    func startService()
    func stopService()
    func sendHeartbeats()
    func disconnect(peer: Peer)
    func allowReconnect(peer: Peer)
}

final class DefaultBluetoothConnectivityService: NSObject, BluetoothConnectivityService {
    private let deviceManager: DeviceManaging
    private let serviceUUID = CBUUID(string: Constants.bluetoothServiceUUID)
    private let characteristicUUID = CBUUID(string: Constants.bluetoothCharacteristicUUID)

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var characteristic: CBMutableCharacteristic?

    /// Peripherals pending name resolution (keyed by CBPeripheral)
    private var pendingPeripherals: [CBPeripheral: Void] = [:]
    /// Resolved peers (keyed by peerId i.e. DeviceIdentity.peerName)
    private var resolvedPeripherals: [String: CBPeripheral] = [:]
    /// Reverse lookup: peripheral → resolved peerId
    private var peripheralPeerIds: [CBPeripheral: String] = [:]
    /// Connected resolved peers
    private var connectedPeerIds: Set<String> = []
    /// Peers paired via MP — BT only auto-connects to these
    private var pairedPeers: Set<String> = []
    private var isActive = false

    init(deviceManager: DeviceManaging) {
        self.deviceManager = deviceManager
        super.init()
    }

    func startService() {
        guard !isActive else { return }
        isActive = true
        Log.debug("BT starting")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func stopService() {
        guard isActive else { return }
        isActive = false
        Log.debug("BT stopping")

        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()

        for peerId in connectedPeerIds {
            deviceManager.peerDisconnected(Peer(peerId: peerId, name: peerId), via: .bluetooth)
        }
        for (peripheral, _) in pendingPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        for (_, peripheral) in resolvedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }

        pendingPeripherals.removeAll()
        resolvedPeripherals.removeAll()
        peripheralPeerIds.removeAll()
        connectedPeerIds.removeAll()
        centralManager = nil
        peripheralManager = nil
        characteristic = nil
    }

    func sendHeartbeats() {
        for peerId in connectedPeerIds {
            deviceManager.heartbeatDetected(Peer(peerId: peerId, name: peerId), via: .bluetooth)
        }
    }

    func disconnect(peer: Peer) {
        pairedPeers.remove(peer.peerId)
        guard let peripheral = resolvedPeripherals[peer.peerId] else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
        Log.debug("BT disconnected \(peer.name)")
    }

    func allowReconnect(peer: Peer) {
        pairedPeers.insert(peer.peerId)
        // If already discovered but rejected earlier, connect now
        if let peripheral = resolvedPeripherals[peer.peerId], !connectedPeerIds.contains(peer.peerId) {
            centralManager?.connect(peripheral, options: nil)
        }
    }
}

// MARK: - Peripheral Manager (Advertising)
extension DefaultBluetoothConnectivityService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn, isActive else { return }

        let char = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read],
            value: DeviceIdentity.peerName.data(using: .utf8),
            permissions: [.readable]
        )
        self.characteristic = char

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [char]
        peripheral.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            Log.error("BT add service failed: \(error.localizedDescription)")
            return
        }
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: DeviceIdentity.peerName
        ])
        Log.debug("BT advertising as \(DeviceIdentity.peerName)")
    }
}

// MARK: - Central Manager (Scanning & Connecting)
extension DefaultBluetoothConnectivityService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn, isActive else { return }
        Log.debug("BT scanning")
        central.scanForPeripherals(withServices: [serviceUUID], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Skip if already tracking this peripheral
        guard pendingPeripherals[peripheral] == nil,
              peripheralPeerIds[peripheral] == nil else { return }

        Log.debug("BT discovered peripheral: \(peripheral.identifier)")
        pendingPeripherals[peripheral] = ()
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.debug("BT connected peripheral: \(peripheral.identifier)")

        // Already resolved from a previous connection — just mark connected
        if let peerId = peripheralPeerIds[peripheral], pairedPeers.contains(peerId) {
            connectedPeerIds.insert(peerId)
            let peer = Peer(peerId: peerId, name: peerId)
            deviceManager.peerDiscovered(peer, via: .bluetooth)
            deviceManager.peerConnected(peer, via: .bluetooth)
            return
        }

        // First time — resolve name via characteristic
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log.error("BT connect failed: \(peripheral.identifier) \(error?.localizedDescription ?? "")")
        // Retry if still active
        if isActive {
            central.connect(peripheral, options: nil)
        } else {
            pendingPeripherals.removeValue(forKey: peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let peerId = peripheralPeerIds[peripheral]

        if let peerId, connectedPeerIds.contains(peerId) {
            Log.debug("BT disconnected: \(peerId)")
            connectedPeerIds.remove(peerId)
            deviceManager.peerDisconnected(Peer(peerId: peerId, name: peerId), via: .bluetooth)
        } else {
            pendingPeripherals.removeValue(forKey: peripheral)
        }

        // Auto-reconnect only if still paired
        if isActive, let peerId, pairedPeers.contains(peerId) {
            central.connect(peripheral, options: nil)
        }
    }
}

// MARK: - Peripheral Delegate (name resolution)
extension DefaultBluetoothConnectivityService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars where char.uuid == characteristicUUID {
            peripheral.readValue(for: char)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == characteristicUUID,
              let data = characteristic.value,
              let peerName = String(data: data, encoding: .utf8) else { return }

        // Already resolved
        if let existing = peripheralPeerIds[peripheral], existing == peerName { return }

        Log.debug("BT resolved: \(peerName)")
        pendingPeripherals.removeValue(forKey: peripheral)
        peripheralPeerIds[peripheral] = peerName
        resolvedPeripherals[peerName] = peripheral

        guard pairedPeers.contains(peerName) else {
            // Not paired via MP — disconnect
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }

        connectedPeerIds.insert(peerName)
        let peer = Peer(peerId: peerName, name: peerName)
        deviceManager.peerDiscovered(peer, via: .bluetooth)
        deviceManager.peerConnected(peer, via: .bluetooth)
    }
}
