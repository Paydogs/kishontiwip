//
//  DummyData.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

extension ConnectionStatus {
    static func randomStatuses(count: Int) -> [ConnectionStatus] {
        (0..<count).map { _ in
            [.unavailable, .full, .bluetooth, .multipeer].randomElement() ?? .unavailable
        }
    }
}
