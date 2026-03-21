//
//  Chip.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

struct Chip: View {
    struct Data: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
    }
    let chipData: Data
    
    var body: some View {
        Text(chipData.text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .textCase(.uppercase)
            .foregroundColor(chipData.color)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                Capsule()
                    .fill(chipData.color.opacity(0.12))
            )
    }
}

#Preview {
    Chip(chipData: .init(text: "Live", color: Asset.Colors.General.green.swiftUIColor))
    Chip(chipData: .init(text: "Error", color: Asset.Colors.General.red.swiftUIColor))
}
