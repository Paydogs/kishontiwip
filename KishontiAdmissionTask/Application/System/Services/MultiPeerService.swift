//
//  MultiPeerService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation
import MultipeerConnectivity
import os

struct PendingInvitation: Identifiable {
    let id = UUID()
    let peerID: MCPeerID
    let handler: (Bool, MCSession?) -> Void
}

protocol MultiPeerService {
    func startService()
    func stopService()
    func sendHeartbeats()
    func invite(peer: Peer)
    func reconnectKnownPeer(peer: Peer)
    func acceptInvitation()
    func declineInvitation()
    func send(action: RemoteAction, to peer: Peer)
    func disconnect(peer: Peer)
}

// MARK: - PeerService
final class DefaultMultiPeerService: NSObject, MultiPeerService {
    private let deviceManager: DeviceManaging
    private let myPeerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    var pendingInvitation: PendingInvitation?

    private var peerIdStack: [String: MCPeerID] = [:]
    private var isActive: Bool = false
    
    init(deviceManager: DeviceManaging) {
        self.deviceManager = deviceManager
        self.myPeerID = MCPeerID(displayName: DeviceIdentity.peerName)
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        super.init()
        session.delegate = self
    }
    
    func startService() {
        guard !isActive else { return }
        startAdvertising()
        startBrowsing()
        isActive = true
    }
    
    func stopService() {
        guard isActive else { return }
        Log.debug("Stopping Multipeer service")
        stopAdvertising()
        stopBrowsing()
        isActive = false
        for (name, _) in peerIdStack {
            Log.debug("Dropping multipeer transports")
            deviceManager.peerLost(name, via: .multipeer)
        }
        peerIdStack.removeAll()
    }
    
    func invite(peer: Peer) {
        guard let mcPeerID = peerIdStack[peer.peerId] else {
            Log.debug("Invite failed: no MCPeerID for \(peer.name)")
            return
        }
        guard !session.connectedPeers.contains(mcPeerID) else {
            Log.debug("Invite skipped: \(peer.name) already connected")
            return
        }
        browser?.invitePeer(mcPeerID, to: session, withContext: nil, timeout: 30)
        Log.debug("Multipeer service sent invitation to \(peer.name)")
    }

    func reconnectKnownPeer(peer: Peer) {
        guard let mcPeerID = peerIdStack[peer.peerId] else {
            Log.debug("Invite failed: no MCPeerID for \(peer.name)")
            return
        }
        guard !session.connectedPeers.contains(mcPeerID) else {
            Log.debug("Reconnect skipped: \(peer.name) already connected")
            return
        }
        browser?.invitePeer(mcPeerID, to: session, withContext: nil, timeout: 30)
        Log.debug("Multipeer service sent invitation to \(peer.name)")
    }
    
    func acceptInvitation() {
        guard let invitation = pendingInvitation else { return }
        Log.debug("Multipeer service accepting invitation")
        invitation.handler(true, session)
        pendingInvitation = nil
        deviceManager.invitationCleared()
        Log.debug("Multipeer service handled the invitation")
    }

    func declineInvitation() {
        guard let invitation = pendingInvitation else { return }
        Log.debug("Multipeer service declining invitation")
        invitation.handler(false, nil)
        pendingInvitation = nil
        deviceManager.invitationCleared()
        Log.debug("Multipeer service handled the invitation")
    }
    
    func sendHeartbeats() {
        reportHeartbeats()
    }

    func send(action: RemoteAction, to peer: Peer) {
        guard let mcPeerID = peerIdStack[peer.peerId],
              let data = try? JSONEncoder().encode(action) else { return }
        try? session.send(data, toPeers: [mcPeerID], with: .reliable)
        Log.debug("Multipeer service sent \(action) to \(peer.name)")
    }

    func disconnect(peer: Peer) {
        session.disconnect()
        deviceManager.peerDisconnected(peer.peerId, via: .multipeer)
        Log.debug("Multipeer service disconnected from \(peer.name)")
    }
}

private extension DefaultMultiPeerService {
    func reportHeartbeats() {
        for peerID in session.connectedPeers {
            deviceManager.heartbeatDetected(peerID.displayName, via: .multipeer)
        }
    }

    func startAdvertising() {
        Log.info("Multipeer service starting advertising")
        let advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: Constants.serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        Log.info("Multipeer service started advertising as \(self.myPeerID.displayName)")
    }
    
    func stopAdvertising() {
        Log.info("Multipeer service stopping advertising")
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        Log.info("Multipeer service stopped advertising")
    }
    
    func startBrowsing() {
        Log.info("Multipeer Browser starting")
        let br = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: Constants.serviceType
        )
        br.delegate = self
        br.startBrowsingForPeers()
        self.browser = br
        Log.info("Multipeer Browser started")
    }
    
    func stopBrowsing() {
        Log.info("Multipeer Browser stopping")
        browser?.stopBrowsingForPeers()
        browser = nil
        Log.info("Multipeer Browser stopped")
    }
}

extension DefaultMultiPeerService: MCSessionDelegate {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Log.debug("Multipeer Session state \(state) didChange with peer: \(peerID)")
        switch state {
        case .connected:
            deviceManager.peerConnected(peerID.displayName, via: .multipeer)
        case .notConnected:
            deviceManager.peerDisconnected(peerID.displayName, via: .multipeer)
        default:
            break
        }
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Log.debug("Multipeer Session didReceive: \(data.count)bytes from: \(peerID)")
        guard let action = try? JSONDecoder().decode(RemoteAction.self, from: data) else { return }
        Log.debug("Its the following action: \(action) from \(peerID.displayName)")
        deviceManager.remoteActionReceived(action, from: peerID.displayName)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        Log.debug("Multipeer Session didReceiveStream withName: \(streamName) from: \(peerID)")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Log.debug("Multipeer Session didStartReceivingResourceWithName withName: \(resourceName) from: \(peerID), progress: \(progress)")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Log.debug("Multipeer Session didFinishReceivingResourceWithName withName: \(resourceName) from: \(peerID), localUrl: \(localURL?.absoluteString ?? "") error: \(error?.localizedDescription ?? "")")
    }
}

extension DefaultMultiPeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Log.debug("Multipeer Advertiser didReceiveInvitationFromPeer: \(peerID), context: \(context?.count ?? 0) bytes")
        guard !session.connectedPeers.contains(peerID) else {
            Log.debug("Invitation ignored: \(peerID.displayName) already connected")
            invitationHandler(false, nil)
            return
        }
        pendingInvitation = PendingInvitation(peerID: peerID, handler: invitationHandler)
        peerIdStack[peerID.displayName] = peerID
        deviceManager.invitationReceived(from: peerID.displayName)
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        Log.debug("Multipeer Advertiser didNotStartAdvertisingPeer: \(error)")
    }
}

extension DefaultMultiPeerService: MCNearbyServiceBrowserDelegate {

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Log.debug("Multipeer Browser found peer: \(peerID), info: \(String(describing: info))")
        peerIdStack[peerID.displayName] = peerID
        deviceManager.peerDiscovered(peerID.displayName, via: .multipeer)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Log.debug("Multipeer Browser lost peer: \(peerID)")
        peerIdStack.removeValue(forKey: peerID.displayName)
        deviceManager.peerLost(peerID.displayName, via: .multipeer)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Log.debug("Multipeer Browser didNotStartBrowsingForPeers: \(error)")
    }
}
