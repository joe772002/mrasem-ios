//
//  DriverScreens.swift
//  Mrasem
//
//  Phase 16 — شاشات السائق: «رحلاتي» (رحلات اليوم بحالتها وزر الخطوة الجاية) و«الجدول» (كل الأيام).
//  دوال صافية فوق `DriverTripService`.
//

import Foundation

extension TripStatus {
    /// الخطوة الجاية في الرحلة، أو `nil` لو انتهت.
    var next: TripStatus? {
        switch self {
        case .scheduled: return .onTheWay
        case .onTheWay: return .arrived
        case .arrived: return .pickedUp
        case .pickedUp: return .completed
        case .completed: return nil
        }
    }

    var driverLabelKey: String { "mrasem_driver_status_" + rawValue }
    var driverActionKey: String { "mrasem_driver_action_" + rawValue }
}

struct DriverTripRow: Equatable, Identifiable {
    let id: String
    let time: String
    let pickupTime: String
    let arrivalTime: String
    let title: String
    let delegationName: String
    let from: String
    let to: String
    let passengers: [String]
    let escorts: [String]
    let status: TripStatus

    var next: TripStatus? { status.next }
}

/// وفد متعيّن على سيارة السائق (حتى لو لسه مالوش فقرات في البرنامج).
struct DriverAssignmentRow: Equatable, Identifiable {
    let id: String
    let name: String
    let start: String
    let end: String
    let hotelName: String?
    let passengers: [String]
    let escorts: [String]
}

/// «رحلاتي»: رحلات اليوم؛ لو مفيش رحلات النهارده بيعرض أقرب يوم جاي فيه رحلات.
struct DriverHomeState: Equatable {
    let driverName: String
    let carLabel: String?
    let date: String
    let rows: [DriverTripRow]
    let done: Int
    /// true لو `date` يوم جاي مش النهارده.
    var isUpcoming: Bool = false
    /// الوفود الحالية والجاية اللي أعضاؤها على سيارة السائق.
    var assignments: [DriverAssignmentRow] = []

    static let empty = DriverHomeState(driverName: "", carLabel: nil, date: "", rows: [], done: 0)

    static func make(_ db: MrasemDatabase, driverId: String, today: String) -> DriverHomeState {
        guard let driver = db.driver(driverId) else { return .empty }
        let dates = DriverTripService.dates(db, driverId: driverId)
        let date = dates.contains(today) ? today : (dates.first { $0 > today } ?? today)
        let rows = DriverScreens.rows(db, driverId: driverId, on: date)
        return DriverHomeState(
            driverName: driver.name,
            carLabel: DriverScreens.carLabel(db, driverId: driverId),
            date: date,
            rows: rows,
            done: rows.count { $0.status == .completed },
            isUpcoming: date != today,
            assignments: DriverScreens.assignments(db, driverId: driverId, today: today)
        )
    }
}

struct DriverScheduleDay: Equatable, Identifiable {
    let date: String
    let rows: [DriverTripRow]

    var id: String { date }
}

struct DriverScheduleState: Equatable {
    let days: [DriverScheduleDay]

    static func make(_ db: MrasemDatabase, driverId: String) -> DriverScheduleState {
        DriverScheduleState(days: DriverTripService.dates(db, driverId: driverId).map {
            DriverScheduleDay(date: $0, rows: DriverScreens.rows(db, driverId: driverId, on: $0))
        })
    }
}

nonisolated enum DriverScreens {

    static func rows(_ db: MrasemDatabase, driverId: String, on date: String) -> [DriverTripRow] {
        DriverTripService.trips(db, driverId: driverId, on: date).map { trip in
            DriverTripRow(
                id: trip.id, time: trip.item.time, pickupTime: trip.pickupTime, arrivalTime: trip.arrivalTime,
                title: trip.item.title, delegationName: trip.delegationName, from: trip.from, to: trip.to,
                passengers: trip.passengers.map(\.name), escorts: trip.escorts.map(\.name), status: trip.status
            )
        }
    }

    /// الوفود غير المؤرشفة اللي ما انتهتش، وفيها عضو أو فقرة على سيارة السائق.
    static func assignments(_ db: MrasemDatabase, driverId: String, today: String) -> [DriverAssignmentRow] {
        let carIds = Set(db.cars.filter { $0.driverId == driverId }.map(\.id))
        guard !carIds.isEmpty else { return [] }
        return db.delegations
            .filter { $0.status != .archived && $0.end >= today }
            .sorted { $0.start < $1.start }
            .compactMap { delegation -> DriverAssignmentRow? in
                let riders = db.members.filter { member in
                    member.delegationId == delegation.id && member.carId.map { carIds.contains($0) } == true
                }
                let hasItem = db.program.contains { item in
                    item.delegationId == delegation.id && item.carId.map { carIds.contains($0) } == true
                }
                guard !riders.isEmpty || hasItem else { return nil }
                var escortIds: [String] = []
                for id in riders.compactMap(\.escortId) where !escortIds.contains(id) { escortIds.append(id) }
                return DriverAssignmentRow(
                    id: delegation.id, name: delegation.name, start: delegation.start, end: delegation.end,
                    hotelName: db.place(delegation.hotelId)?.name,
                    passengers: riders.map(\.name),
                    escorts: escortIds.compactMap { db.escort($0)?.name }
                )
            }
    }

    static func carLabel(_ db: MrasemDatabase, driverId: String) -> String? {
        AdminDelegationDetailBuilder.carLabel(db.cars.first { $0.driverId == driverId })
    }
}
