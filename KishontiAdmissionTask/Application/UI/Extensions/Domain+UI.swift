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
        case .unknown:
            Asset.Colors.General.gray.swiftUIColor
        case .online:
            Asset.Colors.General.green.swiftUIColor
        case .offline:
            Asset.Colors.General.red.swiftUIColor
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
