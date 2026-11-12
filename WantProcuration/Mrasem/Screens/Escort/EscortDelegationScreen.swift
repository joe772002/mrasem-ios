//
//  EscortDelegationScreen.swift
//  Mrasem
//
//  Phase 16 — «وفدي» للمرافق: وفوده، أعضاؤه (غرفة / سيارة / سائق)، وبرنامج النهاردة.
//

import SwiftUI

struct EscortDelegationScreen: View {
    @StateObject private var model: EscortDelegationModel

    init(context: MrasemAppContext) {
        _model = StateObject(wrappedValue: EscortDelegationModel(backend: context.backend))
    }

    var body: some View {
        EscortDelegationContent(state: model.uiState)
    }
}

struct EscortDelegationContent: View {
    @Environment(\.mrasem) private var theme

    let state: EscortHomeState

    var body: some View {
        MrasemScreenContent {
            VStack(alignment: .leading, spacing: 4) {
                Text("mrasem_tab_escort_delegation")
                    .mrasemText(theme.type.heroDest)
                    .foregroundColor(theme.colors.maroon)
                    .accessibilityAddTraits(.isHeader)
                if !state.meetingSpot.isEmpty {
                    Text(mrasemString("mrasem_escort_spot", [state.meetingSpot]))
                        .mrasemText(theme.type.bodySm)
                        .foregroundColor(theme.colors.muted)
                }
            }

            if state.delegations.isEmpty {
                Text("mrasem_escort_empty")
                    .mrasemText(theme.type.body)
                    .foregroundColor(theme.colors.muted)
            }
            ForEach(state.delegations) { card in
                delegationCard(card)
            }
        }
    }

    private func delegationCard(_ card: EscortDelegationCard) -> some View {
        MrasemCard(title: card.name) {
            VStack(alignment: .leading, spacing: 10) {
                Text(mrasemString("mrasem_escort_dates", [
                    card.start.toArabicDigits(), card.end.toArabicDigits(), card.hotelName ?? "—"
                ]))
                .mrasemText(theme.type.bodySm)
                .foregroundColor(theme.colors.muted)

                Text("mrasem_escort_members")
                    .mrasemText(theme.type.strong)
                    .foregroundColor(theme.colors.maroon)
                if card.members.isEmpty {
                    Text("mrasem_escort_no_members")
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.muted)
                }
                ForEach(card.members) { member in
                    MrasemActionRow(
                        title: member.name,
                        subtitle: mrasemString("mrasem_escort_member_subtitle", [
                            member.room.isEmpty ? "—" : member.room.toArabicDigits(),
                            member.carLabel ?? mrasemString("mrasem_admin_res_no_car"),
                            member.driverName ?? mrasemString("mrasem_admin_res_no_driver")
                        ])
                    ) {
                        if member.isHead {
                            MrasemPill(mrasemString("mrasem_escort_head"), kind: .ok)
                        }
                    }
                }

                Text("mrasem_escort_today")
                    .mrasemText(theme.type.strong)
                    .foregroundColor(theme.colors.maroon)
                if card.today.isEmpty {
                    Text("mrasem_escort_today_empty")
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.muted)
                }
                ForEach(card.today) { item in
                    MrasemActionRow(
                        title: mrasemString("mrasem_escort_item_title", [item.time.toArabicDigits(), item.title]),
                        subtitle: mrasemString("mrasem_escort_item_subtitle", [
                            mrasemString(item.kind.labelKey), item.placeName ?? "—",
                            item.carLabel ?? mrasemString("mrasem_admin_res_no_car")
                        ])
                    )
                }
            }
        }
    }
}

#Preview("Escort - Light") {
    MrasemScreenPreview(.light) {
        EscortDelegationContent(state: .make(MrasemSeed.demo(), escortId: "e1", today: "2026-11-24"))
    }
}
