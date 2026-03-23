//
//  RootView.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import FactoryKit
import SwiftUI

struct RootView: View {
    @StateObject var viewModel: RootViewModel = RootViewModel()
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ownPeerComponent()
                    .padding()
                ScrollView(.vertical, showsIndicators: false) {
                    if !viewModel.discoveredPeers.isEmpty {
                        TitleComponent(text: "DISCOVERED")
                        VStack {
                            ForEach(viewModel.discoveredPeers) { peer in
                                discoveredPeerComponent(peer)
                            }
                        }
                    }
                    if !viewModel.connectedPeers.isEmpty {
                        TitleComponent(text: "PAIRED")
                        VStack {
                            ForEach(viewModel.connectedPeers) { peer in
                                connectedPeerComponent(peer)
                            }
                        }
                    }
                    HStack {
                        TitleComponent(text: "EVENT LOG")
                        Spacer()
                        Button {
                            viewModel.resetLog()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .frame(width: 24, height: 24)
                        }
                        .padding(.horizontal, 8)

                    }
                    VStack {
                        ForEach(viewModel.messages) { message in
                            LogEventListItem(event: message)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                
                resetButton()
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Asset.Colors.Background.bg1.swiftUIColor)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Keys.appName)
                        .font(.headline)
                        .foregroundColor(Asset.accentColor.swiftUIColor)
                }
            }
        }
        .alert(
            "Incoming Connection",
            isPresented: Binding(
                get: { viewModel.pendingInvitation != nil },
                set: { if !$0 { viewModel.declineInvitation() } }
            ),
            presenting: viewModel.pendingInvitation
        ) { peer in
            Button("Accept") { viewModel.acceptInvitation() }
            Button("Decline", role: .cancel) { viewModel.declineInvitation() }
        } message: { peer in
            Text("\(peer.name) wants to connect")
        }
        .alert("Reset Storage", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { viewModel.resetStorage() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all followed peers and heartbeat history.")
        }
        .task {
            viewModel.load()
        }
    }
}

extension RootView {
    @ViewBuilder
    func ownPeerComponent() -> some View {
        PeerComponent(text: DeviceIdentity.peerName,
                      chips: [
                        .init(text: "This device", color: Asset.Colors.Text.primary.swiftUIColor)
                      ],
                      image: Image(systemName: "power"),
                      isOn: viewModel.isActive,
                      heartbeats: [],
                      toggle: viewModel.toggleServiceActivity)
    }
    
    @ViewBuilder
    func discoveredPeerComponent(_ peer: Peer) -> some View {
        PeerComponent(text: peer.name,
                      chips: [.init(text: "Detected", color: Asset.Colors.General.yellow.swiftUIColor)] + peer.activeTransports.transportChips(),
                      image: Image(systemName: "link"),
                      isOn: false,
                      heartbeats: [],
                      toggle: { viewModel.pair(peer: peer) })
    }

    @ViewBuilder
    func connectedPeerComponent(_ peer: Peer) -> some View {
        PeerComponent(text: peer.name,
                      chips: [.init(text: "Connected", color: Asset.Colors.General.green.swiftUIColor)] + peer.activeTransports.transportChips(),
                      image: Image(systemName: "link.circle.fill"),
                      isOn: true,
                      heartbeats: viewModel.heartbeats(for: peer),
                      toggle: { viewModel.unpair(peer: peer) })
    }
    
    @ViewBuilder
    func resetButton() -> some View {
        Button {
            showResetAlert = true
        } label: {
            Image(systemName: "clear")
                .font(Fonts.regular(size: 12))
            Text("Reset data")
                .font(Fonts.regular(size: 12))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let message1 = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "has connected", date: Date(), severity: .info)
    let message2 = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "has disconnected", date: Date(), severity: .error)
    let detectedPeer = Peer(peerId: "id1", name: "iPhone 12 mini", activeTransports: [.bluetooth, .multipeer])
    let connectedPeer = Peer(peerId: "id2", name: "iPhone 13", activeTransports: [.bluetooth])
    let previewStore = AppStore(actionBus: ActionBus(),
                                initialState: AppState(peerList: ["id1": detectedPeer, "id2": connectedPeer],
                                                       discoveredPeers: ["id1"],
                                                       connectedPeers: ["id2"],
                                                       logs: [message1, message2]))
    Container.shared.appStore.preview { previewStore }
    
    RootView()
}
