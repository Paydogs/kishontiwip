//
//  LogEventListItem.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct LogEventListItem: View {
    let event: NetworkEventLogItem
    
    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .frame(width: 8, height: 8)
                .padding(.top, 6)
                .foregroundStyle(event.severity.color)
            
            (
                Text(event.primaryText)
                    .font(Fonts.bold(size: 14))
                +
                Text(" " + event.secondaryText)
                    .font(Fonts.regular(size: 14))
            )
            .lineLimit(nil)
            
            Spacer()
            
            Text(event.date, format: .dateTime.hour().minute())
                .font(Fonts.regular(size: 12))
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Asset.Colors.Background.bg2.swiftUIColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.black, lineWidth: 1)
        )
    }
}

#Preview {
    let exampleEvent = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "connected", date: Date(), severity: .info)
    LogEventListItem(event: exampleEvent)
        .padding()
}

#Preview {
    let exampleEvent = NetworkEventLogItem(primaryText: "Your app", secondaryText: "started watching on Wifi and Bluetooth", date: Date(), severity: .info)
    LogEventListItem(event: exampleEvent)
        .padding()
}
