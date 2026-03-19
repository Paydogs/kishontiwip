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
