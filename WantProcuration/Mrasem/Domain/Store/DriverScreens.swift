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

struct DriverHomeState: Equatable {
    let driverName: String
    let carLabel: String?
    let date: String
    let rows: [DriverTripRow]
    let done: Int

    static let empty = DriverHomeState(driverName: "", carLabel: nil, date: "", rows: [], done: 0)

    static func make(_ db: MrasemDatabase, driverId: String, today: String) -> DriverHomeState {
        guard let driver = db.driver(driverId) else { return .empty }
        let rows = DriverScreens.rows(db, driverId: driverId, on: today)
        return DriverHomeState(
            driverName: driver.name,
            carLabel: DriverScreens.carLabel(db, driverId: driverId),
            date: today,
            rows: rows,
            done: rows.count { $0.status == .completed }
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

    static func carLabel(_ db: MrasemDatabase, driverId: String) -> String? {
        AdminDelegationDetailBuilder.carLabel(db.cars.first { $0.driverId == driverId })
    }
}
