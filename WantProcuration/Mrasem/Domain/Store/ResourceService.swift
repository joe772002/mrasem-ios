//
//  ResourceService.swift
//  Mrasem
//
//  Phase 12 — الموارد والدليل والإعدادات (البوابة: «السائقون والسيارات والمرافقون» + «الأماكن والجهات» + «الإعدادات»).
//  نفس نمط `save`: معرّف فاضي أو مش موجود = إضافة. الحذف متسلسل (`MrasemDatabase+Delete`).
//

import Foundation

nonisolated final class ResourceService {
    private let store: MrasemStore

    init(store: MrasemStore) {
        self.store = store
    }

    // MARK: - الحفظ

    @discardableResult
    func saveDriver(_ record: DriverRecord) -> Result<DriverRecord, StoreValidationError> {
        upsert(record, prefix: "r", keyPath: \.drivers, name: record.name) { $0.name = $0.name.storeTrimmed }
    }

    @discardableResult
    func saveCar(_ record: CarRecord) -> Result<CarRecord, StoreValidationError> {
        upsert(record, prefix: "c", keyPath: \.cars, name: record.type) {
            $0.type = $0.type.storeTrimmed
            $0.plate = $0.plate.storeTrimmed
        }
    }

    @discardableResult
    func saveEscort(_ record: EscortRecord) -> Result<EscortRecord, StoreValidationError> {
        upsert(record, prefix: "e", keyPath: \.escorts, name: record.name) { $0.name = $0.name.storeTrimmed }
    }

    @discardableResult
    func savePlace(_ record: PlaceRecord) -> Result<PlaceRecord, StoreValidationError> {
        guard record.minutes >= 0, record.durationHours >= 0 else { return .failure(.invalidTime) }
        return upsert(record, prefix: "pl", keyPath: \.places, name: record.name) { $0.name = $0.name.storeTrimmed }
    }

    @discardableResult
    func saveDestination(_ record: DestinationRecord) -> Result<DestinationRecord, StoreValidationError> {
        upsert(record, prefix: "dest", keyPath: \.destinations, name: record.name) { $0.name = $0.name.storeTrimmed }
    }

    /// عضو فريق. ممنوع يتحوّل آخر أدمن لدور تاني.
    @discardableResult
    func saveTeamUser(_ record: TeamUserRecord) -> Result<TeamUserRecord, StoreValidationError> {
        let db = store.database
        if let old = db.teamUser(record.id), old.role == .admin, record.role != .admin,
           db.team.count(where: { $0.role == .admin }) == 1 {
            return .failure(.lastAdmin)
        }
        return upsert(record, prefix: "u", keyPath: \.team, name: record.name) { $0.name = $0.name.storeTrimmed }
    }

    // MARK: - تعديلات سريعة

    func setDriverStatus(_ driverId: String, _ status: DriverStatus) {
        store.update { db in
            guard let i = db.drivers.firstIndex(where: { $0.id == driverId }) else { return }
            db.drivers[i].status = status
        }
    }

    /// سائق السيارة (من كارت السيارة).
    func assignDriver(_ driverId: String?, toCar carId: String) {
        store.update { db in
            guard let i = db.cars.firstIndex(where: { $0.id == carId }) else { return }
            db.cars[i].driverId = driverId.flatMap { db.driver($0) == nil ? nil : $0 }
        }
    }

    func updatePreferences(_ change: (inout PreferencesRecord) -> Void) {
        store.update { change(&$0.preferences) }
    }

    // MARK: - الحذف

    @discardableResult func deleteDriver(_ id: String) -> Bool { delete { $0.deleteDriver(id) } }
    @discardableResult func deleteCar(_ id: String) -> Bool { delete { $0.deleteCar(id) } }
    @discardableResult func deleteEscort(_ id: String) -> Bool { delete { $0.deleteEscort(id) } }
    @discardableResult func deletePlace(_ id: String) -> Bool { delete { $0.deletePlace(id) } }
    @discardableResult func deleteDestination(_ id: String) -> Bool { delete { $0.deleteDestination(id) } }
    @discardableResult func deleteTeamUser(_ id: String) -> Bool { delete { $0.deleteTeamUser(id) } }

    // MARK: - القراءة

    /// السائقين المشغولين في يوم معيّن (جدول التعيينات).
    static func trips(of driverId: String, on date: String, in db: MrasemDatabase) -> [ProgramItemRecord] {
        db.program
            .filter { $0.date == date && db.car($0.carId)?.driverId == driverId }
            .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
    }

    /// وفود المرافق (من أعضائه).
    static func delegations(ofEscort escortId: String, in db: MrasemDatabase) -> [DelegationRecord] {
        let ids = Set(db.members.filter { $0.escortId == escortId }.map(\.delegationId))
        return db.delegations.filter { ids.contains($0.id) }
    }

    // MARK: - داخلي

    private func upsert<T: IdentifiedRecord>(
        _ record: T,
        prefix: String,
        keyPath: WritableKeyPath<MrasemDatabase, [T]>,
        name: String,
        clean: (inout T) -> Void
    ) -> Result<T, StoreValidationError> {
        guard !name.storeTrimmed.isEmpty else { return .failure(.emptyName) }

        var saved = record
        clean(&saved)
        if saved.id.isEmpty { saved.id = MrasemDatabase.newId(prefix) }

        store.update { db in
            if let index = db[keyPath: keyPath].firstIndex(where: { $0.id == saved.id }) {
                db[keyPath: keyPath][index] = saved
            } else {
                db[keyPath: keyPath].append(saved)
            }
        }
        return .success(saved)
    }

    private func delete(_ action: (inout MrasemDatabase) -> Bool) -> Bool {
        var deleted = false
        store.update { deleted = action(&$0) }
        return deleted
    }
}

/// كيان معرّفه قابل للتعديل (كل الـ `…Record` اللي ليها `id`).
protocol IdentifiedRecord {
    var id: String { get set }
}

extension DelegationRecord: IdentifiedRecord {}
extension MemberRecord: IdentifiedRecord {}
extension EscortRecord: IdentifiedRecord {}
extension DriverRecord: IdentifiedRecord {}
extension CarRecord: IdentifiedRecord {}
extension PlaceRecord: IdentifiedRecord {}
extension ProgramItemRecord: IdentifiedRecord {}
extension RequestRecord: IdentifiedRecord {}
extension NoticeRecord: IdentifiedRecord {}
extension TeamUserRecord: IdentifiedRecord {}
extension DestinationRecord: IdentifiedRecord {}
