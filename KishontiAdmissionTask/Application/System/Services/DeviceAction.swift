//
//  DeviceAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

public enum DeviceAction: Intent {
    case invite(Peer)
    case unpair(Peer)
    case remoteUnpair(Peer)
    case acceptInvitation
    case declineInvitation
}
