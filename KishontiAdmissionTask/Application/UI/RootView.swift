//
//  RootView.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct RootView: View {
    
    @StateObject private var peerService = MultipeerService()
    @State private var messageText = ""
    @State private var isActive = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBanner
                peerSection
                Divider()
                chatSection
                inputBar
            }
            .navigationTitle("PeerConnect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle(isOn: $isActive) {
                        Label(
                            isActive ? "Active" : "Inactive",
                            systemImage: isActive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
                        )
                    }
                    .toggleStyle(.button)
                    .onChange(of: isActive) { newValue in
                        if newValue {
                            peerService.startAll()
                        } else {
                            peerService.stopAll()
                        }
                    }
                }
            }
            .alert(
                "Invitation",
                isPresented: .init(
                    get: { peerService.pendingInvitation != nil },
                    set: { if !$0 {
                        if let inv = peerService.pendingInvitation {
                            peerService.declineInvitation(inv)
                        }
                    }}
                )
            ) {
                Button("Accept") {
                    if let inv = peerService.pendingInvitation {
                        peerService.acceptInvitation(inv)
                    }
                }
                Button("Decline", role: .cancel) {
                    if let inv = peerService.pendingInvitation {
                        peerService.declineInvitation(inv)
                    }
                }
            } message: {
                if let inv = peerService.pendingInvitation {
                    Text("\(inv.peerID.displayName) wants to connect")
                }
            }
        }
    }
    
    // MARK: - Status Banner
    
    private var statusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(peerService.localDisplayName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private var statusColor: Color {
        if !peerService.connectedPeers.isEmpty { return .green }
        if isActive { return .orange }
        return .gray
    }
    
    private var statusText: String {
        let count = peerService.connectedPeers.count
        if count > 0 {
            return "Connected to \(count) peer\(count == 1 ? "" : "s")"
        }
        if isActive { return "Searching…" }
        return "Inactive"
    }
    
    // MARK: - Peer Section
    
    private var peerSection: some View {
        Group {
            if !peerService.discoveredPeers.isEmpty || !peerService.connectedPeers.isEmpty {
                List {
                    if !peerService.connectedPeers.isEmpty {
                        Section("Connected") {
                            ForEach(peerService.connectedPeers, id: \.self) { peer in
                                Label(peer.displayName, systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    if !peerService.discoveredPeers.isEmpty {
                        Section("Nearby") {
                            ForEach(peerService.discoveredPeers, id: \.self) { peer in
                                Button {
                                    peerService.invite(peer: peer)
                                } label: {
                                    Label(peer.displayName, systemImage: "person.wave.2")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .frame(maxHeight: 220)
            } else if isActive {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Looking for nearby devices…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            }
        }
    }
    
    // MARK: - Chat
    
    private var chatSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(peerService.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: peerService.messages.count) { _ in
                if let last = peerService.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(sendMessage)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || peerService.connectedPeers.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        peerService.send(text: text)
        messageText = ""
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: MultipeerService.Message
    
    var body: some View {
        HStack {
            if message.isLocal { Spacer(minLength: 60) }
            
            VStack(alignment: message.isLocal ? .trailing : .leading, spacing: 2) {
                if !message.isLocal {
                    Text(message.sender)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isLocal ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isLocal ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if !message.isLocal { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
