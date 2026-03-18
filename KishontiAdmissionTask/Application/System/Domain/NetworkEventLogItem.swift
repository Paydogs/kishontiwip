//
//  NetworkEventLogItem.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import Foundation

struct NetworkEventLogItem {
    let primaryText: String
    let secondaryText: String
    let date: Date
    let severity: EventSeverity
}

enum EventSeverity {
    case Good
    case Warning
    case Error
}
