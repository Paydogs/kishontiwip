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
        HStack {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(event.severity.color)
            Text(event.primaryText)
                .font(Fonts.bold(size: 14))
                .bold()
            Text(event.secondaryText)
                .font(Fonts.regular(size: 14))
            Spacer()
            Text(event.date, format: .dateTime.hour().minute())
                .font(Fonts.regular(size: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.Background.bg2.swiftUIColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.black, lineWidth: 1)
        )
    }
}

#Preview {
    let exampleEvent = NetworkEventLogItem(primaryText: "iPhone 12 mini", secondaryText: "connected", date: Date(), severity: .Good)
    LogEventListItem(event: exampleEvent)
        .padding()
}
