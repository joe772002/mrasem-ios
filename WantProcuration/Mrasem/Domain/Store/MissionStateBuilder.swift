//
//  MissionStateBuilder.swift
//  Mrasem
//
//  Phase 13 — يبني `MrasemState` (اللي شاشات الضيف والفريق بتقراه) من القاعدة + المستخدم الحالي + حالة التنقل.
//  دالة صافية: نفس القاعدة ونفس التنقل = نفس الحالة، فسهل تتختبر.
//

import Foundation

/// حالة التنقل (مش بيانات): التابات واليوم والفلتر والوفد المختار.
struct RepoNav: Equatable {
    var guestTab: GuestTab = .mission
    var teamTab: TeamTab = .visit
    /// `nil` = اليوم الافتراضي (النهارده لو جوّه فترة الوفد، وإلا الأول).
    var dayIndex: Int?
    var filter: ExploreFilter = .all
    var selectedDelegationId: String?
    /// علامات «محدَّث» للأقسام لكل وفد (مؤقتة زي الأصل).
    var sectionMarks: [String: Set<ChangedSection>] = [:]
}

/// معرّفات رقمية ثابتة للطلبات والتنبيهات (الشاشات القديمة بتستخدم `Int64`).
nonisolated final class IdTable {
    private let lock = NSLock()
    private var forward: [String: Int64] = [:]
    private var reverse: [Int64: String] = [:]
    private var last: Int64 = 0

    func id(_ key: String) -> Int64 {
        lock.lock(); defer { lock.unlock() }
        if let value = forward[key] { return value }
        last += 1
        forward[key] = last
        reverse[last] = key
        return last
    }

    func key(_ id: Int64) -> String? {
        lock.lock(); defer { lock.unlock() }
        return reverse[id]
    }

    /// معرّف جديد لعنصر مش في القاعدة (نتيجة دالة بترجّع قيمة).
    func fresh() -> Int64 {
        lock.lock(); defer { lock.unlock() }
        last += 1
        return last
    }
}

