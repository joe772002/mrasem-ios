//
//  NoticesScreen.swift
//  Mrasem
//
//  Phase 16 — تاب «التنبيهات» للمرافق، وبطاقة التنبيهات اللي بتتحط في شاشة السائق.
//

import SwiftUI

struct NoticesScreen: View {
    @Environment(\.mrasem) private var theme
    @StateObject private var model: NoticesModel

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: NoticesModel(backend: context.backend))
    }

    var body: some View {
        MrasemScreenContent {
            Text("mrasem_tab_notices")
                .mrasemText(theme.type.heroDest)
                .foregroundColor(theme.colors.maroon)
                .accessibilityAddTraits(.isHeader)

            NoticeInboxCard(state: model.uiState, onMarkRead: model.markAllRead)
        }
    }
}

/// قائمة التنبيهات + «علّم الكل مقروء».
struct NoticeInboxCard: View {
    @Environment(\.mrasem) private var theme

    let state: NoticeInboxState
    let onMarkRead: () -> Void

    var body: some View {
        MrasemCard(
            title: mrasemString("mrasem_notices_title", [state.unread.toArabicDigits()]),
            headerEnd: AnyView(
                state.unread > 0
                    ? AnyView(MrasemButton(mrasemString("mrasem_notices_mark_read"), variant: .ghost, action: onMarkRead))
                    : AnyView(EmptyView())
            )
        ) {
            if state.rows.isEmpty {
                Text("mrasem_notices_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(state.rows) { row in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(row.isRead ? Color.clear : theme.colors.gold)
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                                .accessibilityHidden(true)
                            Text(row.text)
                                .mrasemText(row.isRead ? theme.type.body : theme.type.strong)
                                .foregroundColor(theme.colors.ink)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityValue(row.isRead ? "" : mrasemString("mrasem_notices_unread"))
                    }
                }
            }
        }
    }
}

#Preview("Notices - Light") {
    MrasemScreenPreview(.light) {
        NoticeInboxCard(
            state: .make(MrasemSeed.demo(), user: .member("m1")), onMarkRead: {}
        )
    }
}
