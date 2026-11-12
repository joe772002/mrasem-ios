//
//  DriverTripService.swift
//  Mrasem
//
//  Phase 12 — «رحلاتي» للسائق وحالة الرحلة (08 §2، تصميم `enhance` §7):
//  الرحلات = فقرات البرنامج اللي على سيارة السائق. الاستلام قبل الفقرة بـ ٢٥ دقيقة والوصول قبلها بـ ١٥.
//  تغيير الحالة («في الطريق» / «وصلت» …) بيوصل للركّاب ومرافقيهم والمنسقين والأدمن.
//

import Foundation

struct DriverTrip: Equatable, Identifiable {
    let item: ProgramItemRecord
    let delegationName: String
    let pickupTime: String
    let arrivalTime: String
    /// من: الوجهة السابقة في نفس اليوم، أو الفندق.
    let from: String
    /// إلى: المكان، أو الملاحظة، أو عنوان الفقرة.
    let to: String
    let passengers: [MemberRecord]
    let escorts: [EscortRecord]
    let status: TripStatus

    var id: String { item.id }
}

nonisolated final class DriverTripService {
    static let pickupLeadMinutes = 25
    static let arrivalLeadMinutes = 15

    private let store: MrasemStore
    private let now: () -> Date

    init(store: MrasemStore, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.now = now
    }

    func trips(of driverId: String, on date: String? = nil) -> [DriverTrip] {
        Self.trips(store.database, driverId: driverId, on: date)
    }

    static func trips(_ db: MrasemDatabase, driverId: String, on date: String? = nil) -> [DriverTrip] {
        let items = db.program
            .filter { db.car($0.carId)?.driverId == driverId && (date == nil || $0.date == date) }
            .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }

        var lastPlace: [String: String] = [:]
        return items.map { item in
            let delegation = db.delegation(item.delegationId)
            let key = item.date + "|" + item.delegationId
            let hotel = db.place(delegation?.hotelId)?.name ?? ""
            let from = lastPlace[key] ?? hotel
            let to = db.place(item.placeId)?.name ?? (item.note.isEmpty ? item.title : item.note)
            lastPlace[key] = to

            let passengers = db.passengers(of: item.id)
            let escortIds = Array(Set(passengers.compactMap(\.escortId))).sorted()
            return DriverTrip(
                item: item,
                delegationName: delegation?.name ?? "",
                pickupTime: StoreTime.add(item.time, minutes: -pickupLeadMinutes) ?? item.time,
                arrivalTime: StoreTime.add(item.time, minutes: -arrivalLeadMinutes) ?? item.time,
                from: from,
                to: to,
                passengers: passengers,
                escorts: escortIds.compactMap { db.escort($0) },
                status: status(of: item.id, in: db)
            )
        }
    }

    /// الأيام اللي فيها رحلات للسائق.
    static func dates(_ db: MrasemDatabase, driverId: String) -> [String] {
        Array(Set(trips(db, driverId: driverId).map(\.item.date))).sorted()
    }

    static func status(of itemId: String, in db: MrasemDatabase) -> TripStatus {
        db.trips.first { $0.id == itemId }?.status ?? .scheduled
    }

    /// «في الطريق» / «وصلت» / «تم الاستلام» / «انتهت». بيرجع false لو الفقرة مش موجودة أو الحالة هي هي.
    @discardableResult
    func setStatus(_ itemId: String, _ status: TripStatus) -> Bool {
        var changed = false
        let date = now()

        store.update { db in
            guard let item = db.programItem(itemId), Self.status(of: itemId, in: db) != status else { return }

            if let index = db.trips.firstIndex(where: { $0.id == itemId }) {
                db.trips[index].status = status
                db.trips[index].updatedAt = date
            } else {
                db.trips.append(TripRecord(id: itemId, status: status, updatedAt: date))
            }
            changed = true

            guard status != .scheduled else { return }
            let passengers = db.passengers(of: itemId)
            let recipients = passengers.map { UserRef.member($0.id) }
                + db.escortRefs(of: passengers)
                + db.coordinatorRefs(of: item.delegationId)
                + db.adminRefs()
            db.post(.tripStatus(itemId: itemId, status: status), delegationId: item.delegationId, to: recipients, at: date)
        }
        return changed
    }
}
