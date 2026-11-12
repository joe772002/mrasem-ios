//
//  AdminRequests.swift
//  Mrasem
//
//  Phase 15 — تاب «الطلبات»: طلبات الضيوف عبر كل الوفود (رد، تم، إضافة للبرنامج)، وإرسال تنبيه حسب الجمهور، وسجل التنبيهات.
//

import Foundation

enum RequestFilter: String, CaseIterable, Hashable {
    case new
    case done
    case all

    var titleKey: String { "mrasem_admin_req_filter_" + rawValue }
}

struct AdminRequestItem: Equatable, Identifiable {
    let id: String
    let delegationId: String
    let delegationName: String
    let memberName: String
    let kind: RequestKind
    let text: String
    let placeName: String?
    let status: RequestStatus
    let reply: String
    let createdAt: Date
}

/// تنبيه عام اتبعت (سجل).
struct AdminBroadcastRow: Equatable, Identifiable {
    let id: String
    let delegationName: String
    let audience: NoticeAudience
    let text: String
    let recipientCount: Int
    let readCount: Int
    let createdAt: Date
}

extension NoticeAudience {
    var adminLabelKey: String { "mrasem_admin_audience_" + rawValue }

    /// الجماهير اللي ينفع الأدمن يبعتلها (`custom` مستلمين محددين بس).
    static var broadcastChoices: [NoticeAudience] { [.all, .escorts, .drivers] }
}

struct AdminRequestsState: Equatable {
    let filter: RequestFilter
    let items: [AdminRequestItem]
    let counts: [RequestFilter: Int]
    let broadcasts: [AdminBroadcastRow]
    let hasDelegations: Bool

    static func make(_ db: MrasemDatabase, filter: RequestFilter) -> AdminRequestsState {
        AdminRequestsState(
            filter: filter,
            items: AdminRequestsBuilder.items(db, filter: filter),
            counts: AdminRequestsBuilder.counts(db),
            broadcasts: AdminRequestsBuilder.broadcasts(db),
            hasDelegations: !db.delegations.isEmpty
        )
    }
}

nonisolated enum AdminRequestsBuilder {

    static func items(_ db: MrasemDatabase, filter: RequestFilter) -> [AdminRequestItem] {
        db.requests
            .filter { matches($0, filter) }
            .sorted { $0.createdAt != $1.createdAt ? $0.createdAt > $1.createdAt : $0.id < $1.id }
            .map { request in
                AdminRequestItem(
                    id: request.id,
                    delegationId: request.delegationId,
                    delegationName: db.delegation(request.delegationId)?.name ?? "",
                    memberName: db.member(request.memberId)?.name ?? "",
                    kind: request.kind,
                    text: request.text,
                    placeName: db.place(request.placeId)?.name,
                    status: request.status,
                    reply: request.reply,
                    createdAt: request.createdAt
                )
            }
    }

    static func counts(_ db: MrasemDatabase) -> [RequestFilter: Int] {
        Dictionary(uniqueKeysWithValues: RequestFilter.allCases.map { filter in
            (filter, db.requests.count { matches($0, filter) })
        })
    }

    /// سجل التنبيهات العامة، الأحدث الأول.
    static func broadcasts(_ db: MrasemDatabase) -> [AdminBroadcastRow] {
        db.notices
            .compactMap { notice -> AdminBroadcastRow? in
                guard case let .broadcast(text) = notice.body else { return nil }
                return AdminBroadcastRow(
                    id: notice.id,
                    delegationName: db.delegation(notice.delegationId)?.name ?? "",
                    audience: notice.audience,
                    text: text,
                    recipientCount: notice.recipients.count,
                    readCount: notice.readBy.count,
                    createdAt: notice.createdAt
                )
            }
            .sorted { $0.createdAt != $1.createdAt ? $0.createdAt > $1.createdAt : $0.id < $1.id }
    }

    private static func matches(_ request: RequestRecord, _ filter: RequestFilter) -> Bool {
        switch filter {
        case .all: return true
        case .new: return request.status == .new
        case .done: return request.status == .done
        }
    }
}

/// نموذج «إضافة للبرنامج» لطلب زيارة.
struct RequestProgramDraft: Equatable, Identifiable {
    let requestId: String
    var date: String
    var time = "10:00"
    var carId: String?

    var id: String { requestId }

    init(requestId: String, date: String) {
        self.requestId = requestId
        self.date = date
    }
}

/// نموذج الرد على طلب.
struct RequestReplyDraft: Equatable, Identifiable {
    let requestId: String
    var text: String

    var id: String { requestId }

    init(requestId: String, text: String = "") {
        self.requestId = requestId
        self.text = text
    }
}

/// نموذج تنبيه عام.
struct BroadcastDraft: Equatable, Identifiable {
    var delegationId: String
    var audience: NoticeAudience = .all
    var text = ""

    var id: String { "broadcast" }

    init(delegationId: String) {
        self.delegationId = delegationId
    }
}
