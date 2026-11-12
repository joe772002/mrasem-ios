//
//  MrasemDatabase.swift
//  Mrasem
//
//  Phase 11 — كل بيانات التطبيق في قيمة واحدة (امتداد A5). بتتحفظ كملف JSON واحد.
//

import Foundation

struct MrasemDatabase: Codable, Equatable {
    /// يزيد مع أي تغيير في شكل الكيانات. ملف برقم أكبر ما بيتقريش (بيتحفظ نسخة منه).
    static let currentSchemaVersion = 1

    var schemaVersion: Int = MrasemDatabase.currentSchemaVersion

    var destinations: [DestinationRecord] = []
    var delegations: [DelegationRecord] = []
    var members: [MemberRecord] = []
    var escorts: [EscortRecord] = []
    var drivers: [DriverRecord] = []
    var cars: [CarRecord] = []
    var places: [PlaceRecord] = []
    var program: [ProgramItemRecord] = []
    var requests: [RequestRecord] = []
    var notices: [NoticeRecord] = []
    var team: [TeamUserRecord] = []
    var trips: [TripRecord] = []
    var checklists: [ChecklistRecord] = []
    var chats: [ChatRecord] = []
    var preferences = PreferencesRecord()

    /// المستخدم الحالي. `nil` = يظهر «اختر المستخدم».
    var currentUser: UserRef?
    /// اختار «ابدأ فارغ» أو «بيانات العرض» (08 القرار #1).
    var didChooseStart = false

    /// قاعدة فاضية فيها أدمن واحد بس عشان تقدر تدخل (08 §3).
    static func blank() -> MrasemDatabase {
        var db = MrasemDatabase()
        db.ensureAdmin()
        return db
    }

    var isEmptyOfContent: Bool {
        destinations.isEmpty && delegations.isEmpty && members.isEmpty && escorts.isEmpty
            && drivers.isEmpty && cars.isEmpty && places.isEmpty && program.isEmpty
    }

    /// لو مفيش أدمن، يضيف الأدمن الافتراضي ويخليه المستخدم الحالي لو مفيش.
    mutating func ensureAdmin() {
        guard !team.contains(where: { $0.role == .admin }) else { return }
        let admin = MrasemSeed.defaultAdmin
        team.removeAll { $0.id == admin.id }
        team.insert(admin, at: 0)
        if currentUser == nil {
            currentUser = .team(admin.id)
        }
    }

    /// بعد أي تعديل: أدمن موجود، والمستخدم الحالي موجود فعلاً (لو اتحذف ← `nil` فيظهر «اختر المستخدم»).
    mutating func normalize() {
        ensureAdmin()
        if let user = currentUser, !exists(user) {
            currentUser = nil
        }
    }

    // MARK: - البحث بالمعرّف

    func delegation(_ id: String?) -> DelegationRecord? { id.flatMap { id in delegations.first { $0.id == id } } }
    func member(_ id: String?) -> MemberRecord? { id.flatMap { id in members.first { $0.id == id } } }
    func escort(_ id: String?) -> EscortRecord? { id.flatMap { id in escorts.first { $0.id == id } } }
    func driver(_ id: String?) -> DriverRecord? { id.flatMap { id in drivers.first { $0.id == id } } }
    func car(_ id: String?) -> CarRecord? { id.flatMap { id in cars.first { $0.id == id } } }
    func place(_ id: String?) -> PlaceRecord? { id.flatMap { id in places.first { $0.id == id } } }
    func programItem(_ id: String?) -> ProgramItemRecord? { id.flatMap { id in program.first { $0.id == id } } }
    func teamUser(_ id: String?) -> TeamUserRecord? { id.flatMap { id in team.first { $0.id == id } } }
    func destination(_ id: String?) -> DestinationRecord? { id.flatMap { id in destinations.first { $0.id == id } } }

    /// المستخدم موجود فعلاً في البيانات.
    func exists(_ user: UserRef) -> Bool {
        switch user {
        case let .team(id): return teamUser(id) != nil
        case let .member(id): return member(id) != nil
        case let .escort(id): return escort(id) != nil
        case let .driver(id): return driver(id) != nil
        }
    }

    /// معرّف جديد مش متكرر (البادئة بتوضح النوع في الملف).
    static func newId(_ prefix: String) -> String {
        prefix + "_" + UUID().uuidString.prefix(8).lowercased()
    }
}

/// ترميز الملف: JSON مرتب (سهل المراجعة والمقارنة)، والـ `Date` بالقيمة الكاملة عشان القراءة ترجع نفس القيمة.
enum MrasemDatabaseCodec {
    private struct Header: Decodable {
        let schemaVersion: Int
    }

    static func encode(_ database: MrasemDatabase) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(database)
    }

    static func decode(_ data: Data) throws -> MrasemDatabase {
        try JSONDecoder().decode(MrasemDatabase.self, from: data)
    }

    /// رقم الـ schema من غير ما نفك الملف كله (`nil` لو مش JSON سليم).
    static func schemaVersion(of data: Data) -> Int? {
        try? JSONDecoder().decode(Header.self, from: data).schemaVersion
    }
}
