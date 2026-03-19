//
//  DiscoveredPeerComponent.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

struct DiscoveredPeerComponent: View {
    let peer: Peer
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Image(systemName: "iphone")
                        .font(.system(size: 20))
                        .foregroundColor(Asset.Colors.Text.primary.swiftUIColor)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.15), lineWidth: 1)
                        )
                    Text(DeviceIdentity.peerName)
                        .font(Fonts.regular(size: 16))
                        .foregroundColor(Asset.Colors.Text.primary.swiftUIColor)
                    Spacer()
                    Chip(text: "DISCOVERED", color: Asset.Colors.General.green.swiftUIColor)
                }
            }
            .padding()
        }
        .background(Asset.Colors.Background.bg2.swiftUIColor)
        .cornerRadius(12)
    }
}

#Preview {
    let peer = Peer(peerId: PeerIdentifier(), name: "iPhone 12")
    DiscoveredPeerComponent(peer: peer)
}
