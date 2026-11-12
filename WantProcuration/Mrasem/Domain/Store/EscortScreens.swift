//
//  EscortScreens.swift
//  Mrasem
//
//  Phase 16 — «وفدي» للمرافق: الوفود المسؤول عنها، أعضاؤه بغرفهم وسياراتهم وسائقيهم، وبرنامج النهاردة.
//

import Foundation

struct EscortMemberRow: Equatable, Identifiable {
    let id: String
    let name: String
    let title: String
    let room: String
    let carLabel: String?
    let driverName: String?
    let isHead: Bool
}

struct EscortProgramRow: Equatable, Identifiable {
    let id: String
    let time: String
    let title: String
    let kind: ProgramItemKind
    let placeName: String?
    let carLabel: String?
}

struct EscortDelegationCard: Equatable, Identifiable {
    let id: String
    let name: String
    let start: String
    let end: String
    let hotelName: String?
    let members: [EscortMemberRow]
    let today: [EscortProgramRow]
}

struct EscortHomeState: Equatable {
    let name: String
    let phone: String
    let meetingSpot: String
    let delegations: [EscortDelegationCard]

    static let empty = EscortHomeState(name: "", phone: "", meetingSpot: "", delegations: [])

    static func make(_ db: MrasemDatabase, escortId: String, today: String) -> EscortHomeState {
        guard let escort = db.escort(escortId) else { return .empty }

        let cards = ResourceService.delegations(ofEscort: escortId, in: db).map { delegation in
            EscortDelegationCard(
                id: delegation.id, name: delegation.name, start: delegation.start, end: delegation.end,
                hotelName: db.place(delegation.hotelId)?.name,
                members: db.members
                    .filter { $0.delegationId == delegation.id && $0.escortId == escortId }
                    .map { member in
                        EscortMemberRow(
                            id: member.id, name: member.name, title: member.title, room: member.room,
                            carLabel: AdminDelegationDetailBuilder.carLabel(db.car(member.carId)),
                            driverName: db.driver(db.car(member.carId)?.driverId)?.name, isHead: member.isHead
                        )
                    },
                today: db.program
                    .filter { $0.delegationId == delegation.id && $0.date == today }
                    .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
                    .map { item in
                        EscortProgramRow(
                            id: item.id, time: item.time, title: item.title, kind: item.kind,
                            placeName: db.place(item.placeId)?.name,
                            carLabel: AdminDelegationDetailBuilder.carLabel(db.car(item.carId))
                        )
                    }
            )
        }
        return EscortHomeState(name: escort.name, phone: escort.phone, meetingSpot: escort.meetingSpot, delegations: cards)
    }
}
