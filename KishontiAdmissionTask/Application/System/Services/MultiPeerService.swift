//
//  MultiPeerService.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

/*
import MultipeerConnectivity

public struct PeerInvitation: Sendable {
    let peer: PeerInfo
    fileprivate let continuation: CheckedContinuation<Bool, Never>
    
    func accept() { continuation.resume(returning: true) }
    func decline() { continuation.resume(returning: false) }
}

final class MultiPeerService: NSObject, @unchecked Sendable {
    
    private let myPeerID: MCPeerID
    private let session: MCSession
    private let serviceType: String
    
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // Event stream
    private var eventContinuation: AsyncStream<PeerEvent>.Continuation?
    let events: AsyncStream<PeerEvent>
    
    // Invitation stream
    private var invitationContinuation: AsyncStream<PeerInvitation>.Continuation?
    let invitations: AsyncStream<PeerInvitation>
    
    // MCPeerID → PeerInfo mapping
    private let lock = NSLock()
    private var peerMap: [MCPeerID: PeerInfo] = [:]
    
    init(displayName: String, serviceType: String = "peer-connect") {
        self.serviceType = serviceType
        self.myPeerID = MCPeerID(displayName: displayName)
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        var eCont: AsyncStream<PeerEvent>.Continuation?
        self.events = AsyncStream { eCont = $0 }
        
        var iCont: AsyncStream<PeerInvitation>.Continuation?
        self.invitations = AsyncStream { iCont = $0 }
        
        super.init()
        
        self.eventContinuation = eCont
        self.invitationContinuation = iCont
        self.session.delegate = self
    }
    
    deinit {
        eventContinuation?.finish()
        invitationContinuation?.finish()
    }
    
    // MARK: - Public API
    
    func startAdvertising() {
        let adv = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        self.advertiser = adv
    }
    
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }
    
    func startBrowsing() {
        let br = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )
        br.delegate = self
        br.startBrowsingForPeers()
        self.browser = br
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }
    
    func invite(_ peer: PeerInfo, timeout: TimeInterval = 30) {
        lock.lock()
        let mcPeer = peerMap.first { $0.value == peer }?.key
        lock.unlock()
        
        guard let mcPeer else { return }
        browser?.invitePeer(mcPeer, to: session, withContext: nil, timeout: timeout)
    }
    
    func send(_ data: Data, reliable: Bool = true) throws {
        guard !session.connectedPeers.isEmpty else { return }
        try session.send(
            data,
            toPeers: session.connectedPeers,
            with: reliable ? .reliable : .unreliable
        )
    }
    
    func disconnect() {
        session.disconnect()
    }
    
    // MARK: - Internal helpers
    
    private func peerInfo(for mcPeer: MCPeerID) -> PeerInfo {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = peerMap[mcPeer] {
            return existing
        }
        let info = PeerInfo(
            id: mcPeer.displayName + "-" + UUID().uuidString.prefix(8),
            displayName: mcPeer.displayName
        )
        peerMap[mcPeer] = info
        return info
    }
    
    private func emit(_ event: PeerEvent) {
        eventContinuation?.yield(event)
    }
}

// MARK: - MCSessionDelegate

extension MultiPeerService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let info = peerInfo(for: peerID)
        switch state {
        case .connected:    emit(.connected(info))
        case .connecting:   emit(.connecting(info))
        case .notConnected: emit(.disconnected(info))
        @unknown default:   break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        emit(.received(data, from: peerInfo(for: peerID)))
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

// MARK: - Browser delegate

extension MultiPeerService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo: [String: String]?) {
        emit(.discovered(peerInfo(for: peerID)))
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        emit(.lost(peerInfo(for: peerID)))
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}

// MARK: - Advertiser delegate

extension MultiPeerService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let info = peerInfo(for: peerID)
        let session = self.session
        
        Task {
            let accepted = await withCheckedContinuation { continuation in
                let invitation = PeerInvitation(peer: info, continuation: continuation)
                invitationContinuation?.yield(invitation)
            }
            invitationHandler(accepted, accepted ? session : nil)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
}
*/
