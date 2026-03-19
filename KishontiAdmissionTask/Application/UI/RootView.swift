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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PeerComponent(text: DeviceIdentity.peerName,
                              chipText: "This device",
                              chipColor: Asset.Colors.Text.primary.swiftUIColor,
                              image: Image(systemName: "power"),
                              isOn: viewModel.isActive,
                              toggle: viewModel.toggleServiceActivity)
                    .padding()
                ScrollView(.vertical, showsIndicators: false) {
                    if !viewModel.discoveredPeers.isEmpty {
                        TitleComponent(text: "DISCOVERED")
                        VStack {
                            ForEach(viewModel.discoveredPeers) { peer in
                                PeerComponent(text: peer.name,
                                              chipText: "Detected",
                                              chipColor: Asset.Colors.General.yellow.swiftUIColor,
                                              image: Image(systemName: "link"),
                                              isOn: false,
                                              toggle: { viewModel.connect(peer: peer) })
                            }
                        }
                    }
                    if !viewModel.connectedPeers.isEmpty {
                        TitleComponent(text: "PAIRED")
                        VStack {
                            ForEach(viewModel.connectedPeers) { peer in
                                PeerComponent(text: peer.name,
                                              chipText: "Connected",
                                              chipColor: Asset.Colors.General.green.swiftUIColor,
                                              image: Image(systemName: "link.circle.fill"),
                                              isOn: true,
                                              toggle: { viewModel.disconnect(peer: peer) })
                            }
                        }
                    }
                    TitleComponent(text: "EVENT LOG")
                    VStack {
                        ForEach(viewModel.messages) { message in
                            LogEventListItem(event: message)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
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
        .task {
            viewModel.load()
        }
    }
}

#Preview {
    let message1 = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "has connected", date: Date(), severity: .info)
    let message2 = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "has disconnected", date: Date(), severity: .error)
    let previewStore = AppStore(actionBus: ActionBus(), initialState: AppState(messages: [message1, message2]))
    Container.shared.appStore.preview { previewStore }
    
    RootView()
}