nonisolated enum MissionStateBuilder {

    static func build(
        _ db: MrasemDatabase,
        nav: RepoNav,
        ids: IdTable,
        today: MrasemDate = MrasemDate.today()
    ) -> MrasemState {
        let scope = ViewScope.resolve(db, selected: nav.selectedDelegationId)
        let delegation = db.delegation(scope.delegationId)
        let member = db.member(scope.memberId)
        let mode = delegation?.mode ?? db.preferences.defaultMode

        var missions: [MissionMode: Mission] = [:]
        for each in MissionMode.allCases { missions[each] = emptyMission(each) }

        var itemIds: [[String]] = []
        if let delegation {
            let (days, idsByDay) = GuestMissionAdapter.programDays(db, delegation: delegation)
            itemIds = idsByDay
            let mission = GuestMissionAdapter.mission(db, delegation: delegation, member: member, days: days)
            missions[mode] = withAtLeastOneDay(mission)
        }

        var state = MrasemState(missions: missions)
        state.mode = mode
        state.role = isTeam(scope.user, db) ? .team : .guest
        state.guestTab = nav.guestTab
        state.teamTab = nav.teamTab
        state.filter = nav.filter
        state.dayIndex = nav.dayIndex ?? defaultDay(delegation, today: today)
        state.reference = reference(db, delegation: delegation)

        guard let delegation else { return state }

        state.dress = delegation.dress
        state.arrived[mode] = GuestMissionAdapter.arrivalStage(db, delegationId: delegation.id)
        state.requests = requests(db, delegation: delegation, scope: scope, mode: mode, ids: ids)
        state.notices = notices(db, delegation: delegation, scope: scope, mode: mode, ids: ids)
        state.changed = changedKeys(db, nav: nav, delegation: delegation, itemIds: itemIds)

        if let memberId = scope.memberId {
            state.checks[mode] = Set(db.checklists.first { $0.id == memberId }?.checked ?? [])
            state.chat = chat(db, memberId: memberId, mission: state.mission, dress: delegation.dress)
        }
        return state
    }

    // MARK: - أجزاء الحالة

    private static func isTeam(_ user: UserRef?, _ db: MrasemDatabase) -> Bool {
        guard let user, case .team = user else { return false }
        return true
    }

    /// اليوم اللي النهارده فيه (لو جوّه الفترة)، وإلا الأول.
    static func defaultDay(_ delegation: DelegationRecord?, today: MrasemDate) -> Int {
        guard let delegation else { return 0 }
        return StoreTime.days(from: delegation.start, to: delegation.end).firstIndex(of: today.iso) ?? 0
    }

    private static func reference(_ db: MrasemDatabase, delegation: DelegationRecord?) -> ReferenceContent {
        guard let destination = db.destination(delegation?.destinationId) else { return .empty }
        var sets: [DressCode: DressSet] = [:]
        for set in destination.dressSets {
            sets[set.code] = DressSet(title: set.title, men: set.men, women: set.women)
        }
        return ReferenceContent(checklist: destination.checklist, dressSets: sets, guides: destination.guides)
    }

    private static func requests(
        _ db: MrasemDatabase, delegation: DelegationRecord, scope: ViewScope, mode: MissionMode, ids: IdTable
    ) -> [GuestRequest] {
        db.requests
            .filter { $0.delegationId == delegation.id && (scope.memberId == nil || $0.memberId == scope.memberId) }
            .map { record in
                GuestRequest(
                    id: ids.id(record.id),
                    mode: mode,
                    kind: record.kind,
                    place: record.kind == .visit ? record.text : nil,
                    text: record.kind == .question ? record.text : nil,
                    status: record.status
                )
            }
    }

    /// التنبيهات بترتيب وصولها. لمستخدم الفريق: اللي اتبعت للضيف من وفده. لغيره: اللي وصلته هو.
    private static func notices(
        _ db: MrasemDatabase, delegation: DelegationRecord, scope: ViewScope, mode: MissionMode, ids: IdTable
    ) -> [Notice] {
        let source: [NoticeRecord]
        if case .team? = scope.user {
            source = db.notices.filter { $0.delegationId == delegation.id && NoticeContentMapper.isSentToGuest($0.body) }
        } else if let user = scope.user {
            source = db.notices.filter { $0.recipients.contains(user) }
        } else {
            source = []
        }
        return source.map { Notice(id: ids.id($0.id), mode: mode, content: NoticeContentMapper.content($0.body, in: db)) }
    }

    private static func changedKeys(
        _ db: MrasemDatabase, nav: RepoNav, delegation: DelegationRecord, itemIds: [[String]]
    ) -> Set<ChangeKey> {
        var keys: Set<ChangeKey> = []
        for section in nav.sectionMarks[delegation.id] ?? [] {
            keys.insert(.section(mode: delegation.mode, section: section))
        }
        for (dayIndex, day) in itemIds.enumerated() {
            for (itemIndex, id) in day.enumerated() where db.programItem(id)?.isChanged == true {
                keys.insert(.item(mode: delegation.mode, dayIndex: dayIndex, itemIndex: itemIndex))
            }
        }
        return keys
    }

    /// الأسئلة وردودها (الرد بيتحسب من بيانات الوفد الحالية؛ الترحيب بيضيفه `AssistantStrategy`).
    private static func chat(_ db: MrasemDatabase, memberId: String, mission: Mission, dress: DressCode) -> [ChatMessage] {
        db.chats.filter { $0.memberId == memberId }.flatMap { record -> [ChatMessage] in
            [.user(record.question), .bot(AssistantStrategy.reply(record.question, mission: mission, dress: dress))]
        }
    }

    // MARK: - المهمة الفاضية

    /// الشاشات بتقرا `days[dayIndex]` فلازم يوم واحد على الأقل حتى لو الوفد من غير برنامج.
    private static func withAtLeastOneDay(_ mission: Mission) -> Mission {
        mission.days.isEmpty ? mission.with(days: [ProgramDay(label: "", items: [])]) : mission
    }

    static func emptyMission(_ mode: MissionMode) -> Mission {
        let epoch = MrasemDate(year: 1970, month: 1, day: 1)
        return Mission(
            mode: mode, guest: "", country: "", dest: "", host: "", start: epoch, end: epoch,
            timeZone: "", currency: "", weather: "",
            receiver: Receiver(name: "", title: "", phone: "", spot: ""),
            car: Car(type: "", plate: "", driver: "", country: "", plateStyle: .qatar),
            coordinator: Coordinator(name: "", phone: ""),
            venue: Venue(building: "", area: "", entrance: "", floor: "", hall: "", parking: "", lat: 0, lng: 0, mapLabel: ""),
            hotel: Hotel(name: "", area: "", room: "", breakfast: "", drive: ""),
            emergency: [], days: [ProgramDay(label: "", items: [])], services: [], quickInfo: [], places: [], customs: [],
            nextMeeting: NextMeeting(who: "", address: "", seat: "", gift: "", language: "")
        )
    }
}
