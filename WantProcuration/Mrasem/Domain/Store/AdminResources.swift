//
//  AdminResources.swift
//  Mrasem
//
//  Phase 15 — تاب «الموارد» للأدمن: السائقون والسيارات والمرافقون وجدول التعيينات والتعارضات.
//  دوال نقية على القاعدة (بتتختبر من غير UI).
//

import Foundation

struct AdminDriverRow: Equatable, Identifiable {
    let id: String
    let name: String
    let phone: String
    let status: DriverStatus
    let carLabel: String?
    let tripsToday: Int
}

struct AdminCarRow: Equatable, Identifiable {
    let id: String
    let type: String
    let plate: String
    let plateStyle: PlateStyle
    let driverName: String?
    let tripCount: Int
}

struct AdminEscortRow: Equatable, Identifiable {
    let id: String
    let name: String
    let title: String
    let phone: String
    let delegationNames: [String]
}

/// فقرة عليها سيارة، في جدول التعيينات.
struct AdminAssignmentRow: Equatable, Identifiable {
    let id: String
    let date: String
    let time: String
    let title: String
    let delegationName: String
    let driverName: String?
    let carLabel: String?
    let hasConflict: Bool
}

struct AdminConflictRow: Equatable, Identifiable {
    let id: String
    let driverName: String
    let date: String
    let first: AdminConflictSide
    let second: AdminConflictSide
}

struct AdminConflictSide: Equatable {
    let itemId: String
    let time: String
    let title: String
    let delegationName: String
}

struct AdminResourcesState: Equatable {
    let drivers: [AdminDriverRow]
    let cars: [AdminCarRow]
    let escorts: [AdminEscortRow]
    let assignments: [AdminAssignmentRow]
    let conflicts: [AdminConflictRow]

    static func make(_ db: MrasemDatabase, today: String) -> AdminResourcesState {
        AdminResourcesState(
            drivers: AdminResourcesBuilder.drivers(db, today: today),
            cars: AdminResourcesBuilder.cars(db),
            escorts: AdminResourcesBuilder.escorts(db),
            assignments: AdminResourcesBuilder.assignments(db, today: today),
            conflicts: AdminResourcesBuilder.conflicts(db)
        )
    }
}

nonisolated enum AdminResourcesBuilder {

    static func drivers(_ db: MrasemDatabase, today: String) -> [AdminDriverRow] {
        db.drivers.map { driver in
            AdminDriverRow(
                id: driver.id, name: driver.name, phone: driver.phone, status: driver.status,
                carLabel: AdminDelegationDetailBuilder.carLabel(db.cars.first { $0.driverId == driver.id }),
                tripsToday: ResourceService.trips(of: driver.id, on: today, in: db).count
            )
        }
    }

    static func cars(_ db: MrasemDatabase) -> [AdminCarRow] {
        db.cars.map { car in
            AdminCarRow(
                id: car.id, type: car.type, plate: car.plate, plateStyle: car.plateStyle,
                driverName: db.driver(car.driverId)?.name,
                tripCount: db.program.count { $0.carId == car.id }
            )
        }
    }

    static func escorts(_ db: MrasemDatabase) -> [AdminEscortRow] {
        db.escorts.map { escort in
            AdminEscortRow(
                id: escort.id, name: escort.name, title: escort.title, phone: escort.phone,
                delegationNames: ResourceService.delegations(ofEscort: escort.id, in: db).map(\.name)
            )
        }
    }

    /// الفقرات اللي عليها سيارة من النهاردة وبعده، بالترتيب الزمني.
    static func assignments(_ db: MrasemDatabase, today: String) -> [AdminAssignmentRow] {
        let conflictIds = PortalInsights.conflictItemIds(db)
        return db.program
            .filter { $0.carId != nil && $0.date >= today }
            .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
            .map { item in
                AdminAssignmentRow(
                    id: item.id, date: item.date, time: item.time, title: item.title,
                    delegationName: db.delegation(item.delegationId)?.name ?? "",
                    driverName: PortalInsights.driver(of: item, in: db)?.name,
                    carLabel: AdminDelegationDetailBuilder.carLabel(db.car(item.carId)),
                    hasConflict: conflictIds.contains(item.id)
                )
            }
    }

    static func conflicts(_ db: MrasemDatabase) -> [AdminConflictRow] {
        PortalInsights.conflicts(db).map { conflict in
            AdminConflictRow(
                id: conflict.first.id + "|" + conflict.second.id,
                driverName: conflict.driver.name,
                date: conflict.first.date,
                first: side(conflict.first, db),
                second: side(conflict.second, db)
            )
        }
    }

    /// سيارات بديلة لفقرة: سواقها متاح وما عندوش رحلة قريبة في نفس اليوم (حل التعارض).
    static func alternatives(_ db: MrasemDatabase, forItem itemId: String) -> [CarRecord] {
        guard let item = db.programItem(itemId), let start = StoreTime.minutes(item.time) else { return [] }

        return db.cars.filter { car in
            guard car.id != item.carId, let driver = db.driver(car.driverId), driver.status == .available else { return false }
            let busy = db.program.contains { other in
                guard other.id != item.id, other.carId == car.id, other.date == item.date,
                      let time = StoreTime.minutes(other.time) else { return false }
                return abs(time - start) < PortalInsights.conflictWindowMinutes
            }
            return !busy
        }
    }

    private static func side(_ item: ProgramItemRecord, _ db: MrasemDatabase) -> AdminConflictSide {
        AdminConflictSide(
            itemId: item.id, time: item.time, title: item.title,
            delegationName: db.delegation(item.delegationId)?.name ?? ""
        )
    }
}
