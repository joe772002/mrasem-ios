//
//  ProgramService.swift
//  Mrasem
//
//  Phase 12 — برنامج الوفد (البوابة: «إضافة فقرة / تعديل / تأجيل ٣٠ دقيقة / حذف»).
//  التعديل بيعلّم الفقرة «محدَّث» وبيبعت تنبيه للوفد والمرافقين والسائق (لو «إشعار الوفد تلقائياً» شغال).
//

import Foundation

nonisolated final class ProgramService {
    static let postponeMinutes = 30

    private let store: MrasemStore
    private let now: () -> Date

    init(store: MrasemStore, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.now = now
    }

    func validate(_ item: ProgramItemRecord, in db: MrasemDatabase) -> StoreValidationError? {
        if item.title.storeTrimmed.isEmpty { return .emptyName }
        guard let delegation = db.delegation(item.delegationId) else { return .notFound }
        guard StoreTime.isValidDate(item.date) else { return .invalidDate }
        guard StoreTime.isValidTime(item.time) else { return .invalidTime }
        if item.kind == .free {
            guard let end = item.endTime, let to = StoreTime.minutes(end), let from = StoreTime.minutes(item.time) else {
                return .invalidTime
            }
            if to <= from { return .endBeforeStart }
        }
        if item.date < delegation.start || item.date > delegation.end { return .dateOutsideDelegation }
        return nil
    }

    /// يضيف أو يعدّل فقرة. `notify` = خانة «إشعار الوفد والسائق والمرافق بعد الحفظ» (الافتراضي من الإعدادات).
    @discardableResult
    func save(_ item: ProgramItemRecord, notify: Bool? = nil) -> Result<ProgramItemRecord, StoreValidationError> {
        if let error = validate(item, in: store.database) { return .failure(error) }

        var saved = item
        saved.title = item.title.storeTrimmed
        saved.note = item.note.storeTrimmed
        if saved.kind != .free { saved.endTime = nil }
        let date = now()

        store.update { db in
            let shouldNotify = notify ?? db.preferences.autoNotifyGuests
            if saved.isKey {
                for i in db.program.indices where db.program[i].delegationId == saved.delegationId {
                    db.program[i].isKey = false
                }
            }

            var oldCarId: String?
            if saved.id.isEmpty || db.programItem(saved.id) == nil {
                if saved.id.isEmpty { saved.id = MrasemDatabase.newId("p") }
                saved.isChanged = false
                db.program.append(saved)
            } else if let index = db.program.firstIndex(where: { $0.id == saved.id }) {
                let old = db.program[index]
                oldCarId = old.carId
                saved.isChanged = old.isChanged || Self.contentChanged(old, saved)
                db.program[index] = saved
            }

            if shouldNotify {
                Self.notifyChange(&db, item: saved, extraDriverCar: oldCarId, body: .programChanged(itemId: saved.id), at: date)
            }
        }
        return .success(saved)
    }

    /// «تأجيل ٣٠ دقيقة». بيرجع الوقت الجديد، أو `nil` لو الفقرة مش موجودة.
    @discardableResult
    func postpone(_ itemId: String, minutes: Int = ProgramService.postponeMinutes, notify: Bool = true) -> String? {
        var newTime: String?
        let date = now()

        store.update { db in
            guard let index = db.program.firstIndex(where: { $0.id == itemId }),
                  let time = StoreTime.add(db.program[index].time, minutes: minutes)
            else { return }

            db.program[index].time = time
            db.program[index].isChanged = true
            newTime = time

            if notify {
                let item = db.program[index]
                Self.notifyChange(&db, item: item, extraDriverCar: nil,
                                  body: .postponed(title: item.title, newTime: time), at: date)
            }
        }
        return newTime
    }

    @discardableResult
    func delete(_ itemId: String) -> Bool {
        var deleted = false
        store.update { deleted = $0.deleteProgramItem(itemId) }
        return deleted
    }

    // MARK: - القراءة

    func items(of delegationId: String, on date: String? = nil) -> [ProgramItemRecord] {
        Self.items(store.database, delegationId: delegationId, on: date)
    }

    static func items(_ db: MrasemDatabase, delegationId: String, on date: String? = nil) -> [ProgramItemRecord] {
        db.program
            .filter { $0.delegationId == delegationId && (date == nil || $0.date == date) }
            .sorted { StoreTime.sortKey($0) < StoreTime.sortKey($1) }
    }

    // MARK: - داخلي

    private static func contentChanged(_ a: ProgramItemRecord, _ b: ProgramItemRecord) -> Bool {
        a.date != b.date || a.time != b.time || a.endTime != b.endTime || a.title != b.title
            || a.kind != b.kind || a.placeId != b.placeId || a.note != b.note || a.carId != b.carId
    }

    /// أعضاء الوفد + مرافقيهم + سائق الفقرة (والسائق القديم لو السيارة اتغيّرت).
    private static func notifyChange(
        _ db: inout MrasemDatabase,
        item: ProgramItemRecord,
        extraDriverCar: String?,
        body: NoticeBody,
        at date: Date
    ) {
        let drivers = [db.driverRef(ofCar: item.carId), db.driverRef(ofCar: extraDriverCar)].compactMap { $0 }
        let recipients = db.memberRefs(of: item.delegationId) + db.escortRefs(of: item.delegationId) + drivers
        db.post(body, delegationId: item.delegationId, to: recipients, at: date)
    }
}
