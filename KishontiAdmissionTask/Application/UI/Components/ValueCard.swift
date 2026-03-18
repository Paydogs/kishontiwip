//
//  ValueCard.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct ValueCard: View {
    let value: String
    let valueColor: Color
    let title: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text(value)
                .font(Fonts.bold(size: 16))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(Fonts.regular(size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding()
        .background(Asset.Colors.Background.bg3.swiftUIColor)
        .cornerRadius(12)
    }
}

#Preview {
    HStack {
        ValueCard(value: "24.6h", valueColor: .green, title: "ONLINE")
        ValueCard(value: "10.0h", valueColor: .red, title: "OFFLINE")
        ValueCard(value: "5", valueColor: .gray, title: "SESSIONS")
        ValueCard(value: "4h 10m", valueColor: .gray, title: "LONGEST")
    }
}
