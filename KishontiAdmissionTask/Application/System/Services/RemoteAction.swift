//
//  RemoteAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 23..
//

import Foundation

enum RemoteAction: Codable {
    /// Unpairing action sent by the remote peer
    case unpair
    /// Remote message sending action
    case message(String)
}
