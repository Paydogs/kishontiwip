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
    let chipText: String?
    let chipColor: Color?
    let image: Image
    let isOn: Bool
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
                    if let chipText = chipText, let chipcolor = chipColor {
                        Chip(text: chipText, color: chipcolor)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                GlowButton(image: image,
                           isOn: isOn,
                           action: toggle)
            }
            .padding()
        }
        .background(Asset.Colors.Background.bg2.swiftUIColor)
        .cornerRadius(12)
    }
}

#Preview {
    PeerComponent(text: "iPhone 12 mini",
                  chipText: "Own",
                  chipColor: Asset.Colors.Text.primary.swiftUIColor,
                  image: Image.init(systemName: "power"),
                  isOn: false,
                  toggle: { })
    .padding()
    PeerComponent(text: "iPhone 12 mini",
                  chipText: "Detected",
                  chipColor: Asset.Colors.General.yellow.swiftUIColor,
                  image: Image.init(systemName: "link"),
                  isOn: false,
                  toggle: { })
    .padding()
    PeerComponent(text: "iPhone 12 mini",
                  chipText: "Connected",
                  chipColor: Asset.Colors.General.green.swiftUIColor,
                  image: Image.init(systemName: "link"),
                  isOn: true,
                  toggle: { })
    .padding()
}


