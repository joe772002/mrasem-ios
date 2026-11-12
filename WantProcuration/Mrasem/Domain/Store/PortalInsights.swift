//
//  PortalInsights.swift
//  Mrasem
//
//  Phase 12 — حسابات لوحة الأدمن، منقولة من بوابة الإدارة (conflicts / gaps / readiness):
//  تعارض السائقين، نواقص الوفد، الجاهزية، ملخص لوحة التحكم، تحركات اليوم.
//

import Foundation

/// نفس السائق مع وفدين مختلفين في أقل من ساعة.
struct DriverConflict: Equatable {
    let first: ProgramItemRecord
    let second: ProgramItemRecord
    let driver: DriverRecord
}

struct DelegationGaps: Equatable {
    let noCar: Int
    let noRoom: Int
    let noEscort: Int
    let total: Int
    let noHotel: Bool

    var missingCount: Int { noCar + noRoom + noEscort + (noHotel ? 1 : 0) }
}

struct DashboardSummary: Equatable {
    let activeDelegations: Int
    let inbound: Int
    let outbound: Int
    let members: Int
    let activatedMembers: Int
    let availableDrivers: Int
    let totalDrivers: Int
    let conflicts: Int
    let newRequests: Int
    let newVisitRequests: Int
    let newQuestions: Int
}

nonisolated enum PortalInsights {

    /// الحد الأدنى بين رحلتين لنفس السائق (البوابة: أقل من ساعة = تعارض).
    static let conflictWindowMinutes = 60

    static func driver(of item: ProgramItemRecord, in db: MrasemDatabase) -> DriverRecord? {
        db.driver(db.car(item.carId)?.driverId)
    }

    /// الفقرات بتتجمّع حسب (اليوم، السائق) فالمقارنة جوّه المجموعة بس، وبتقف أول ما الفرق يوصل ساعة
    /// (الفقرات مترتبة بالوقت). نفس ترتيب النتيجة القديم (i ثم j)، بس من غير O(n²) على كل البرنامج (Phase 18).
    static func conflicts(_ db: MrasemDatabase) -> [DriverConflict] {
        let drivers = Dictionary(db.drivers.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let cars = Dictionary(db.cars.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        struct Entry {
            let item: ProgramItemRecord
            let driver: DriverRecord
            let minutes: Int
        }
        let entries: [Entry] = db.program
            .filter { $0.carId != nil }
            .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
            .compactMap { item in
                guard let carId = item.carId, let driverId = cars[carId]?.driverId, let driver = drivers[driverId],
                      let minutes = StoreTime.minutes(item.time) else { return nil }
                return Entry(item: item, driver: driver, minutes: minutes)
            }

        var buckets: [String: [Int]] = [:]
        for (index, entry) in entries.enumerated() {
            buckets[entry.item.date + "|" + entry.driver.id, default: []].append(index)
        }

        var out: [DriverConflict] = []
        for (i, a) in entries.enumerated() {
            let bucket = buckets[a.item.date + "|" + a.driver.id] ?? []
            for j in bucket where j > i {
                let b = entries[j]
                guard b.minutes - a.minutes < conflictWindowMinutes else { break }
                guard a.item.delegationId != b.item.delegationId else { continue }
                out.append(DriverConflict(first: a.item, second: b.item, driver: a.driver))
            }
        }
        return out
    }

    static func conflictItemIds(_ db: MrasemDatabase) -> Set<String> {
        Set(conflicts(db).flatMap { [$0.first.id, $0.second.id] })
    }

    static func gaps(_ db: MrasemDatabase, delegationId: String) -> DelegationGaps {
        let members = db.members.filter { $0.delegationId == delegationId }
        return DelegationGaps(
            noCar: members.count { $0.carId == nil },
            noRoom: members.count { $0.room.storeTrimmed.isEmpty },
            noEscort: members.count { $0.escortId == nil },
            total: members.count,
            noHotel: db.delegation(delegationId)?.hotelId == nil
        )
    }

    /// ٠–١٠٠ زي البوابة: ٤٠٪ للأساسيات (فندق، برنامج، أعضاء) و٦٠٪ لاكتمال التعيينات.
    static func readiness(_ db: MrasemDatabase, delegationId: String) -> Int {
        guard let delegation = db.delegation(delegationId) else { return 0 }
        let g = gaps(db, delegationId: delegationId)
        let hasProgram = db.program.contains { $0.delegationId == delegationId }
        let checks = [delegation.hotelId != nil, hasProgram, g.total > 0]

        var score = Double(checks.count { $0 }) / Double(checks.count) * 40
        if g.total > 0 {
            score += 60 * (1 - Double(g.noCar + g.noRoom + g.noEscort) / Double(g.total * 3))
        }
        return Int(score.rounded())
    }

    static func newRequests(_ db: MrasemDatabase, delegationId: String? = nil) -> [RequestRecord] {
        db.requests.filter { $0.status == .new && (delegationId == nil || $0.delegationId == delegationId) }
    }

    static func activeDelegations(_ db: MrasemDatabase) -> [DelegationRecord] {
        db.delegations.filter { $0.status != .archived }
    }

    static func dashboard(_ db: MrasemDatabase) -> DashboardSummary {
        let active = activeDelegations(db)
        let inbound = active.count { $0.mode == .inbound }
        let fresh = newRequests(db)
        return DashboardSummary(
            activeDelegations: active.count,
            inbound: inbound,
            outbound: active.count - inbound,
            members: db.members.count,
            activatedMembers: db.members.count { $0.appStatus == .active },
            availableDrivers: db.drivers.count { $0.status == .available },
            totalDrivers: db.drivers.count,
            conflicts: conflicts(db).count,
            newRequests: fresh.count,
            newVisitRequests: fresh.count { $0.kind == .visit },
            newQuestions: fresh.count { $0.kind == .question }
        )
    }

    /// تحركات يوم معيّن لكل الوفود غير المؤرشفة، بالترتيب.
    static func movements(_ db: MrasemDatabase, on date: String) -> [ProgramItemRecord] {
        let active = Set(activeDelegations(db).map(\.id))
        return db.program
            .filter { $0.date == date && active.contains($0.delegationId) }
            .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
    }

    /// كل الأيام اللي فيها فقرات (للوحة التحكم وجدول التعيينات).
    static func programDates(_ db: MrasemDatabase) -> [String] {
        Array(Set(db.program.map(\.date))).sorted()
    }
}
