//
//  StoreRecords.swift
//  Mrasem
//
//  Phase 11 — كيانات قاعدة البيانات المحلية (08-ALL-ROLES-PLAN §3).
//  كل كيان `Codable` بمعرّف نصي، والعلاقات بالمعرّفات (زي البوابة).
//  التواريخ نص `yyyy-MM-dd` والأوقات `HH:mm` زي المصدر؛ اللحظات (`Date`) للأحداث بس.
//

import Foundation

extension MissionMode: Codable {}
extension DressCode: Codable {}
extension PlateStyle: Codable {}
extension RequestKind: Codable {}
extension RequestStatus: Codable {}

// MARK: - التعدادات

enum DelegationStatus: String, Codable, CaseIterable, Hashable {
    case draft
    case active
    case archived
}

enum MemberAppStatus: String, Codable, CaseIterable, Hashable {
    case active
    case invited
}

enum DriverStatus: String, Codable, CaseIterable, Hashable {
    case available
    case onLeave
}

enum PlaceKind: String, Codable, CaseIterable, Hashable {
    case hotel
    case restaurant
    case attraction
    case entity
}

enum ProgramItemKind: String, Codable, CaseIterable, Hashable {
    case official
    case meal
    case visit
    case move
    case free
}

enum TeamRole: String, Codable, CaseIterable, Hashable {
    case admin
    case coordinator
    case viewer
}

/// حالة رحلة السائق لفقرة في البرنامج (Phase 16).
enum TripStatus: String, Codable, CaseIterable, Hashable {
    case scheduled
    case onTheWay
    case arrived
    case pickedUp
    case completed
}

enum NoticeAudience: String, Codable, CaseIterable, Hashable {
    /// كل أعضاء الوفد.
    case all
    case escorts
    case drivers
    /// مستلمين محددين في `recipients`.
    case custom
}

enum ThemeChoice: String, Codable, CaseIterable, Hashable {
    case light
    case dark
    case system
}

/// مين المستخدم — أي شخص في البيانات ممكن «يدخل» بيه (08 §1).
enum UserRef: Codable, Hashable {
    case team(String)
    case member(String)
    case escort(String)
    case driver(String)
}

/// محتوى التنبيه — النص النهائي يتبني في الـ UI من الـ strings (C1). Phase 12 بيكمّل الحالات.
enum NoticeBody: Codable, Hashable {
    case broadcast(String)
    case dressApproved(DressCode)
    case visitDataUpdated
    case programChanged(itemId: String)
    case postponed(title: String, newTime: String)
    case requestCreated(requestId: String)
    case requestResolved(requestId: String)
    case requestReplied(requestId: String)
    case tripStatus(itemId: String, status: TripStatus)
    case assignmentChanged(memberId: String)
}

// MARK: - الكيانات

struct NextMeetingRecord: Codable, Equatable, Hashable {
    var who: String
    var address: String
    var seat: String
    var gift: String
    var language: String
}

struct DelegationRecord: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var mode: MissionMode
    var host: String
    /// «وفد رسمي زائر» / «مهمة رسمية».
    var countryLabel: String
    var destinationId: String?
    var start: String
    var end: String
    var hotelId: String?
    /// مكان الملتقى الرئيسي (بطاقة «الملتقى» عند الضيف).
    var venueId: String?
    /// المنسقون المسؤولون (TeamUser).
    var coordinatorIds: [String]
    var status: DelegationStatus
    var dress: DressCode
    var nextMeeting: NextMeetingRecord?
}

struct MemberRecord: Codable, Equatable, Identifiable {
    var id: String
    var delegationId: String
    var name: String
    var title: String
    var escortId: String?
    var carId: String?
    var room: String
    var appStatus: MemberAppStatus
    /// رئيس الوفد: بياناته (السيارة، الغرفة، المرافق) هي اللي بتظهر في بطاقة المهمة.
    var isHead: Bool
}

struct EscortRecord: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var title: String
    var phone: String
    /// مكان الاستقبال («صالة كبار الشخصيات…»).
    var meetingSpot: String
}

struct DriverRecord: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var phone: String
    var status: DriverStatus
}

struct CarRecord: Codable, Equatable, Identifiable {
    var id: String
    var type: String
    var plate: String
    var plateStyle: PlateStyle
    var driverId: String?
}

/// دليل الأماكن: فنادق ومطاعم ومزارات وجهات. الحقول اللي مش لازمة لنوع معيّن بتفضل فاضية.
struct PlaceRecord: Codable, Equatable, Identifiable {
    var id: String
    var kind: PlaceKind
    var mode: MissionMode
    var name: String
    var description: String
    /// زمن الوصول بالسيارة (دقائق).
    var minutes: Int
    var durationHours: Double
    var tag: String
    /// الشخصية الرسمية (للجهات).
    var official: String
    var building: String
    var area: String
    var entrance: String
    var floor: String
    var hall: String
    var parking: String
    var latitude: Double?
    var longitude: Double?
    var mapLabel: String
    /// مواعيد الفطور (للفنادق).
    var breakfast: String
    var phone: String
}

struct ProgramItemRecord: Codable, Equatable, Identifiable {
    var id: String
    var delegationId: String
    var date: String
    var time: String
    /// نهاية الوقت الحر (للنوع `free` بس).
    var endTime: String?
    var title: String
    var kind: ProgramItemKind
    var placeId: String?
    var note: String
    var carId: String?
    var isKey: Bool
    /// «محدَّث» عند الضيف.
    var isChanged: Bool
}

struct RequestRecord: Codable, Equatable, Identifiable {
    var id: String
    var delegationId: String
    var memberId: String?
    var kind: RequestKind
    /// اسم المكان (زيارة) أو نص السؤال.
    var text: String
    var placeId: String?
    var status: RequestStatus
    var reply: String
    var createdAt: Date
}

struct NoticeRecord: Codable, Equatable, Identifiable {
    var id: String
    var delegationId: String?
    var audience: NoticeAudience
    var recipients: [UserRef]
    var readBy: [UserRef]
    var body: NoticeBody
    var createdAt: Date
}

struct TeamUserRecord: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var role: TeamRole
    var phone: String
    var email: String
}

/// حالة رحلة السائق لفقرة (`id` = معرّف الفقرة).
struct TripRecord: Codable, Equatable, Identifiable {
    var id: String
    var status: TripStatus
    var updatedAt: Date
}

/// «قبل الخروج من الفندق» لكل عضو (`id` = معرّف العضو).
struct ChecklistRecord: Codable, Equatable, Identifiable {
    var id: String
    var checked: [Int]
}

/// سؤال للمساعد؛ الرد بيتحسب من البيانات (Phase 12).
struct ChatRecord: Codable, Equatable, Identifiable {
    var id: String
    var memberId: String
    var question: String
    var createdAt: Date
}
