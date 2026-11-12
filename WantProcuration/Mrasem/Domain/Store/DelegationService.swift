//
//  DelegationService.swift
//  Mrasem
//
//  Phase 12 — الوفود والأعضاء والتعيينات (البوابة: «الوفود والبرامج» + «الأعضاء والتعيينات» + «الإقامة»).
//  `save` بيضيف لو المعرّف فاضي أو مش موجود، وبيعدّل لو موجود.
//

import Foundation

nonisolated final class DelegationService {
    private let store: MrasemStore
    private let now: () -> Date

    init(store: MrasemStore, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.now = now
    }

    // MARK: - الوفد

    func validate(_ record: DelegationRecord) -> StoreValidationError? {
        if record.name.storeTrimmed.isEmpty { return .emptyName }
        guard StoreTime.isValidDate(record.start), StoreTime.isValidDate(record.end) else { return .invalidDate }
        if record.end < record.start { return .endBeforeStart }
        return nil
    }

    /// يحفظ الوفد. لو زي اليوم اتغيّر، أعضاء الوفد ومرافقيهم بيوصلهم تنبيه (dressApproved).
    @discardableResult
    func save(_ record: DelegationRecord) -> Result<DelegationRecord, StoreValidationError> {
        if let error = validate(record) { return .failure(error) }

        var saved = record
        saved.name = record.name.storeTrimmed
        let date = now()

        store.update { db in
            if saved.id.isEmpty || db.delegation(saved.id) == nil {
                if saved.id.isEmpty { saved.id = MrasemDatabase.newId("d") }
                db.delegations.append(saved)
                return
            }
            guard let index = db.delegations.firstIndex(where: { $0.id == saved.id }) else { return }
            let old = db.delegations[index]
            db.delegations[index] = saved

            if old.dress != saved.dress {
                db.post(.dressApproved(saved.dress), delegationId: saved.id,
                        to: db.memberRefs(of: saved.id) + db.escortRefs(of: saved.id), at: date)
            }
        }
        return .success(saved)
    }

    func setStatus(_ id: String, _ status: DelegationStatus) {
        store.update { db in
            guard let index = db.delegations.firstIndex(where: { $0.id == id }) else { return }
            db.delegations[index].status = status
        }
    }

    /// حذف الوفد بكل حاجته (= «مسح بيانات وفد»).
    @discardableResult
    func delete(_ id: String) -> Bool {
        var deleted = false
        store.update { deleted = $0.deleteDelegation(id) }
        return deleted
    }

    // MARK: - الأعضاء والتعيينات

    func validate(_ member: MemberRecord, in db: MrasemDatabase) -> StoreValidationError? {
        if member.name.storeTrimmed.isEmpty { return .emptyName }
        if db.delegation(member.delegationId) == nil { return .notFound }
        return nil
    }

    /// يحفظ العضو. تغيير السيارة أو المرافق أو الغرفة بيبعت تنبيه للعضو وللسائق القديم والجديد.
    /// رئيس الوفد واحد بس: تعليم عضو كرئيس بيشيل العلامة من الباقيين.
    @discardableResult
    func saveMember(_ member: MemberRecord) -> Result<MemberRecord, StoreValidationError> {
        if let error = validate(member, in: store.database) { return .failure(error) }

        var saved = member
        saved.name = member.name.storeTrimmed
        saved.room = member.room.storeTrimmed
        let date = now()

        store.update { db in
            if saved.isHead {
                for i in db.members.indices where db.members[i].delegationId == saved.delegationId {
                    db.members[i].isHead = false
                }
            }

            if saved.id.isEmpty || db.member(saved.id) == nil {
                if saved.id.isEmpty { saved.id = MrasemDatabase.newId("m") }
                if !db.members.contains(where: { $0.delegationId == saved.delegationId }) {
                    saved.isHead = true
                }
                db.members.append(saved)
                return
            }
            guard let index = db.members.firstIndex(where: { $0.id == saved.id }) else { return }
            let old = db.members[index]
            db.members[index] = saved

            guard old.carId != saved.carId || old.escortId != saved.escortId || old.room != saved.room else { return }
            let drivers = [db.driverRef(ofCar: old.carId), db.driverRef(ofCar: saved.carId)].compactMap { $0 }
            let escorts = [old.escortId, saved.escortId].compactMap { $0 }.filter { db.escort($0) != nil }.map { UserRef.escort($0) }
            db.post(.assignmentChanged(memberId: saved.id), delegationId: saved.delegationId,
                    to: [.member(saved.id)] + drivers + escorts, at: date)
        }
        return .success(saved)
    }

    @discardableResult
    func deleteMember(_ id: String) -> Bool {
        var deleted = false
        store.update { deleted = $0.deleteMember(id) }
        return deleted
    }

    // MARK: - القراءة

    func members(of delegationId: String) -> [MemberRecord] {
        store.database.members.filter { $0.delegationId == delegationId }
    }

    /// رئيس الوفد، أو أول عضو لو مفيش رئيس متعلّم.
    static func head(of delegationId: String, in db: MrasemDatabase) -> MemberRecord? {
        let list = db.members.filter { $0.delegationId == delegationId }
        return list.first { $0.isHead } ?? list.first
    }

    /// أيام الوفد من البداية للنهاية.
    static func days(of delegation: DelegationRecord) -> [String] {
        StoreTime.days(from: delegation.start, to: delegation.end)
    }
}
