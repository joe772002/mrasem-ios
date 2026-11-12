//
//  StoreMissionRepository.swift
//  Mrasem
//
//  Phase 13 — `MissionRepository` فوق القاعدة المحلية. شاشات الضيف والفريق (Phases 4–7) بتفضل زي ما هي،
//  لكن بدل بيانات العرض الثابتة بتقرا وتكتب في `MrasemStore` للمستخدم الحالي (G2).
//
//  قواعد الكتابة (G4): الأفعال اللي ليها services (طلب، «تم الترتيب»، حالة الرحلة، تنبيه عام) بتعدّي عليها
//  عشان التنبيه يروح للمعنيين بس. باقي التعديلات (بيانات الزيارة، الزي، تأجيل فقرة) بتتكتب من غير تنبيه،
//  والتنبيه بيتبعت من `addNotice` اللي الـ strategy بتناديه بعدها، فمفيش تنبيه يتكرر.
//

import Foundation
import Combine

nonisolated final class StoreMissionRepository: MissionRepository {
    private let store: MrasemStore
    private let requests: RequestService
    private let trips: DriverTripService
    private let now: () -> Date
    private let today: () -> MrasemDate
    private let ids = IdTable()
    private let navSubject = CurrentValueSubject<RepoNav, Never>(RepoNav())

    init(
        store: MrasemStore,
        requests: RequestService,
        trips: DriverTripService,
        now: @escaping () -> Date = { Date() },
        today: @escaping () -> MrasemDate = { MrasemDate.today() }
    ) {
        self.store = store
        self.requests = requests
        self.trips = trips
        self.now = now
        self.today = today
    }

    // MARK: - القراءة

    var statePublisher: AnyPublisher<MrasemState, Never> {
        Publishers.CombineLatest(store.publisher, navSubject)
            .map { [ids = self.ids, today = self.today] database, nav in
                MissionStateBuilder.build(database, nav: nav, ids: ids, today: today())
            }
            .eraseToAnyPublisher()
    }

    var state: MrasemState {
        MissionStateBuilder.build(store.database, nav: navSubject.value, ids: ids, today: today())
    }

    var navPublisher: AnyPublisher<RepoNav, Never> { navSubject.eraseToAnyPublisher() }
    var nav: RepoNav { navSubject.value }

    /// النطاق الحالي (الوفد والعضو).
    var scope: ViewScope { ViewScope.resolve(store.database, selected: navSubject.value.selectedDelegationId) }

    // MARK: - التنقل

    /// الوضع والدور بيتحددوا من المستخدم ووفده، فالطلبين دول مالهمش أثر.
    func setMode(_ mode: MissionMode, dayIndex: Int) {}
    func setRole(_ role: UserRole) {}

    func setGuestTab(_ tab: GuestTab) { updateNav { $0.guestTab = tab } }
    func setTeamTab(_ tab: TeamTab) { updateNav { $0.teamTab = tab } }
    func setDay(_ index: Int) { updateNav { $0.dayIndex = index } }
    func setFilter(_ filter: ExploreFilter) { updateNav { $0.filter = filter } }

    /// اختيار وفد لمنسق أو أدمن عنده أكتر من وفد.
    func selectDelegation(_ id: String?) {
        updateNav {
            $0.selectedDelegationId = id
            $0.dayIndex = nil
            $0.filter = .all
        }
    }

    /// عند تبديل المستخدم: وفد ويوم وفلتر من الأول (التابات بتفضل).
    func resetForNewUser() { selectDelegation(nil) }

    // MARK: - الوصول والطلبات والتنبيهات

    /// مرحلة الوصول = حالة رحلة أول فقرة في البرنامج (نفس اللي السائق بيغيّرها).
    func setArrival(mode: MissionMode, stage: Int) {
        guard let delegationId = scope.delegationId,
              let first = ProgramService.items(store.database, delegationId: delegationId).first
        else { return }

        let status: TripStatus
        switch stage {
        case 1: status = .onTheWay
        case 2: status = .arrived
        case 3: status = .pickedUp
        case 4: status = .completed
        default: status = .scheduled
        }
        trips.setStatus(first.id, status)
    }

    @discardableResult
    func addRequest(mode: MissionMode, kind: RequestKind, place: String?, text: String?) -> GuestRequest {
        let fallback = GuestRequest(id: 0, mode: mode, kind: kind, place: place, text: text, status: .new)
        let database = store.database
        guard let memberId = scope.memberId, let member = database.member(memberId) else { return fallback }

        let placeId = place.flatMap { name in
            database.places.first { $0.name == name && $0.kind == .attraction && $0.mode == mode }?.id
        }
        switch requests.create(memberId: member.id, kind: kind, text: place ?? text ?? "", placeId: placeId) {
        case let .success(record):
            return GuestRequest(id: ids.id(record.id), mode: mode, kind: kind, place: place, text: text, status: .new)
        case .failure:
            return fallback
        }
    }

    func setRequestStatus(id: Int64, status: RequestStatus) {
        guard let key = ids.key(id) else { return }

        if status == .done {
            // الـ service بيبعت «تم الترتيب» للعضو ومرافقه.
            requests.resolve(key)
        } else {
            store.update { db in
                guard let index = db.requests.firstIndex(where: { $0.id == key }) else { return }
                db.requests[index].status = status
            }
        }
    }

    /// نقطة إرسال التنبيهات اللي الـ strategies بتطلبها. «تم الترتيب» بيتبعت من `setRequestStatus`، فمش بيتكرر هنا.
    @discardableResult
    func addNotice(mode: MissionMode, content: NoticeContent) -> Notice {
        let notice = Notice(id: ids.fresh(), mode: mode, content: content)
        guard let delegationId = scope.delegationId else { return notice }
        let date = now()

        switch content {
        case let .broadcast(text):
            requests.broadcast(text, delegationId: delegationId, audience: .all)
        case let .dressApproved(code):
            post(.dressApproved(code), delegationId: delegationId, withDrivers: false, at: date)
        case .visitDataUpdated:
            post(.visitDataUpdated, delegationId: delegationId, withDrivers: false, at: date)
        case let .postponed(title, newTime):
            post(.postponed(title: title, newTime: newTime), delegationId: delegationId, withDrivers: true, at: date)
        case .requestResolved, .programChanged, .tripStatus, .requestCreated, .assignmentChanged, .driverConflict:
            break
        }
        return notice
    }

    func markChanged(_ keys: Set<ChangeKey>) {
        guard let delegationId = scope.delegationId else { return }
        let sections = keys.compactMap { key -> ChangedSection? in
            if case let .section(_, section) = key { return section }
            return nil
        }
        guard !sections.isEmpty else { return }
        updateNav { $0.sectionMarks[delegationId, default: []].formUnion(sections) }
    }

    // MARK: - بيانات الزيارة

    func updateVisitData(mode: MissionMode, data: VisitData) {
        guard let delegationId = scope.delegationId else { return }
        store.update { VisitDataWriter.apply(data, delegationId: delegationId, to: &$0) }
    }

    func setDress(_ dress: DressCode) {
        guard let delegationId = scope.delegationId else { return }
        store.update { db in
            guard let index = db.delegations.firstIndex(where: { $0.id == delegationId }) else { return }
            db.delegations[index].dress = dress
        }
    }

    func setItemTime(mode: MissionMode, dayIndex: Int, itemIndex: Int, time: String) {
        let database = store.database
        guard let delegation = database.delegation(scope.delegationId) else { return }
        let itemIds = GuestMissionAdapter.programDays(database, delegation: delegation).1
        guard itemIds.indices.contains(dayIndex), itemIds[dayIndex].indices.contains(itemIndex) else { return }
        let itemId = itemIds[dayIndex][itemIndex]

        store.update { db in
            guard let index = db.program.firstIndex(where: { $0.id == itemId }), db.program[index].kind != .free else { return }
            db.program[index].time = time
            db.program[index].isChanged = true
        }
    }

    // MARK: - الفحص والمحادثة

    func setCheck(mode: MissionMode, index: Int, checked: Bool) {
        guard let memberId = scope.memberId else { return }
        store.update { db in
            var list = db.checklists.first { $0.id == memberId }?.checked ?? []
            list.removeAll { $0 == index }
            if checked { list.append(index) }
            list.sort()

            if let at = db.checklists.firstIndex(where: { $0.id == memberId }) {
                db.checklists[at].checked = list
            } else {
                db.checklists.append(ChecklistRecord(id: memberId, checked: list))
            }
        }
    }

    /// الأسئلة بس بتتحفظ؛ الردود بتتحسب من بيانات الوفد وقت العرض.
    func appendChat(_ messages: [ChatMessage]) {
        guard let memberId = scope.memberId else { return }
        let date = now()
        let questions = messages.compactMap { message -> String? in
            if case let .user(text) = message { return text }
            return nil
        }
        guard !questions.isEmpty else { return }

        store.update { db in
            for question in questions {
                db.chats.append(ChatRecord(id: MrasemDatabase.newId("chat"), memberId: memberId, question: question, createdAt: date))
            }
        }
    }

    // MARK: - داخلي

    private func updateNav(_ change: (inout RepoNav) -> Void) {
        var value = navSubject.value
        change(&value)
        if value != navSubject.value { navSubject.send(value) }
    }

    /// أعضاء الوفد + مرافقيهم (+ سائقيه). صاحب الفعل ما بيستلمش تنبيهه.
    private func post(_ body: NoticeBody, delegationId: String, withDrivers: Bool, at date: Date) {
        store.update { db in
            var recipients = db.memberRefs(of: delegationId) + db.escortRefs(of: delegationId)
            if withDrivers { recipients += db.driverRefs(of: delegationId) }
            db.post(body, delegationId: delegationId, to: recipients, at: date)
        }
    }
}
