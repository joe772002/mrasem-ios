//
//  NoticeContentMapper.swift
//  Mrasem
//
//  Phase 13 — يحوّل تنبيه القاعدة (`NoticeBody`) لمحتوى الشاشات القديمة (`NoticeContent`).
//  أي تنبيه مرجعه اتحذف (فقرة، طلب) بيتحوّل لأقرب نص عام بدل ما يضيع.
//

import Foundation

nonisolated enum NoticeContentMapper {

    static func content(_ body: NoticeBody, in db: MrasemDatabase) -> NoticeContent {
        switch body {
        case let .broadcast(text):
            return .broadcast(text)
        case let .dressApproved(code):
            return .dressApproved(code)
        case .visitDataUpdated:
            return .visitDataUpdated
        case let .postponed(title, newTime):
            return .postponed(title: title, newTime: newTime)
        case let .programChanged(itemId):
            guard let item = db.programItem(itemId) else { return .visitDataUpdated }
            return .programChanged(title: item.title)
        case let .requestCreated(requestId):
            return .requestCreated(text: request(requestId, db)?.text ?? "")
        case let .requestResolved(requestId):
            return .requestResolved(place: visitPlace(requestId, db))
        case .requestReplied:
            return .requestResolved(place: nil)
        case let .tripStatus(itemId, status):
            return .tripStatus(status, driver: driverName(ofItem: itemId, db))
        case .assignmentChanged:
            return .assignmentChanged
        }
    }

    /// التنبيهات اللي الضيف بيستلمها من الفريق (بتتعد في «تنبيهات مرسلة» عند المنسق).
    static func isSentToGuest(_ body: NoticeBody) -> Bool {
        switch body {
        case .broadcast, .dressApproved, .visitDataUpdated, .postponed, .programChanged,
             .requestResolved, .requestReplied:
            return true
        case .requestCreated, .tripStatus, .assignmentChanged:
            return false
        }
    }

    private static func request(_ id: String, _ db: MrasemDatabase) -> RequestRecord? {
        db.requests.first { $0.id == id }
    }

    /// اسم المكان لو الطلب كان زيارة، وإلا `nil` (سؤال).
    private static func visitPlace(_ id: String, _ db: MrasemDatabase) -> String? {
        guard let request = request(id, db), request.kind == .visit else { return nil }
        return request.text
    }

    private static func driverName(ofItem itemId: String, _ db: MrasemDatabase) -> String {
        let car = db.car(db.programItem(itemId)?.carId)
        let name = db.driver(car?.driverId)?.name.storeTrimmed ?? ""
        return name.isEmpty ? mrasemString("mrasem_notice_trip_unknown_driver") : name
    }
}
