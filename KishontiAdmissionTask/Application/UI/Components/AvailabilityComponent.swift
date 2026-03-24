//
//  AvailabilityComponent.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct AvailabilityComponent: View {
    let connectionStatuses: [ConnectionStatus]
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Spacer()
                    Text(Keys.peerAvailabilityUptime + ": " + connectionStatuses.globalPercentageText)
                        .font(Fonts.regular(size: 16))
                        .foregroundStyle(Asset.Colors.General.green.swiftUIColor)
                }
                TimelineBar(connectionStatuses: connectionStatuses)
                    .frame(height: 36)
                    .padding(.vertical)
                HStack {
                    ValueCard(value: "\(connectionStatuses.percentageText(.full))", valueColor: .green, title: Keys.peerAvailabilityFull)
                    ValueCard(value: "\(connectionStatuses.percentageText(.multipeer))", valueColor: .yellow, title: Keys.peerAvailabilityMultipeer)
                    ValueCard(value: "\(connectionStatuses.percentageText(.bluetooth))", valueColor: .blue, title: Keys.peerAvailabilityBluetooth)
                    ValueCard(value: "\(connectionStatuses.percentageText(.unavailable))", valueColor: .gray, title: Keys.peerAvailabilityNone)
                }
            }
            .padding()
        }
        .background(Asset.Colors.Background.bg2.swiftUIColor)
        .cornerRadius(12)
    }
}

#Preview {
    AvailabilityComponent(connectionStatuses: ConnectionStatus.randomStatuses(count: 24))
        .padding()
}
