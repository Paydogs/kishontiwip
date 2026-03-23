//
//  TimelineBar.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct TimelineBar: View {
    let connectionStatuses: [ConnectionStatus]
    private let maxVisibleBars = 24
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(displayedStatuses.enumerated()), id: \.offset) { _, status in
                RoundedRectangle(cornerRadius: 4)
                    .fill(status.color)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 48) // Fixed height for the bar
    }
    
    private var displayedStatuses: [ConnectionStatus] {
        let suffix = connectionStatuses.suffix(maxVisibleBars)
        let paddingCount = maxVisibleBars - suffix.count
        
        // Add "empty" slots to the beginning if we have less than 24
        let padding = Array(repeating: ConnectionStatus.unavailable, count: paddingCount)
        return padding + suffix
    }
}

#Preview {
    TimelineBar(connectionStatuses: ConnectionStatus.randomStatuses(count: 24))
        .frame(height: 48)
    TimelineBar(connectionStatuses: ConnectionStatus.randomStatuses(count: 12))
        .frame(height: 48)
}
