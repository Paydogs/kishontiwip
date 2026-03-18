//
//  AvailabilityComponent.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct AvailabilityComponent: View {
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("iPhone 12 mini")
                        .font(Fonts.regular(size: 18))
                    Spacer()
                    Text("94.2%")
                        .font(Fonts.regular(size: 16))
                        .foregroundStyle(Asset.Colors.General.green.swiftUIColor)
                }
                TimelineBar(connectionStatuses: ConnectionStatus.randomStatuses(count: 24))
                    .frame(height: 36)
                HStack {
                    ValueCard(value: "24.6h", valueColor: .green, title: "ONLINE")
                    ValueCard(value: "10.0h", valueColor: .red, title: "OFFLINE")
                    ValueCard(value: "5", valueColor: .gray, title: "SESSIONS")
                    ValueCard(value: "4h 10m", valueColor: .gray, title: "LONGEST")
                }
            }
            .padding()
        }
        .background(Asset.Colors.Background.bg2.swiftUIColor)
        .cornerRadius(12)
    }
}

#Preview {
    AvailabilityComponent()
        .padding()
}
