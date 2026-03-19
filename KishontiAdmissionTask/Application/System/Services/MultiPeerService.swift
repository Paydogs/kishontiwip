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
    func invite(peer: MCPeerID)
    func acceptInvitation(_ invitation: PendingInvitation)
    func declineInvitation(_ invitation: PendingInvitation)
    func send(text: String)
    func disconnect()
}

// MARK: - PeerService
final class DefaultMultiPeerService: NSObject, MultiPeerService {
    private let myPeerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    var pendingInvitation: PendingInvitation?
    
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
    
    func startService() {
        startAdvertising()
        startBrowsing()
    }
    
    func stopService() {
        stopAdvertising()
        stopBrowsing()
    }
    
    func invite(peer: MCPeerID) {
    }
    
    func acceptInvitation(_ invitation: PendingInvitation) {
    }
    
    func declineInvitation(_ invitation: PendingInvitation) {
    }
    
    func send(text: String) {
    }
    
    func disconnect() {
    }
}

private extension DefaultMultiPeerService {
    func startAdvertising() {
        Log.info("Starting advertising")
//        guard !isAdvertising else { return }
        let adv = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: Constants.serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        self.advertiser = adv
//        isAdvertising = true
        Log.info("Started advertising as \(self.myPeerID.displayName)")
    }
    
    func stopAdvertising() {
        Log.info("Stopping advertising")
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
//        isAdvertising = false
        Log.info("Stopped advertising")
    }
    
    func startBrowsing() {
        Log.info("Starting browsing")
//        guard !isBrowsing else { return }
        let br = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: Constants.serviceType
        )
        br.delegate = self
        br.startBrowsingForPeers()
        self.browser = br
//        isBrowsing = true
        Log.info("Started browsing")
    }
    
    func stopBrowsing() {
        Log.info("Stopping browsing")
        browser?.stopBrowsingForPeers()
        browser = nil
//        isBrowsing = false
//        discoveredPeers.removeAll()
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
        Log.debug("Session didFinishReceivingResourceWithName withName: \(resourceName) from: \(peerID), localUrl: \(localURL) error: \(error)")
    }
}

extension DefaultMultiPeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Log.debug("Advertiser didReceiveInvitationFromPeer: \(peerID), context: \(context?.count) bytes")
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
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Log.debug("Browser lost peer: \(peerID)")
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Log.debug("Browser didNotStartBrowsingForPeers: \(error)")
    }
}
