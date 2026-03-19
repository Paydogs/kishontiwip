//
//  TitleComponent.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

struct TitleComponent: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .font(Fonts.regular(size: 12))
                .foregroundStyle(Asset.Colors.Text.secondary.swiftUIColor)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.horizontal, 2)
    }
}

#Preview {
    TitleComponent(text: "EVENT LOG")
}
