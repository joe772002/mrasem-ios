//
//  MrasemState.swift
//  Mrasem
//
//  Mirrors Android: data/model/mrasem/MrasemState.kt
//

import Foundation

enum UserRole: String, CaseIterable, Hashable {
    case guest
    case team
}

enum GuestTab: String, CaseIterable, Hashable {
    case mission
    case plan
    case services
    case explore
    case `protocol`
    case assistant
}

enum TeamTab: String, CaseIterable, Hashable {
    case visit
    case changes
    case requests
    case archive
}

enum DressCode: String, CaseIterable, Hashable {
    case formal
    case bisht
}

/// فلاتر استكشف: الكل / ساعة / ساعتان / نصف يوم / يوم كامل.
enum ExploreFilter: String, CaseIterable, Hashable {
    case all
    case oneHour
    case twoHours
    case halfDay
    case fullDay
}

/// طقم الزي: اسمه + قائمة الرجال + قائمة النساء.
struct DressSet: Equatable, Hashable {
    let title: String
    let men: [String]
    let women: [String]
}

enum RequestKind: String, Hashable {
    case visit
    case question
}

enum RequestStatus: String, Hashable {
    case new
    case done
}

/// طلب من الضيف: زيارة مكان (`place`) أو سؤال للمنسق (`text`).
struct GuestRequest: Identifiable, Equatable, Hashable {
    let id: Int64
    let mode: MissionMode
    let kind: RequestKind
    let place: String?
    let text: String?
    var status: RequestStatus
}

/// محتوى التنبيه — النص النهائي يتبني في الـ UI من الـ strings (قاعدة C1).
enum NoticeContent: Equatable, Hashable {
    case dressApproved(DressCode)
    case visitDataUpdated
    case postponed(title: String, newTime: String)
    /// تنبيه عام كتبه الفريق — النص كما هو.
    case broadcast(String)
    /// `place` = nil يعني الطلب كان سؤالاً.
    case requestResolved(place: String?)
    /// تعديل في فقرة من البرنامج.
    case programChanged(title: String)
    /// حالة رحلة السائق (`driver` = اسمه).
    case tripStatus(TripStatus, driver: String)
    /// طلب جديد وصل للمنسق (نص الطلب).
    case requestCreated(text: String)
    /// تعيين السيارة أو المرافق أو الغرفة اتغيّر.
    case assignmentChanged
}

struct Notice: Identifiable, Equatable, Hashable {
    let id: Int64
    let mode: MissionMode
    let content: NoticeContent
}

/// الأقسام اللي بيظهر عليها «محدَّث» في شاشة المهمة.
enum ChangedSection: String, CaseIterable, Hashable {
    case receiver
    case car
    case venue
}

enum ChangeKey: Hashable {
    case section(mode: MissionMode, section: ChangedSection)
    case item(mode: MissionMode, dayIndex: Int, itemIndex: Int)
}

/// رد المساعد — النص يتبني في الـ UI من الـ strings.
enum AssistantReply: Equatable, Hashable {
    case welcome(city: String)
    case dress(DressCode)
    case nextItem(title: String, dayLabel: String, time: String, place: String)
    case carInfo(type: String, plate: String, driver: String)
    case hotelInfo(name: String, area: String, room: String, drive: String)
    case food([String])
    case taxi([String])
    case nearbyPlaces([String])
    case emergency(number: String, coordinatorName: String, coordinatorPhone: String)
    /// مفيش إجابة: السؤال اتحوّل لمنسق المراسم.
    case forwarded
}

enum ChatMessage: Equatable, Hashable {
    case user(String)
    case bot(AssistantReply)
}

/// القيم اللي الفريق بيعدّلها من نموذج «بيانات الزيارة».
struct VisitData: Equatable, Hashable {
    var receiverName: String
    var receiverPhone: String
    var carType: String
    var carPlate: String
    var driver: String
    var hall: String
    var floor: String
}

/// الحالة الكاملة للتطبيق. مصدر واحد للضيف والفريق (قاعدة A5).
struct MrasemState: Equatable {
    var missions: [MissionMode: Mission]
    var mode: MissionMode = .inbound
    var role: UserRole = .guest
    var guestTab: GuestTab = .mission
    var teamTab: TeamTab = .visit
    var dayIndex: Int = 1
    var filter: ExploreFilter = .all
    /// مرحلة الوصول 0..4 لكل وضع.
    var arrived: [MissionMode: Int] = [:]
    var requests: [GuestRequest] = []
    var notices: [Notice] = []
    var changed: Set<ChangeKey> = []
    var dress: DressCode = .formal
    /// فهارس عناصر «قبل الخروج من الفندق» المعلَّمة لكل وضع.
    var checks: [MissionMode: Set<Int>] = [:]
    var chat: [ChatMessage] = []
    /// المحتوى المرجعي للوجهة (Phase 13). الافتراضي بيانات العرض للـ Previews والاختبارات.
    var reference: ReferenceContent = .demo

    init(missions: [MissionMode: Mission]) {
        self.missions = missions
    }

    /// الوضع الحالي دايماً موجود من `MissionStateBuilder`؛ ولو لأي سبب مش موجود نرجّع مهمة فاضية بدل crash (G5).
    var mission: Mission { missions[mode] ?? MissionStateBuilder.emptyMission(mode) }

    func arrived(for mode: MissionMode? = nil) -> Int {
        arrived[mode ?? self.mode] ?? 0
    }

    func checks(for mode: MissionMode? = nil) -> Set<Int> {
        checks[mode ?? self.mode] ?? []
    }

    func requests(for mode: MissionMode? = nil) -> [GuestRequest] {
        requests.filter { $0.mode == (mode ?? self.mode) }
    }

    func notices(for mode: MissionMode? = nil) -> [Notice] {
        notices.filter { $0.mode == (mode ?? self.mode) }
    }
}
