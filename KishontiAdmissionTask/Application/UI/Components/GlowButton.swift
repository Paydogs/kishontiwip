//
//  GlowButton.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

struct GlowButton: View {
    let image: Image
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            image
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isOn ? .green : .gray)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isOn ? Color.green.opacity(0.12) : Color.gray.opacity(0.08))
                )
                .overlay(
                    Circle()
                        .stroke(isOn ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: isOn ? Color.green.opacity(0.4) : .clear, radius: 8)
                .shadow(color: isOn ? Color.green.opacity(0.2) : .clear, radius: 16)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GlowButton(image: Image(systemName: "power"), isOn: true) {}
        GlowButton(image: Image(systemName: "power"), isOn: false) {}
    }
    .padding()
    .background(Color(red: 0.05, green: 0.06, blue: 0.08))
}
