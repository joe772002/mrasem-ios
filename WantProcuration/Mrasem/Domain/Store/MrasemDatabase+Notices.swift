//
//  MrasemDatabase+Notices.swift
//  Mrasem
//
//  Phase 12 — توزيع التنبيهات على المستخدمين (قاعدة G4، جدول 08 §2):
//  مين المعني بكل حدث، وإرسال التنبيه، وحالة القراءة لكل مستخدم.
//

import Foundation

extension MrasemDatabase {

    // MARK: - مين المعني

    func memberRefs(of delegationId: String) -> [UserRef] {
        members.filter { $0.delegationId == delegationId }.map { .member($0.id) }
    }

    /// مرافقو أعضاء الوفد.
    func escortRefs(of delegationId: String) -> [UserRef] {
        unique(members.filter { $0.delegationId == delegationId }.compactMap { $0.escortId }.filter { escort($0) != nil })
            .map { .escort($0) }
    }

    func escortRefs(of members: [MemberRecord]) -> [UserRef] {
        unique(members.compactMap { $0.escortId }.filter { escort($0) != nil }).map { .escort($0) }
    }

    /// سائقو السيارات اللي على أعضاء الوفد أو فقراته.
    func driverRefs(of delegationId: String) -> [UserRef] {
        let carIds = members.filter { $0.delegationId == delegationId }.compactMap(\.carId)
            + program.filter { $0.delegationId == delegationId }.compactMap(\.carId)
        return unique(unique(carIds).compactMap { driverRef(ofCar: $0) })
    }

    func driverRef(ofCar carId: String?) -> UserRef? {
        guard let driverId = car(carId)?.driverId, driver(driverId) != nil else { return nil }
        return .driver(driverId)
    }

    func coordinatorRefs(of delegationId: String) -> [UserRef] {
        (delegation(delegationId)?.coordinatorIds ?? []).filter { teamUser($0) != nil }.map { .team($0) }
    }

    func adminRefs() -> [UserRef] {
        team.filter { $0.role == .admin }.map { .team($0.id) }
    }

    /// ركّاب الفقرة: أعضاء الوفد اللي على نفس السيارة، أو كل الوفد لو الفقرة من غير سيارة.
    func passengers(of itemId: String) -> [MemberRecord] {
        guard let item = programItem(itemId) else { return [] }
        let all = members.filter { $0.delegationId == item.delegationId }
        guard let carId = item.carId else { return all }
        let inCar = all.filter { $0.carId == carId }
        return inCar.isEmpty ? all : inCar
    }

    /// جمهور التنبيه العام.
    func refs(for audience: NoticeAudience, delegationId: String) -> [UserRef] {
        switch audience {
        case .all: return memberRefs(of: delegationId)
        case .escorts: return escortRefs(of: delegationId)
        case .drivers: return driverRefs(of: delegationId)
        case .custom: return []
        }
    }

    // MARK: - الإرسال

    /// يضيف تنبيه للمستخدمين المعنيين. صاحب الفعل (المستخدم الحالي) ما بيستلمش تنبيهه،
    /// والتكرار بيتشال. لو مفيش مستلمين، مفيش تنبيه.
    mutating func post(
        _ body: NoticeBody,
        delegationId: String?,
        audience: NoticeAudience = .custom,
        to recipients: [UserRef],
        at date: Date
    ) {
        let list = unique(recipients).filter { $0 != currentUser && exists($0) }
        guard !list.isEmpty else { return }

        notices.append(NoticeRecord(
            id: Self.newId("n"),
            delegationId: delegationId,
            audience: audience,
            recipients: list,
            readBy: [],
            body: body,
            createdAt: date
        ))
    }

    // MARK: - القراءة

    /// تنبيهات المستخدم، الأحدث الأول.
    func notices(for user: UserRef) -> [NoticeRecord] {
        notices.filter { $0.recipients.contains(user) }.sorted { $0.createdAt > $1.createdAt }
    }

    func unreadCount(for user: UserRef) -> Int {
        notices.count { $0.recipients.contains(user) && !$0.readBy.contains(user) }
    }

    mutating func markAllRead(for user: UserRef) {
        for index in notices.indices where notices[index].recipients.contains(user) && !notices[index].readBy.contains(user) {
            notices[index].readBy.append(user)
        }
    }

    private func unique<T: Hashable>(_ list: [T]) -> [T] {
        var seen = Set<T>()
        return list.filter { seen.insert($0).inserted }
    }
}
