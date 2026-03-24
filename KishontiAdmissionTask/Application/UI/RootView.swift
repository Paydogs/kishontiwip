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
    @State private var currentLanguage: LanguageCode = Localization.sharedInstance.currentLanguageCode
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ownPeerComponent()
                    .padding()
                ScrollView(.vertical, showsIndicators: false) {
                    if !viewModel.discoveredPeers.isEmpty {
                        TitleComponent(text: Keys.peerDiscoveredGroupTitle)
                            .padding(.top, 8)
                        VStack {
                            ForEach(viewModel.discoveredPeers) { peer in
                                discoveredPeerComponent(peer)
                            }
                        }
                    }
                    if !viewModel.connectedPeers.isEmpty {
                        TitleComponent(text: Keys.peerPairedGroupTitle)
                            .padding(.top, 8)
                        VStack {
                            ForEach(viewModel.connectedPeers) { peer in
                                connectedPeerComponent(peer)
                            }
                        }
                    }
                    HStack {
                        TitleComponent(text: Keys.peerEventlogGroupTitle)
                            .padding(.top, 8)
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
                    Menu {
                        ForEach([LanguageCode.en, .hu], id: \.self) { code in
                            Button {
                                Localization.sharedInstance.setLanguage(code)
                            } label: {
                                if currentLanguage == code {
                                    Label(code.localizedValue, systemImage: "checkmark")
                                } else {
                                    Text(code.localizedValue)
                                }
                            }
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(Keys.appName)
                                .font(Fonts.regular(size: 20))
                                .foregroundColor(Asset.accentColor.swiftUIColor)
                            Text(Keys.appSubtitle)
                                .font(Fonts.regular(size: 12))
                                .foregroundColor(Asset.accentColor.swiftUIColor)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                currentLanguage = Localization.sharedInstance.currentLanguageCode
            }
        }
        .alert(
            Keys.incomingConnectionAlertTitle,
            isPresented: Binding(
                get: { viewModel.pendingInvitation != nil },
                set: { if !$0 { viewModel.declineInvitation() } }
            ),
            presenting: viewModel.pendingInvitation
        ) { peer in
            Button(Keys.incomingConnectionAlertAccept) { viewModel.acceptInvitation() }
            Button(Keys.incomingConnectionAlertDecline, role: .cancel) { viewModel.declineInvitation() }
        } message: { peer in
            Text(Keys.incomingConnectionAlertMessage(peer.name))
        }
        .alert(Keys.resetStorageAlertTitle, isPresented: $showResetAlert) {
            Button(Keys.resetStorageAlertReset, role: .destructive) { viewModel.resetStorage() }
            Button(Keys.resetStorageAlertCancel, role: .cancel) { }
        } message: {
            Text(Keys.resetStorageAlertMessage)
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
                        .init(text: Keys.peerSelfTitle, color: Asset.Colors.Text.primary.swiftUIColor)
                      ],
                      image: Image(systemName: "power"),
                      isOn: viewModel.isActive,
                      heartbeats: [],
                      toggle: viewModel.toggleServiceActivity)
    }
    
    @ViewBuilder
    func discoveredPeerComponent(_ peer: Peer) -> some View {
        PeerComponent(text: peer.name,
                      chips: [.init(text: Keys.peerStatusDetected, color: Asset.Colors.General.cyan.swiftUIColor)] + peer.activeTransports.transportChips(),
                      image: Image(systemName: "link"),
                      isOn: false,
                      heartbeats: [],
                      toggle: { viewModel.pair(peer: peer) })
    }

    @ViewBuilder
    func connectedPeerComponent(_ peer: Peer) -> some View {
        PeerComponent(text: peer.name,
                      chips: [.init(text: Keys.peerStatusConnected, color: Asset.Colors.General.green.swiftUIColor)] + peer.activeTransports.transportChips(),
                      image: Image(systemName: "link"),
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
            Text(Keys.resetDataButtonTitle)
                .font(Fonts.regular(size: 12))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let message1 = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "has connected", date: Date(), severity: .info)
    let message2 = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "has disconnected", date: Date(), severity: .error)
    let detectedPeer = Peer(peerId: "id1", name: "iPhone 12 mini", activeTransports: [.bluetooth, .multipeer])
    let connectedPeer = Peer(peerId: "id2", name: "iPhone 15", activeTransports: [.bluetooth])
    let previewStore = AppStore(actionBus: ActionBus(),
                                initialState: AppState(peerList: ["id1": detectedPeer, "id2": connectedPeer],
                                                       discoveredPeers: ["id1"],
                                                       connectedPeers: ["id2"],
                                                       logs: [message1, message2],
                                                       heartbeats: ["id2" : [.multipeer(Date.init(timeIntervalSinceNow: -100)),
                                                                             .multipeer(Date.init(timeIntervalSinceNow: -75)),
                                                                             .bluetooth(Date.init(timeIntervalSinceNow: -75)),
                                                                             .bluetooth(Date.init(timeIntervalSinceNow: -60)),
                                                                             .bluetooth(Date.init(timeIntervalSinceNow: -45)),
                                                                             .none(Date.init(timeIntervalSinceNow: -30)),
                                                                             .none(Date.init(timeIntervalSinceNow: -15)),
                                                                             .bluetooth(Date.init(timeIntervalSinceNow: 0)),
                                                                             .multipeer(Date.init(timeIntervalSinceNow: 0))]
                                                       ]
                                                      ))
    Container.shared.appStore.preview { previewStore }
    
    RootView()
}
