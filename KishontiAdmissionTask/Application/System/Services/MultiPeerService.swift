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
    func acceptInvitation()
    func declineInvitation()
    func send(text: String)
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

    private var discoveredPeerIDs: [String: MCPeerID] = [:]
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
        stopAdvertising()
        stopBrowsing()
        isActive = false
        for (name, peerID) in discoveredPeerIDs {
            deviceManager.peerLost(Peer(peerId: name, name: peerID.displayName), via: .multipeer)
        }
        discoveredPeerIDs.removeAll()
    }
    
    func invite(peer: Peer) {
        guard let mcPeerID = discoveredPeerIDs[peer.peerId] else {
            Log.debug("Invite failed: no MCPeerID for \(peer.name)")
            return
        }
        browser?.invitePeer(mcPeerID, to: session, withContext: nil, timeout: 30)
        Log.debug("Sent invitation to \(peer.name)")
    }
    
    func acceptInvitation() {
        guard let invitation = pendingInvitation else { return }
        invitation.handler(true, session)
        pendingInvitation = nil
        deviceManager.invitationCleared()
    }

    func declineInvitation() {
        guard let invitation = pendingInvitation else { return }
        invitation.handler(false, nil)
        pendingInvitation = nil
        deviceManager.invitationCleared()
    }
    
    func sendHeartbeats() {
        reportHeartbeats()
    }

    func send(text: String) {
    }
    
    func disconnect(peer: Peer) {
        session.disconnect()
        Log.debug("Disconnected \(peer.name)")
    }
}

private extension DefaultMultiPeerService {
    func reportHeartbeats() {
        for peerID in session.connectedPeers {
            let peer = Peer(peerId: peerID.displayName, name: peerID.displayName)
            deviceManager.heartbeatDetected(peer, via: .multipeer)
        }
    }

    func startAdvertising() {
        Log.info("Starting advertising")
        let advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: Constants.serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        Log.info("Started advertising as \(self.myPeerID.displayName)")
    }
    
    func stopAdvertising() {
        Log.info("Stopping advertising")
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        Log.info("Stopped advertising")
    }
    
    func startBrowsing() {
        Log.info("Starting browsing")
        let br = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: Constants.serviceType
        )
        br.delegate = self
        br.startBrowsingForPeers()
        self.browser = br
        Log.info("Started browsing")
    }
    
    func stopBrowsing() {
        Log.info("Stopping browsing")
        browser?.stopBrowsingForPeers()
        browser = nil
        Log.info("Stopped browsing")
    }
}

extension DefaultMultiPeerService: MCSessionDelegate {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Log.debug("Session state \(state) didChange with peer: \(peerID)")
        let peer = Peer(peerId: peerID.displayName, name: peerID.displayName)
        switch state {
        case .connected:
            deviceManager.peerConnected(peer, via: .multipeer)
        case .notConnected:
            deviceManager.peerDisconnected(peer, via: .multipeer)
        default:
            break
        }
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Log.debug("Session didReceive: \(data.count)bytes from: \(peerID)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        Log.debug("Session didReceiveStream withName: \(streamName) from: \(peerID)")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        Log.debug("Session didStartReceivingResourceWithName withName: \(resourceName) from: \(peerID), progress: \(progress)")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        Log.debug("Session didFinishReceivingResourceWithName withName: \(resourceName) from: \(peerID), localUrl: \(localURL?.absoluteString ?? "") error: \(error?.localizedDescription ?? "")")
    }
}

extension DefaultMultiPeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Log.debug("Advertiser didReceiveInvitationFromPeer: \(peerID), context: \(context?.count ?? 0) bytes")
        pendingInvitation = PendingInvitation(peerID: peerID, handler: invitationHandler)
        discoveredPeerIDs[peerID.displayName] = peerID
        deviceManager.invitationReceived(from: Peer(peerId: peerID.displayName, name: peerID.displayName))
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        Log.debug("Advertiser didNotStartAdvertisingPeer: \(error)")
    }
}

extension DefaultMultiPeerService: MCNearbyServiceBrowserDelegate {

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Log.debug("Browser found peer: \(peerID), info: \(String(describing: info))")
        discoveredPeerIDs[peerID.displayName] = peerID
        deviceManager.peerDiscovered(Peer(peerId: peerID.displayName, name: peerID.displayName), via: .multipeer)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Log.debug("Browser lost peer: \(peerID)")
        discoveredPeerIDs.removeValue(forKey: peerID.displayName)
        deviceManager.peerLost(Peer(peerId: peerID.displayName, name: peerID.displayName), via: .multipeer)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Log.debug("Browser didNotStartBrowsingForPeers: \(error)")
    }
}
