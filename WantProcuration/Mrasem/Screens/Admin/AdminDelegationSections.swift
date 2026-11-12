//
//  AdminDelegationSections.swift
//  Mrasem
//
//  Phase 14 — كروت تفاصيل الوفد: الرأس (بيانات + حالة)، الأعضاء والتعيينات، البرنامج.
//

import SwiftUI

struct AdminDelegationHeaderCard: View {
    @Environment(\.mrasem) private var theme

    let detail: AdminDelegationDetail
    let actions: AdminDetailActions

    var body: some View {
        let d = detail.delegation
        let none = mrasemString("mrasem_admin_unassigned")

        MrasemCard(title: d.name, headerEnd: AnyView(MrasemPill(mrasemString(d.status.labelKey), kind: d.status == .active ? .ok : .neutral))) {
            MrasemKeyValueList([
                KeyValue(mrasemString("mrasem_admin_kv_mode"), mrasemString(d.mode.adminLabelKey)),
                KeyValue(mrasemString("mrasem_admin_kv_host"), d.host.isEmpty ? none : d.host),
                KeyValue(mrasemString("mrasem_admin_kv_period"),
                         mrasemString("mrasem_team_archive_period_value", [d.start.toArabicDigits(), d.end.toArabicDigits()])),
                KeyValue(mrasemString("mrasem_admin_kv_hotel"), detail.hotelName ?? none),
                KeyValue(mrasemString("mrasem_admin_kv_venue"), detail.venueName ?? none),
                KeyValue(mrasemString("mrasem_admin_kv_dress"), mrasemString(d.dress.adminLabelKey)),
                KeyValue(mrasemString("mrasem_admin_kv_readiness"),
                         mrasemString("mrasem_admin_readiness", [detail.readiness.toArabicDigits()]))
            ])

            HStack(spacing: 8) {
                MrasemButton(mrasemString("mrasem_admin_detail_edit"), variant: .primary, action: actions.onEdit)
                statusButton(d.status)
            }
        }
    }

    /// مسودة ← تفعيل، نشط ← أرشفة، مؤرشف ← استعادة.
    @ViewBuilder
    private func statusButton(_ status: DelegationStatus) -> some View {
        switch status {
        case .draft:
            MrasemButton(mrasemString("mrasem_admin_detail_activate")) { actions.onStatus(.active) }
        case .active:
            MrasemButton(mrasemString("mrasem_admin_detail_archive")) { actions.onStatus(.archived) }
        case .archived:
            MrasemButton(mrasemString("mrasem_admin_detail_restore")) { actions.onStatus(.active) }
        }
    }
}

struct AdminMembersCard: View {
    @Environment(\.mrasem) private var theme

    let members: [AdminMemberRow]
    let actions: AdminDetailActions

    var body: some View {
        MrasemCard(
            title: mrasemString("mrasem_admin_members_title"),
            headerEnd: AnyView(MrasemButton(mrasemString("mrasem_admin_members_add"), variant: .ghost, action: actions.onAddMember))
        ) {
            if members.isEmpty {
                Text("mrasem_admin_members_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(members) { member in
                        HStack(spacing: 10) {
                            MrasemAvatarInitial(member.name)
                            MrasemActionRow(title: member.name, subtitle: subtitle(member)) {
                                VStack(alignment: .trailing, spacing: 4) {
                                    if member.isHead { MrasemPill(mrasemString("mrasem_admin_member_head")) }
                                    MrasemPill(
                                        mrasemString(member.isActivated ? "mrasem_admin_member_activated" : "mrasem_admin_member_invited"),
                                        kind: member.isActivated ? .ok : .neutral
                                    )
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { actions.onEditMember(member.id) }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    private func subtitle(_ member: AdminMemberRow) -> String {
        let none = mrasemString("mrasem_admin_unassigned")
        return mrasemString("mrasem_admin_member_detail", [
            member.escortName ?? none,
            member.carLabel ?? none,
            member.room.isEmpty ? none : member.room
        ])
    }
}

struct AdminProgramCard: View {
    @Environment(\.mrasem) private var theme

    let days: [AdminProgramDay]
    let actions: AdminDetailActions

    var body: some View {
        MrasemCard(
            title: mrasemString("mrasem_admin_program_title"),
            headerEnd: AnyView(MrasemButton(mrasemString("mrasem_admin_program_add"), variant: .ghost) { actions.onAddItem(nil) })
        ) {
            if days.isEmpty {
                Text("mrasem_admin_program_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(day.label)
                                .mrasemText(theme.type.strong)
                                .foregroundColor(theme.colors.maroon)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(day.items) { item in row(item) }
                        }
                    }
                }
            }
        }
    }

    private func row(_ item: AdminProgramRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            MrasemActionRow(title: time(item) + "  " + item.title, subtitle: subtitle(item)) {
                VStack(alignment: .trailing, spacing: 4) {
                    if item.isKey { MrasemPill(mrasemString("mrasem_admin_pill_key")) }
                    if item.isChanged { MrasemPill(mrasemString("mrasem_admin_pill_changed"), kind: .ok) }
                    if item.hasConflict { MrasemPill(mrasemString("mrasem_admin_pill_conflict"), kind: .warn) }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { actions.onEditItem(item.id) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)

            if item.kind != .free {
                MrasemButton(mrasemString("mrasem_admin_postpone"), variant: .ghost) { actions.onPostpone(item.id) }
            }
        }
    }

    private func time(_ item: AdminProgramRow) -> String {
        item.endTime.map { item.time + "–" + $0 } ?? item.time
    }

    private func subtitle(_ item: AdminProgramRow) -> String {
        [mrasemString(item.kind.labelKey), item.placeName, item.carLabel].compactMap { $0 }.joined(separator: " · ")
    }
}
