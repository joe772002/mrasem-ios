//
//  MrasemDatabase+Delete.swift
//  Mrasem
//
//  Phase 11 — الحذف المتسلسل (قاعدة F3): مفيش عنصر يتيم بعد أي حذف.
//  كل دالة بترجع false لو العنصر مش موجود (أو الحذف ممنوع).
//

import Foundation

extension MrasemDatabase {

    /// حذف وفد ← أعضاؤه وبرنامجه وطلباته وتنبيهاته ورحلاته (= «مسح بيانات وفد»).
    @discardableResult
    mutating func deleteDelegation(_ id: String) -> Bool {
        guard delegation(id) != nil else { return false }

        let memberIds = members.filter { $0.delegationId == id }.map(\.id)
        for memberId in memberIds {
            deleteMember(memberId)
        }

        let itemIds = Set(program.filter { $0.delegationId == id }.map(\.id))
        program.removeAll { itemIds.contains($0.id) }
        trips.removeAll { itemIds.contains($0.id) }
        requests.removeAll { $0.delegationId == id }
        notices.removeAll { $0.delegationId == id }
        delegations.removeAll { $0.id == id }
        return true
    }

    /// حذف عضو ← طلباته وقائمة فحصه ومحادثته، ويتشال من مستلمي التنبيهات.
    @discardableResult
    mutating func deleteMember(_ id: String) -> Bool {
        guard member(id) != nil else { return false }

        members.removeAll { $0.id == id }
        requests.removeAll { $0.memberId == id }
        checklists.removeAll { $0.id == id }
        chats.removeAll { $0.memberId == id }
        removeUser(.member(id))
        return true
    }

    /// حذف مرافق ← الأعضاء اللي معاه يبقوا «بدون مرافق».
    @discardableResult
    mutating func deleteEscort(_ id: String) -> Bool {
        guard escort(id) != nil else { return false }

        escorts.removeAll { $0.id == id }
        for index in members.indices where members[index].escortId == id {
            members[index].escortId = nil
        }
        removeUser(.escort(id))
        return true
    }

    /// حذف سائق ← سيارته تبقى «بدون سائق».
    @discardableResult
    mutating func deleteDriver(_ id: String) -> Bool {
        guard driver(id) != nil else { return false }

        drivers.removeAll { $0.id == id }
        for index in cars.indices where cars[index].driverId == id {
            cars[index].driverId = nil
        }
        removeUser(.driver(id))
        return true
    }

    /// حذف سيارة ← الأعضاء والفقرات اللي عليها يبقوا «بدون سيارة».
    @discardableResult
    mutating func deleteCar(_ id: String) -> Bool {
        guard car(id) != nil else { return false }

        cars.removeAll { $0.id == id }
        for index in members.indices where members[index].carId == id {
            members[index].carId = nil
        }
        for index in program.indices where program[index].carId == id {
            program[index].carId = nil
        }
        return true
    }

    /// حذف مكان ← الفقرات والوفود والطلبات اللي بتشير له تفقد المرجع (النص بيفضل).
    @discardableResult
    mutating func deletePlace(_ id: String) -> Bool {
        guard place(id) != nil else { return false }

        places.removeAll { $0.id == id }
        for index in program.indices where program[index].placeId == id {
            program[index].placeId = nil
        }
        for index in delegations.indices {
            if delegations[index].hotelId == id { delegations[index].hotelId = nil }
            if delegations[index].venueId == id { delegations[index].venueId = nil }
        }
        for index in requests.indices where requests[index].placeId == id {
            requests[index].placeId = nil
        }
        return true
    }

    /// حذف وجهة ← الوفود اللي عليها تبقى «بدون محتوى وجهة».
    @discardableResult
    mutating func deleteDestination(_ id: String) -> Bool {
        guard destination(id) != nil else { return false }

        destinations.removeAll { $0.id == id }
        for index in delegations.indices where delegations[index].destinationId == id {
            delegations[index].destinationId = nil
        }
        return true
    }

    /// حذف فقرة ← حالة رحلتها.
    @discardableResult
    mutating func deleteProgramItem(_ id: String) -> Bool {
        guard programItem(id) != nil else { return false }

        program.removeAll { $0.id == id }
        trips.removeAll { $0.id == id }
        return true
    }

    @discardableResult
    mutating func deleteRequest(_ id: String) -> Bool {
        guard requests.contains(where: { $0.id == id }) else { return false }
        requests.removeAll { $0.id == id }
        return true
    }

    @discardableResult
    mutating func deleteNotice(_ id: String) -> Bool {
        guard notices.contains(where: { $0.id == id }) else { return false }
        notices.removeAll { $0.id == id }
        return true
    }

    /// حذف عضو فريق. آخر أدمن ما بيتحذفش.
    @discardableResult
    mutating func deleteTeamUser(_ id: String) -> Bool {
        guard let user = teamUser(id) else { return false }
        if user.role == .admin, team.filter({ $0.role == .admin }).count == 1 {
            return false
        }

        team.removeAll { $0.id == id }
        for index in delegations.indices {
            delegations[index].coordinatorIds.removeAll { $0 == id }
        }
        removeUser(.team(id))
        return true
    }

    /// يشيل المستخدم من مستلمي وقرّاء التنبيهات، والتنبيه اللي فضل من غير مستلمين يتحذف.
    /// لو هو المستخدم الحالي، الحالي يبقى `nil` (يظهر «اختر المستخدم»).
    private mutating func removeUser(_ user: UserRef) {
        for index in notices.indices {
            notices[index].recipients.removeAll { $0 == user }
            notices[index].readBy.removeAll { $0 == user }
        }
        notices.removeAll { $0.audience == .custom && $0.recipients.isEmpty }

        if currentUser == user {
            currentUser = nil
        }
    }
}
