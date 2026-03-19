//
//  ActionDispatcher+Environment.swift
//  MCPToolTester
//
//  Created by Andras Olah on 2026. 03. 05..
//

import SwiftUI

private struct ActionDispatcherKey: EnvironmentKey {
    static let defaultValue: ActionDispatcher = ActionDispatcher(ActionBus())
}

extension EnvironmentValues {
    var dispatcher: ActionDispatcher {
        get { self[ActionDispatcherKey.self] }
        set { self[ActionDispatcherKey.self] = newValue }
    }
}
