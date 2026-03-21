//
//  PeerComponent.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

extension PeerComponent {
    enum PeerType {
        case own
        case detected
        case connected
    }
}

struct PeerComponent: View {
    let text: String
    let chips: [Chip.Data]
    let image: Image
    let isOn: Bool
    let heartbeats: [PeerHeartbeat]
    let toggle: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top) {
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
                VStack(alignment: .leading) {
                    Text(text)
                        .font(Fonts.regular(size: 16))
                        .foregroundColor(Asset.Colors.Text.primary.swiftUIColor)
                    FlowLayout(spacing: 6) {
                        ForEach(chips) { chipData in
                            Chip(chipData: chipData)
                        }
                    }
                }
                .padding(.leading, 8)

                Spacer()
                GlowButton(image: image,
                           isOn: isOn,
                           action: toggle)
            }
            .padding([.horizontal, .top])

            if !heartbeats.isEmpty {
                HStack(spacing: 8) {
                    ValueCard(value: "\(heartbeats.count)",
                              valueColor: Asset.Colors.General.green.swiftUIColor,
                              title: "HEARTBEATS")
                    Spacer()
                }
                .padding([.horizontal, .bottom])
            }
        }
        .background(Asset.Colors.Background.bg2.swiftUIColor)
        .cornerRadius(12)
    }
}

#Preview {
    PeerComponent(text: "iPhone 12 mini",
                  chips: [.init(text: "Own", color: Asset.Colors.Text.primary.swiftUIColor),
                          .init(text: "BT", color: Asset.Colors.General.blue.swiftUIColor),
                          .init(text: "MultiPoint", color: Asset.Colors.General.yellow.swiftUIColor),
                          .init(text: "MultiLine test", color: Asset.Colors.General.yellow.swiftUIColor)],
                  image: Image.init(systemName: "power"),
                  isOn: false,
                  heartbeats: [.bluetooth(Date()), .multipeer(Date()), .bluetooth(Date())],
                  toggle: { })
    .padding()

    PeerComponent(text: "iPhone 12 mini",
                  chips: [.init(text: "Detected", color: Asset.Colors.General.yellow.swiftUIColor)],
                  image: Image.init(systemName: "link"),
                  isOn: false,
                  heartbeats: [],
                  toggle: { })
    .padding()

    PeerComponent(text: "iPhone 12 mini",
                  chips: [.init(text: "Connected", color: Asset.Colors.General.green.swiftUIColor)],
                  image: Image.init(systemName: "link"),
                  isOn: true,
                  heartbeats: [.multipeer(Date())],
                  toggle: { })
    .padding()
}


