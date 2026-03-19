//
//  NetworkEventLogItem.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import Foundation

public struct NetworkEventLogItem: StorableProperty, Identifiable {
    public let id: UUID
    public let primaryText: String
    public let secondaryText: String
    public let date: Date
    public let severity: EventSeverity
    
    public init(primaryText: String, secondaryText: String, date: Date, severity: EventSeverity) {
        self.id = UUID()
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.date = date
        self.severity = severity
    }
}

public enum EventSeverity: StorableProperty {
    case Good
    case Warning
    case Error
}
