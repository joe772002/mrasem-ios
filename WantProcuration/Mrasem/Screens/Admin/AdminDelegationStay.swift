//
//  AdminDelegationStay.swift
//  Mrasem
//
//  Phase 14 — كروت «الإقامة والغرف» و«طلبات الوفد» في تفاصيل الوفد.
//

import SwiftUI

struct AdminStayCard: View {
    @Environment(\.mrasem) private var theme

    let hotelName: String?
    let members: [AdminMemberRow]

    var body: some View {
        MrasemCard(title: mrasemString("mrasem_admin_stay_title")) {
            Text(hotelName ?? mrasemString("mrasem_admin_stay_hotel_none"))
                .mrasemText(theme.type.strong)
                .foregroundColor(hotelName == nil ? theme.colors.warn : theme.colors.ink)

            VStack(spacing: 8) {
                ForEach(members) { member in
                    MrasemActionRow(
                        title: member.name,
                        subtitle: member.room.isEmpty ? mrasemString("mrasem_admin_stay_room_none") : member.room
                    ) {
                        if member.room.isEmpty { MrasemPill(mrasemString("mrasem_admin_pill_missing"), kind: .warn) }
                    }
                }
            }
        }
    }
}

struct AdminRequestsCard: View {
    @Environment(\.mrasem) private var theme

    let requests: [AdminRequestRow]
    let actions: AdminDetailActions

    var body: some View {
        MrasemCard(title: mrasemString("mrasem_admin_requests_title")) {
            if requests.isEmpty {
                Text("mrasem_admin_requests_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(requests) { request in
                        MrasemActionRow(title: title(request), subtitle: request.memberName.map { mrasemString("mrasem_admin_request_from", [$0]) } ?? "") {
                            if request.status == .done {
                                MrasemPill(mrasemString("mrasem_admin_request_done"), kind: .ok)
                            } else {
                                MrasemButton(mrasemString("mrasem_admin_request_resolve"), variant: .primary) {
                                    actions.onResolve(request.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func title(_ request: AdminRequestRow) -> String {
        mrasemString(request.kind == .visit ? "mrasem_admin_request_visit" : "mrasem_admin_request_question", [request.text])
    }
}
