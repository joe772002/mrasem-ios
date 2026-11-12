//
//  RequestService.swift
//  Mrasem
//
//  Phase 12 — طلبات الوفود والتنبيهات العامة (البوابة: «الطلبات والتنبيهات»):
//  طلب جديد من عضو ← المنسق والأدمن · «تم الترتيب» / رد ← العضو ومرافقه · «إضافة للبرنامج» · تنبيه عام بجمهور.
//

import Foundation

nonisolated final class RequestService {
    private let store: MrasemStore
    private let program: ProgramService
    private let now: () -> Date

    init(store: MrasemStore, program: ProgramService, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.program = program
        self.now = now
    }

    /// طلب زيارة أو سؤال من عضو. بيوصل للمنسقين والأدمن (لو «طلب جديد من وفد» شغال).
    @discardableResult
    func create(memberId: String, kind: RequestKind, text: String, placeId: String? = nil) -> Result<RequestRecord, StoreValidationError> {
        let value = text.storeTrimmed
        guard !value.isEmpty else { return .failure(.emptyName) }
        guard let member = store.database.member(memberId) else { return .failure(.notFound) }

        let request = RequestRecord(
            id: MrasemDatabase.newId("rq"),
            delegationId: member.delegationId,
            memberId: memberId,
            kind: kind,
            text: value,
            placeId: placeId,
            status: .new,
            reply: "",
            createdAt: now()
        )

        store.update { db in
            db.requests.append(request)
            guard db.preferences.notifyNewRequest else { return }
            db.post(.requestCreated(requestId: request.id), delegationId: request.delegationId,
                    to: db.coordinatorRefs(of: request.delegationId) + db.adminRefs(), at: request.createdAt)
        }
        return .success(request)
    }

    /// «تم الترتيب».
    @discardableResult
    func resolve(_ id: String, reply: String = "") -> Bool {
        finish(id, reply: reply.storeTrimmed) { .requestResolved(requestId: $0) }
    }

    /// الرد على سؤال.
    @discardableResult
    func reply(_ id: String, text: String) -> Bool {
        let value = text.storeTrimmed
        guard !value.isEmpty else { return false }
        return finish(id, reply: value) { .requestReplied(requestId: $0) }
    }

    /// «إضافة للبرنامج»: فقرة زيارة بالمكان ده، والطلب يبقى «تم الترتيب».
    @discardableResult
    func addToProgram(_ id: String, date: String, time: String, carId: String? = nil) -> Result<ProgramItemRecord, StoreValidationError> {
        guard let request = store.database.requests.first(where: { $0.id == id }) else { return .failure(.notFound) }

        let item = ProgramItemRecord(
            id: "",
            delegationId: request.delegationId,
            date: date,
            time: time,
            endTime: nil,
            title: request.text,
            kind: .visit,
            placeId: request.placeId,
            note: "",
            carId: carId,
            isKey: false,
            isChanged: false
        )
        let result = program.save(item, notify: false)
        if case .success = result {
            resolve(id)
        }
        return result
    }

    /// تنبيه عام من الأدمن أو المنسق لجمهور في وفد.
    @discardableResult
    func broadcast(_ text: String, delegationId: String, audience: NoticeAudience) -> Bool {
        let value = text.storeTrimmed
        guard !value.isEmpty, store.database.delegation(delegationId) != nil, audience != .custom else { return false }

        let date = now()
        var sent = false
        store.update { db in
            let before = db.notices.count
            db.post(.broadcast(value), delegationId: delegationId, audience: audience,
                    to: db.refs(for: audience, delegationId: delegationId), at: date)
            sent = db.notices.count > before
        }
        return sent
    }

    // MARK: - القراءة

    func requests(ofMember memberId: String) -> [RequestRecord] {
        store.database.requests.filter { $0.memberId == memberId }
    }

    func requests(of delegationId: String? = nil, status: RequestStatus? = nil) -> [RequestRecord] {
        store.database.requests.filter {
            (delegationId == nil || $0.delegationId == delegationId) && (status == nil || $0.status == status)
        }
    }

    // MARK: - داخلي

    private func finish(_ id: String, reply: String, body: (String) -> NoticeBody) -> Bool {
        var done = false
        let date = now()
        let notice = body(id)

        store.update { db in
            guard let index = db.requests.firstIndex(where: { $0.id == id }), db.requests[index].status != .done else { return }
            db.requests[index].status = .done
            if !reply.isEmpty { db.requests[index].reply = reply }
            done = true

            let request = db.requests[index]
            guard let memberId = request.memberId, let member = db.member(memberId) else { return }
            db.post(notice, delegationId: request.delegationId,
                    to: [.member(memberId)] + db.escortRefs(of: [member]), at: date)
        }
        return done
    }
}
