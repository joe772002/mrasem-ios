//
//  AdminDelegationDetail.swift
//  Mrasem
//
//  Phase 14 — تفاصيل الوفد للأدمن: الأعضاء والتعيينات، البرنامج، الإقامة والغرف، الطلبات.
//

import Foundation

struct AdminMemberRow: Equatable, Identifiable {
    let id: String
    let name: String
    let title: String
    let isHead: Bool
    let isActivated: Bool
    let escortName: String?
    let carLabel: String?
    let driverName: String?
    let room: String
}

struct AdminProgramRow: Equatable, Identifiable {
    let id: String
    let time: String
    let endTime: String?
    let title: String
    let kind: ProgramItemKind
    let placeName: String?
    let carLabel: String?
    let isKey: Bool
    let isChanged: Bool
    let hasConflict: Bool
}

struct AdminProgramDay: Equatable, Identifiable {
    let date: String
    let label: String
    let items: [AdminProgramRow]

    var id: String { date }
}

struct AdminRequestRow: Equatable, Identifiable {
    let id: String
    let kind: RequestKind
    let text: String
    let memberName: String?
    let status: RequestStatus
    let reply: String
}

struct AdminDelegationDetail: Equatable {
    let delegation: DelegationRecord
    let hotelName: String?
    let venueName: String?
    let readiness: Int
    let gaps: DelegationGaps
    let members: [AdminMemberRow]
    let days: [AdminProgramDay]
    let requests: [AdminRequestRow]
}

nonisolated enum AdminDelegationDetailBuilder {

    static func carLabel(_ car: CarRecord?) -> String? {
        guard let car else { return nil }
        return car.plate.isEmpty ? car.type : car.type + " · " + car.plate
    }

    /// `nil` لو الوفد اتحذف.
    static func make(_ db: MrasemDatabase, id: String) -> AdminDelegationDetail? {
        guard let delegation = db.delegation(id) else { return nil }
        let conflictIds = PortalInsights.conflictItemIds(db)

        let members = db.members.filter { $0.delegationId == id }.map { member in
            AdminMemberRow(
                id: member.id,
                name: member.name,
                title: member.title,
                isHead: member.isHead,
                isActivated: member.appStatus == .active,
                escortName: db.escort(member.escortId)?.name,
                carLabel: carLabel(db.car(member.carId)),
                driverName: db.driver(db.car(member.carId)?.driverId)?.name,
                room: member.room
            )
        }

        let items = db.program.filter { $0.delegationId == id }.sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
        let days = Dictionary(grouping: items, by: \.date).keys.sorted().map { date in
            AdminProgramDay(
                date: date,
                label: StoreTime.dayLabel(date),
                items: items.filter { $0.date == date }.map { item in
                    AdminProgramRow(
                        id: item.id,
                        time: item.time,
                        endTime: item.endTime,
                        title: item.title,
                        kind: item.kind,
                        placeName: db.place(item.placeId)?.name,
                        carLabel: carLabel(db.car(item.carId)),
                        isKey: item.isKey,
                        isChanged: item.isChanged,
                        hasConflict: conflictIds.contains(item.id)
                    )
                }
            )
        }

        let requests = db.requests.filter { $0.delegationId == id }.sorted { $0.createdAt > $1.createdAt }.map {
            AdminRequestRow(id: $0.id, kind: $0.kind, text: $0.text, memberName: db.member($0.memberId)?.name,
                            status: $0.status, reply: $0.reply)
        }

        return AdminDelegationDetail(
            delegation: delegation,
            hotelName: db.place(delegation.hotelId)?.name,
            venueName: db.place(delegation.venueId)?.name,
            readiness: PortalInsights.readiness(db, delegationId: id),
            gaps: PortalInsights.gaps(db, delegationId: id),
            members: members,
            days: days,
            requests: requests
        )
    }
}

extension ProgramItemKind {
    var labelKey: String { "mrasem_admin_kind_" + rawValue }
}
