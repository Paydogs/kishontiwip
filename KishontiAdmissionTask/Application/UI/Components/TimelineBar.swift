//
//  TimelineBar.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct TimelineBar: View {
    let connectionStatuses: [ConnectionStatus]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(connectionStatuses.suffix(24).enumerated()), id: \.offset) { _, status in
                RoundedRectangle(cornerRadius: 4)
                    .fill(status.color)
            }
        }
    }
}

#Preview {
    TimelineBar(connectionStatuses: ConnectionStatus.randomStatuses(count: 24))
        .frame(height: 48)
}
