//
//  GuestService.swift
//  Mrasem
//
//  Phase 12 — أفعال عضو الوفد على القاعدة: قائمة «قبل الخروج من الفندق»، طلب زيارة من استكشف،
//  وسؤال المساعد (اللي ما لوش إجابة بيتحوّل طلب «سؤال» للمنسق — نفس قواعد `AssistantStrategy`).
//

import Foundation

nonisolated final class GuestService {
    private let store: MrasemStore
    private let requests: RequestService
    private let now: () -> Date

    init(store: MrasemStore, requests: RequestService, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.requests = requests
        self.now = now
    }

    func context(memberId: String) -> GuestContext? {
        GuestMissionAdapter.context(store.database, memberId: memberId)
    }

    /// يقلب بند في قائمة الفحص (محفوظ لكل عضو).
    func toggleCheck(memberId: String, index: Int) {
        guard let count = context(memberId: memberId)?.checklist.count, (0..<count).contains(index) else { return }

        store.update { db in
            if let i = db.checklists.firstIndex(where: { $0.id == memberId }) {
                if let at = db.checklists[i].checked.firstIndex(of: index) {
                    db.checklists[i].checked.remove(at: at)
                } else {
                    db.checklists[i].checked.append(index)
                    db.checklists[i].checked.sort()
                }
            } else {
                db.checklists.append(ChecklistRecord(id: memberId, checked: [index]))
            }
        }
    }

    /// «أرغب في الزيارة». false لو فيه طلب مفتوح لنفس المكان.
    @discardableResult
    func requestVisit(memberId: String, placeId: String) -> Bool {
        let db = store.database
        guard let place = db.place(placeId) else { return false }
        let open = db.requests.contains {
            $0.memberId == memberId && $0.kind == .visit && $0.placeId == placeId && $0.status == .new
        }
        guard !open else { return false }

        if case .success = requests.create(memberId: memberId, kind: .visit, text: place.name, placeId: placeId) {
            return true
        }
        return false
    }

    /// حالة طلب المكان للعضو: nil = ما اتطلبش.
    func visitRequestStatus(memberId: String, placeId: String) -> RequestStatus? {
        store.database.requests.last { $0.memberId == memberId && $0.kind == .visit && $0.placeId == placeId }?.status
    }

    /// سؤال للمساعد: يتسجّل في المحادثة، والرد بيتحسب من بيانات الوفد.
    /// لو مفيش إجابة (`.forwarded`) بيتعمل طلب «سؤال» للمنسق.
    @discardableResult
    func ask(memberId: String, question: String) -> AssistantReply? {
        let value = question.storeTrimmed
        guard !value.isEmpty, let context = context(memberId: memberId) else { return nil }

        let reply = AssistantStrategy.reply(value, mission: context.mission, dress: context.dress)
        let record = ChatRecord(id: MrasemDatabase.newId("chat"), memberId: memberId, question: value, createdAt: now())
        store.update { $0.chats.append(record) }

        if reply == .forwarded {
            requests.create(memberId: memberId, kind: .question, text: value)
        }
        return reply
    }

    /// المحادثة كاملة: الترحيب + كل سؤال ورده (الردود بتتحسب من البيانات الحالية).
    func conversation(memberId: String) -> [ChatMessage] {
        guard let context = context(memberId: memberId) else { return [] }
        var messages: [ChatMessage] = [.bot(AssistantStrategy.welcome(context.mission))]
        for chat in store.database.chats where chat.memberId == memberId {
            messages.append(.user(chat.question))
            messages.append(.bot(AssistantStrategy.reply(chat.question, mission: context.mission, dress: context.dress)))
        }
        return messages
    }
}
