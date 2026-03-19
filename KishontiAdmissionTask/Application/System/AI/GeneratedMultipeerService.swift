//
//  MultipeerService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import Foundation
import MultipeerConnectivity
import os

// MARK: - PeerService

final class GeneratedMultipeerService: NSObject, ObservableObject {
    
    // MARK: - Configuration
    
    /// 1–15 chars, lowercase ASCII letters/digits and hyphens only
    private static let serviceType = "peer-connect"
    
    // MARK: - Published State
    
    @Published private(set) var discoveredPeers: [MCPeerID] = []
    @Published private(set) var connectedPeers: [MCPeerID] = []
    @Published private(set) var messages: [Message] = []
    @Published private(set) var isAdvertising = false
    @Published private(set) var isBrowsing = false
    @Published var pendingInvitation: PendingInvitation?
    
    // MARK: - Types
    
    struct Message: Identifiable {
        let id = UUID()
        let sender: String
        let text: String
        let timestamp: Date
        let isLocal: Bool
    }
    
    struct PendingInvitation: Identifiable {
        let id = UUID()
        let peerID: MCPeerID
        let handler: (Bool, MCSession?) -> Void
    }
    
    // MARK: - Private
    
    private let myPeerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private let logger = Logger(subsystem: "com.peerconnect", category: "PeerService")
    
    // MARK: - Init
    
    override init() {
        let displayName = UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: displayName)
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        super.init()
        session.delegate = self
    }
    
    // MARK: - Public API
    
    func startAdvertising() {
        guard !isAdvertising else { return }
        let adv = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: Self.serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        self.advertiser = adv
        isAdvertising = true
        logger.info("Started advertising as \(self.myPeerID.displayName)")
    }
    
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
    }
    
    func startBrowsing() {
        guard !isBrowsing else { return }
        let br = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: Self.serviceType
        )
        br.delegate = self
        br.startBrowsingForPeers()
        self.browser = br
        isBrowsing = true
        logger.info("Started browsing")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        discoveredPeers.removeAll()
    }
    
    func startAll() {
        startAdvertising()
        startBrowsing()
    }
    
    func stopAll() {
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
        connectedPeers.removeAll()
    }
    
    func invite(peer: MCPeerID) {
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        logger.info("Sent invitation to \(peer.displayName)")
    }
    
    func acceptInvitation(_ invitation: PendingInvitation) {
        invitation.handler(true, session)
        pendingInvitation = nil
    }
    
    func declineInvitation(_ invitation: PendingInvitation) {
        invitation.handler(false, nil)
        pendingInvitation = nil
    }
    
    func send(text: String) {
        guard !session.connectedPeers.isEmpty,
              let data = text.data(using: .utf8) else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            messages.append(Message(
                sender: myPeerID.displayName,
                text: text,
                timestamp: .now,
                isLocal: true
            ))
        } catch {
            logger.error("Send failed: \(error.localizedDescription)")
        }
    }
    
    func disconnect() {
        session.disconnect()
        connectedPeers.removeAll()
    }
    
    var localDisplayName: String { myPeerID.displayName }
}

// MARK: - MCSessionDelegate

extension GeneratedMultipeerService: MCSessionDelegate {
    
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let label: String = {
            switch state {
            case .notConnected: return "notConnected"
            case .connecting:   return "connecting"
            case .connected:    return "connected"
            @unknown default:   return "unknown"
            }
        }()
        logger.info("\(peerID.displayName) → \(label)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.connectedPeers = session.connectedPeers
            self.discoveredPeers.removeAll { session.connectedPeers.contains($0) }
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.messages.append(Message(
                sender: peerID.displayName,
                text: text,
                timestamp: .now,
                isLocal: false
            ))
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension GeneratedMultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        logger.info("Invitation from \(peerID.displayName)")
        DispatchQueue.main.async { [weak self] in
            self?.pendingInvitation = PendingInvitation(
                peerID: peerID,
                handler: invitationHandler
            )
        }
    }
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        logger.error("Advertising failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension GeneratedMultipeerService: MCNearbyServiceBrowserDelegate {
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.discoveredPeers.contains(peerID),
                  !self.connectedPeers.contains(peerID) else { return }
            self.discoveredPeers.append(peerID)
            self.logger.info("Discovered: \(peerID.displayName)")
        }
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.discoveredPeers.removeAll { $0 == peerID }
        }
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        logger.error("Browsing failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.isBrowsing = false
        }
    }
}
