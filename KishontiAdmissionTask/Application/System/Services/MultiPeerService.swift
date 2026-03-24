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
    /// Creates the advertiser and browser, then begins advertising and browsing for peers.
    func startService()

    /// Restarts the browser, forcing a fresh `foundPeer`/`lostPeer` cycle for all nearby peers.
    func rediscover()

    /// Stops advertising and browsing, notifies the device manager of every lost peer, and clears the peer-ID stack.
    func stopService()

    /// Notifies the device manager of a heartbeat for every peer currently in the MC session.
    func sendHeartbeats()

    /// Sends an MC invitation to `peer`. No-ops if the peer is unknown or already connected.
    func invite(peer: Peer)

    /// Re-invites a previously paired `peer` that has been rediscovered. No-ops if already connected.
    func reconnectKnownPeer(peer: Peer)

    /// Accepts the pending invitation, joins the shared session, and clears the pending-invitation state.
    func acceptInvitation()

    /// Rejects the pending invitation without joining the session, and clears the pending-invitation state.
    func declineInvitation()

    /// Encodes `action` as JSON and sends it reliably to `peer` over the active MC session.
    func send(action: RemoteAction, to peer: Peer)

    /// Disconnects the entire MC session and notifies the device manager that `peer` has disconnected.
    func disconnect(peer: Peer)

    /// Replaces the set of paired peer IDs used to auto-accept incoming invitations.
    func updatePairedPeers(_ peerIds: Set<String>)
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
    private var pairedPeers: Set<String> = []
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

    func rediscover() {
        guard isActive else { return }
        Log.info("Multipeer service rediscovering")
        stopBrowsing()
        startBrowsing()
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
        Log.debug("Multipeer service want to send invite to \(peer.name)")
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
        Log.debug("Multipeer service want to reconnect to \(peer.name). peerIdStack is \(peerIdStack), sessionStack is \(session.connectedPeers)")
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

    func updatePairedPeers(_ peerIds: Set<String>) {
        pairedPeers = peerIds
    }
}

private extension DefaultMultiPeerService {
    func reportHeartbeats() {
        for peerID in session.connectedPeers {
            deviceManager.heartbeatDetected(peerID.displayName, .multipeer(Date()))
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
        Log.debug("Multipeer Session state didChange to \(state.localizedName) on peer: \(peerID)")
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
        peerIdStack[peerID.displayName] = peerID
        if pairedPeers.contains(peerID.displayName) {
            if let existing = pendingInvitation, existing.peerID.displayName == peerID.displayName {
                Log.debug("Invitation ignored: duplicate in-flight for \(peerID.displayName)")
                invitationHandler(false, nil)
                return
            }
            Log.debug("Multipeer Advertiser auto-accepting paired peer \(peerID.displayName)")
            invitationHandler(true, session)
            return
        }
        pendingInvitation = PendingInvitation(peerID: peerID, handler: invitationHandler)
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

extension MCSessionState {
    var localizedName: String {
        switch self {
        case .notConnected: return "Not Connected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        @unknown default: return "Unknown"
        }
    }
}
