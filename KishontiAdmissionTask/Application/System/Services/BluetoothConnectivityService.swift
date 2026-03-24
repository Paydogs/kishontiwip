//
//  BluetoothConnectivityService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation
import CoreBluetooth

protocol BluetoothConnectivityService {
    /// Initializes the `CBCentralManager` and `CBPeripheralManager`, begins scanning and advertising.
    func startService()

    /// Stops and restarts the central scan, forcing rediscovery of nearby peripherals.
    func rediscover()

    /// Stops scanning/advertising, cancels all peripheral connections, and clears internal state.
    func stopService()

    /// Notifies the device manager of a heartbeat for each connected peer and pushes the local peer name via the notify characteristic.
    func sendHeartbeats()

    /// Cancels the BLE connection to `peer` and removes it from the paired set, preventing auto-reconnect.
    func disconnect(peer: Peer)

    /// Marks `peer` as paired and immediately connects if its peripheral has already been resolved.
    func reconnectKnownPeer(peer: Peer)
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
    /// Heartbeat characteristic per peripheral (for re-subscribing after reconnect)
    private var peripheralCharacteristics: [CBPeripheral: CBCharacteristic] = [:]
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
        Log.debug("Bluetooth service starting")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func stopService() {
        guard isActive else { return }
        isActive = false
        Log.debug("Bluetooth service stopping")

        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()

        Log.debug("Dropping bluetooth transports")
        for peerId in connectedPeerIds {
            deviceManager.peerDisconnected(peerId, via: .bluetooth)
        }
        Log.debug("Canceling every peripheral connection")
        for (peripheral, _) in pendingPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        Log.debug("Canceling every resolved connection")
        for (_, peripheral) in resolvedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }

        pendingPeripherals.removeAll()
        resolvedPeripherals.removeAll()
        peripheralPeerIds.removeAll()
        peripheralCharacteristics.removeAll()
        connectedPeerIds.removeAll()
        centralManager = nil
        peripheralManager = nil
        characteristic = nil
    }

    func sendHeartbeats() {
        for peerId in connectedPeerIds {
            deviceManager.heartbeatDetected(peerId, .bluetooth(Date()))
        }
        guard let char = characteristic,
              let data = DeviceIdentity.peerName.data(using: .utf8) else { return }
        peripheralManager?.updateValue(data, for: char, onSubscribedCentrals: nil)
    }

    func disconnect(peer: Peer) {
        pairedPeers.remove(peer.peerId)
        guard let peripheral = resolvedPeripherals[peer.peerId] else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
        deviceManager.peerDisconnected(peer.peerId, via: .bluetooth)
        Log.debug("Bluetooth service disconnected [disconnect] from \(peer.name)")
    }

    func rediscover() {
        guard isActive, let central = centralManager, central.state == .poweredOn else { return }
        Log.info("Bluetooth service rediscovering")
        central.stopScan()
        central.scanForPeripherals(withServices: [serviceUUID], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    func reconnectKnownPeer(peer: Peer) {
        pairedPeers.insert(peer.peerId)
        guard !connectedPeerIds.contains(peer.peerId),
              let peripheral = resolvedPeripherals[peer.peerId] else { return }
        if peripheral.state == .connected {
            // Already physically connected but not yet promoted — promote now
            connectedPeerIds.insert(peer.peerId)
            deviceManager.peerDiscovered(peer.peerId, via: .bluetooth)
            deviceManager.peerConnected(peer.peerId, via: .bluetooth)
        } else {
            centralManager?.connect(peripheral, options: nil)
        }
    }
}

// MARK: - Peripheral Manager (Advertising)
extension DefaultBluetoothConnectivityService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // added 2026-03-24
        if peripheral.state == .poweredOff {
            for peerId in connectedPeerIds {
                deviceManager.peerDisconnected(peerId, via: .bluetooth)
            }
            connectedPeerIds.removeAll()
        }
        // added 2026-03-24
        guard peripheral.state == .poweredOn, isActive else { return }

        let char = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        self.characteristic = char

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [char]
        peripheral.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == characteristicUUID,
              let data = DeviceIdentity.peerName.data(using: .utf8) else {
            peripheral.respond(to: request, withResult: .requestNotSupported)
            return
        }
        request.value = data
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            Log.error("Bluetooth service add service failed: \(error.localizedDescription)")
            return
        }
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: DeviceIdentity.peerName
        ])
        Log.debug("Bluetooth service advertising as \(DeviceIdentity.peerName)")
    }
}

// MARK: - Central Manager (Scanning & Connecting)
extension DefaultBluetoothConnectivityService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn, isActive else { return }
        Log.debug("Bluetooth service scanning")
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

        Log.debug("Bluetooth service discovered peripheral: \(peripheral.identifier)")
        pendingPeripherals[peripheral] = ()
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.debug("Bluetooth service connected to peripheral: \(peripheral.identifier)")

        // Already resolved from a previous connection — just mark connected and re-subscribe
        if let peerId = peripheralPeerIds[peripheral], pairedPeers.contains(peerId) {
            connectedPeerIds.insert(peerId)
            deviceManager.peerDiscovered(peerId, via: .bluetooth)
            deviceManager.peerConnected(peerId, via: .bluetooth)
            if let char = peripheralCharacteristics[peripheral] {
                peripheral.setNotifyValue(true, for: char)
            } else {
                peripheral.discoverServices([serviceUUID])
            }
            return
        }

        // First time — resolve name via characteristic
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log.error("Bluetooth service connection failed: \(peripheral.identifier) \(error?.localizedDescription ?? "")")
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
            Log.debug("Bluetooth service disconnected from \(peerId)")
            connectedPeerIds.remove(peerId)
            deviceManager.peerDisconnected(peerId, via: .bluetooth)
        } else {
            pendingPeripherals.removeValue(forKey: peripheral)
        }

        // Queue reconnect — CoreBluetooth holds the request until the peripheral is available again
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
            peripheralCharacteristics[peripheral] = char
            peripheral.readValue(for: char)
            peripheral.setNotifyValue(true, for: char)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        guard invalidatedServices.contains(where: { $0.uuid == serviceUUID }) else { return }
        Log.debug("Bluetooth service: peer removed service, disconnecting \(peripheral.identifier)")
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == characteristicUUID,
              let data = characteristic.value,
              let peerName = String(data: data, encoding: .utf8) else { return }

        // Already resolved — this is a heartbeat notification from the peer
        if let peerId = peripheralPeerIds[peripheral] {
            deviceManager.heartbeatDetected(peerId, .bluetooth(Date()))
            return
        }

        // First time — name resolution
        Log.debug("Bluetooth service resolved the name: \(peerName)")
        pendingPeripherals.removeValue(forKey: peripheral)
        peripheralPeerIds[peripheral] = peerName
        resolvedPeripherals[peerName] = peripheral

        guard pairedPeers.contains(peerName) else {
            // Not paired yet — stay connected, reconnectKnownPeer will promote when pairing arrives
            return
        }

        connectedPeerIds.insert(peerName)
        deviceManager.peerDiscovered(peerName, via: .bluetooth)
        deviceManager.peerConnected(peerName, via: .bluetooth)
    }
}
