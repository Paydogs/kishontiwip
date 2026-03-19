//
//  RootView.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct RootView: View {
    @Environment(\.dispatcher) private var dispatcher
    
    @StateObject var viewModel: RootViewModel = RootViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toggle("Service", isOn: Binding(
                    get: { viewModel.isAdvertising },
                    set: { viewModel.toggleAdvertising($0) }
                ))
                .toggleStyle(.switch)
                .padding(.horizontal, 8)
                .foregroundColor(Asset.accentColor.swiftUIColor)
                .padding()
                ScrollView(.vertical, showsIndicators: false) {
                    AvailabilityComponent()
                    VStack {
                        ForEach(viewModel.messages) { message in
                            LogEventListItem(event: message)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Asset.Colors.Background.bg1.swiftUIColor)
            .toolbar {
                ToolbarItem(placement: .principal) { // This centers the text
                    Text("Admission App")
                        .font(.headline)
                        .foregroundColor(Asset.accentColor.swiftUIColor)
                }
            }
        }
        .task {
            viewModel.load()
        }
    }
}

#Preview {
    RootView()
}
