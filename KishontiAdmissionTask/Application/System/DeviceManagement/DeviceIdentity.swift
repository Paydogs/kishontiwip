//
//  DeviceIdentity.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import UIKit

enum DeviceIdentity {
    static let peerName: String = {
        let name = UIDevice.current.name
        let suffix = UIDevice.current.identifierForVendor
            .flatMap { String($0.uuidString.prefix(4)) } ?? "????"
        return "\(name) (\(suffix))"
    }()
}
