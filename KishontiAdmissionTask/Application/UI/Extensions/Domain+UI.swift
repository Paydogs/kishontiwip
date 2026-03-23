//
//  Domain+UI.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

extension NetworkEventLogItem {
}

extension EventSeverity {
    var color: Color {
        switch self {
        case .info:
            Asset.Colors.General.green.swiftUIColor
        case .warning:
            Asset.Colors.General.yellow.swiftUIColor
        case .error:
            Asset.Colors.General.red.swiftUIColor
        }
    }
}

extension ConnectionStatus {
    var color: Color {
        switch self {
        case .unavailable:
            Asset.Colors.General.gray.swiftUIColor
        case .full:
            Asset.Colors.General.green.swiftUIColor
        case .bluetooth:
            Asset.Colors.General.blue.swiftUIColor
        case .multipeer:
            Asset.Colors.General.yellow.swiftUIColor
        }
    }
}

extension Array where Element == ConnectionStatus {
    var globalPercentageText: String {
        guard !self.isEmpty else { return "0.00%" }
        let availableCount = self.filter { $0 != .unavailable }.count
        let percentage = CGFloat(availableCount) / CGFloat(self.count)
        return String(format: "%.2f%%", percentage * 100)
    }
    
    func percentageText(_ connectionStatus: ConnectionStatus) -> String {
        guard !self.isEmpty else { return "0.00%" }
        let availableCount = self.filter { $0 == connectionStatus }.count
        let percentage = CGFloat(availableCount) / CGFloat(self.count)
        return String(format: "%.2f%%", percentage * 100)
    }
}

extension Array where Element == PeerHeartbeat {
    func connectionStatuses(slice: TimeInterval) -> [ConnectionStatus] {
        guard !self.isEmpty, slice > 0 else { return [] }
        
        // Slice the array into slice length buckets
        let timeSliced = Dictionary(grouping: self) { heartbeat in
            let seconds = heartbeat.date.timeIntervalSince1970
            return (seconds / slice).rounded(.towardZero) * slice
        }
        
        let sortedKeys = timeSliced.keys.sorted()
        
        return sortedKeys.map { key in
            let heartbeatsInSlice = timeSliced[key] ?? []
            
            // Extract unique transports present in this slice
            let transports = heartbeatsInSlice.compactMap { $0.transport }
            
            let hasBT = transports.contains(.bluetooth)
            let hasMP = transports.contains(.multipeer)
            
            if hasBT && hasMP {
                return .full
            } else if hasBT {
                return .bluetooth
            } else if hasMP {
                return .multipeer
            } else {
                return .unavailable
            }
        }
    }
}


extension Set where Element == Transport {
    var sorted: [Transport] {
        self.sorted(by: { $0.rawValue < $1.rawValue })
    }
    
    func transportChips() -> [Chip.Data] {
        self.map { transport in
            switch transport {
            case .bluetooth:
                return .init(text: "Bluetooth", color: Asset.Colors.General.blue.swiftUIColor)
            case .multipeer:
                return .init(text: "MultiPeer", color: Asset.Colors.General.red.swiftUIColor)
            }
        }
    }
}

extension Array where Element == Transport {
    var stringList: [String] {
        self.map { transport in
            switch transport {
            case .bluetooth: return "Bluetooth"
            case .multipeer: return "MultiPeer"
            }
        }
    }
}
