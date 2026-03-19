//
//  Chip.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

struct Chip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}

#Preview {
    Chip(text: "Live", color: Asset.Colors.General.green.swiftUIColor)
    Chip(text: "Error", color: Asset.Colors.General.red.swiftUIColor)
}
