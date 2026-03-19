//
//  GeneratedBluetoothConnectivityService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import Foundation
import CoreBluetooth
import UIKit

// MARK: - Constants
private enum BTConstants {
    static let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890") // App specific constant UUID
    static let pingCharacteristicUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891") // App specific constant UUID
    static let pingInterval: TimeInterval = 5.0
    static let centralRestoreKey = "com.kishonti.bt-central"
    static let peripheralRestoreKey = "com.kishonti.bt-peripheral"
}

// MARK: - Per-peer tracking
private struct ConnectedPeerState {
    let peer: Peer
    let peripheral: CBPeripheral
    let connectionStart: Date
    var lastPingSent: Date?
    var lastPingReceived: Date?
    var pingCharacteristic: CBCharacteristic?
}

// MARK: - Protocol
protocol GeneratedBluetoothConnectivityService {
    func startService()
    func stopService()
}

// MARK: - Implementation
final class DefaultGeneratedBluetoothConnectivityService: NSObject, GeneratedBluetoothConnectivityService {
    private let dispatcher: ActionDispatching
    private let myName: String = UIDevice.current.name

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var pingCharacteristic: CBMutableCharacteristic?
    private var connectedPeers: [UUID: ConnectedPeerState] = [:]
    private var pingTask: Task<Void, Never>?
    private var isActive = false

    init(dispatcher: ActionDispatching) {
        self.dispatcher = dispatcher
        super.init()
    }

    func startService() {
        guard !isActive else { return }
        Log.debug("Starting Bluetooth service")
        isActive = true
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: BTConstants.centralRestoreKey]
        )
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: BTConstants.peripheralRestoreKey]
        )
        startPingLoop()
        Log.debug("Bluetooth service started")
    }

    func stopService() {
        guard isActive else { return }
        Log.debug("Stopping Bluetooth service")
        isActive = false
        pingTask?.cancel()
        pingTask = nil
        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        centralManager = nil
        peripheralManager = nil
        connectedPeers.removeAll()
        Log.debug("Bluetooth service stopped")
    }
}

// MARK: - Ping loop
private extension DefaultGeneratedBluetoothConnectivityService {
    func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(BTConstants.pingInterval))
                guard !Task.isCancelled else { return }
                self?.pingAllPeers()
            }
        }
    }

    func pingAllPeers() {
        let now = Date()
        for (id, var state) in connectedPeers {
            guard let char = state.pingCharacteristic else { continue }
            var timestamp = now.timeIntervalSince1970
            let data = Data(bytes: &timestamp, count: MemoryLayout<Double>.size)
            state.lastPingSent = now
            connectedPeers[id] = state
            state.peripheral.writeValue(data, for: char, type: .withResponse)
            Log.debug("BT ping → \(state.peer.name)")
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension DefaultGeneratedBluetoothConnectivityService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(
            withServices: [BTConstants.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        Log.debug("BT Central: scanning")
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.forEach {
            $0.delegate = self
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name
            ?? "Unknown"
        let peer = Peer(peerId: peripheral.identifier.uuidString, name: name)
        Log.debug("BT discovered: \(name)")
        dispatcher.dispatch(AppAction.peerDiscovered(peer))
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let peer = Peer(peerId: peripheral.identifier.uuidString, name: peripheral.name ?? "Unknown")
        Log.debug("BT connected: \(peer.name)")
        peripheral.delegate = self
        connectedPeers[peripheral.identifier] = ConnectedPeerState(
            peer: peer,
            peripheral: peripheral,
            connectionStart: Date()
        )
        peripheral.discoverServices([BTConstants.serviceUUID])
        dispatcher.dispatch(AppAction.peerConnected(peer))
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        guard let state = connectedPeers.removeValue(forKey: peripheral.identifier) else { return }
        let duration = Date().timeIntervalSince(state.connectionStart)
        Log.debug("BT disconnected: \(state.peer.name), was connected \(Int(duration))s")
        let log = NetworkEventLogItem(
            primaryText: "BT disconnected: \(state.peer.name)",
            secondaryText: "Connected for \(Int(duration))s",
            date: Date(),
            severity: .warning
        )
        Task {
            dispatcher.dispatch(AppAction.peerDisconnected(state.peer))
            dispatcher.dispatch(AppAction.addToEventLog(log))
        }
        if isActive {
            central.connect(peripheral)
        }
    }
}

// MARK: - CBPeripheralDelegate
extension DefaultGeneratedBluetoothConnectivityService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == BTConstants.serviceUUID })
        else { return }
        peripheral.discoverCharacteristics([BTConstants.pingCharacteristicUUID], for: service)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        service.characteristics?
            .filter { $0.uuid == BTConstants.pingCharacteristicUUID }
            .forEach { char in
                connectedPeers[peripheral.identifier]?.pingCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
            }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == BTConstants.pingCharacteristicUUID,
              var state = connectedPeers[peripheral.identifier] else { return }
        let now = Date()
        let rtt = state.lastPingSent.map { now.timeIntervalSince($0) * 1000 }
        state.lastPingReceived = now
        connectedPeers[peripheral.identifier] = state
        let rttText = rtt.map { String(format: "%.0fms", $0) } ?? "pong"
        Log.debug("BT pong ← \(state.peer.name): \(rttText)")
            dispatcher.dispatch(AppAction.addToEventLog(NetworkEventLogItem(
                primaryText: "Ping: \(state.peer.name)",
                secondaryText: rttText,
                date: now,
                severity: .info
            )))
    }
}

// MARK: - CBPeripheralManagerDelegate
extension DefaultGeneratedBluetoothConnectivityService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        let pingChar = CBMutableCharacteristic(
            type: BTConstants.pingCharacteristicUUID,
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )
        pingCharacteristic = pingChar
        let service = CBMutableService(type: BTConstants.serviceUUID, primary: true)
        service.characteristics = [pingChar]
        peripheral.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        Log.debug("BT Peripheral: restoring state")
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {
        guard error == nil else {
            Log.error("BT failed to add service: \(error!)")
            return
        }
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BTConstants.serviceUUID],
            CBAdvertisementDataLocalNameKey: myName
        ])
        Log.debug("BT Peripheral: advertising as \(myName)")
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests where request.characteristic.uuid == BTConstants.pingCharacteristicUUID {
            if let data = request.value, let char = pingCharacteristic {
                peripheral.updateValue(data, for: char, onSubscribedCentrals: nil)
            }
            peripheral.respond(to: request, withResult: .success)
        }
    }
}
