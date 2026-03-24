//
//  DeviceAction.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

public enum DeviceAction: Intent {
    /// Action to invite the given peer
    case invite(Peer)
    /// Action to unpair the given peer
    case unpair(Peer)
    /// Action to send unpair action to the remote peer
    case remoteUnpair(Peer)
    /// Action to accept invitation
    case acceptInvitation
    /// Action to decline invitation
    case declineInvitation
}
