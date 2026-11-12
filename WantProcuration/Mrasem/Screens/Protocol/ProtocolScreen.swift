//
//  ProtocolScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/protocol/ProtocolScreen.kt
//

import SwiftUI

/// تاب «البروتوكول» للضيف (01-DESIGN-SPEC §7.5).
struct ProtocolScreen: View {
    @StateObject private var viewModel: ProtocolViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: ProtocolViewModel(
            session: context.container.session,
            protocolStrategy: context.container.protocolStrategy,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        ProtocolContentView(
            state: viewModel.uiState,
            onCheckToggle: viewModel.onCheckToggle,
            onGuideClick: viewModel.onGuideClick
        )
    }
}

struct ProtocolContentView: View {
    @Environment(\.mrasem) private var theme

    let state: ProtocolUiState
    let onCheckToggle: (Int) -> Void
    let onGuideClick: (String) -> Void

    var body: some View {
        let content = state.content

        MrasemScreenContent {
            // 1) بطاقة الـ ٣٠ ثانية (Hero).
            MrasemHeroCard {
                HStack(alignment: .center, spacing: 12) {
                    MrasemPill(mrasemString("mrasem_protocol_card_label"))
                    Text(mrasemString("mrasem_protocol_next_meeting"))
                        .mrasemText(theme.type.label)
                        .foregroundColor(theme.colors.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(content.nextMeeting.who)
                    .mrasemText(theme.type.cardTitle)
                    .foregroundColor(theme.colors.ink)
                MrasemKeyValueList([
                    KeyValue(mrasemString("mrasem_protocol_kv_address"), content.nextMeeting.address),
                    KeyValue(mrasemString("mrasem_protocol_kv_seat"), content.nextMeeting.seat),
                    KeyValue(mrasemString("mrasem_protocol_kv_gift"), content.nextMeeting.gift),
                    KeyValue(mrasemString("mrasem_protocol_kv_lang"), content.nextMeeting.language),
                ])
            }

            dressCard(content)
            checklistCard(content)

            // 4) آداب وأعراف.
            MrasemCard(title: mrasemString(content.isInbound ? "mrasem_protocol_customs_inbound" : "mrasem_protocol_customs_outbound")) {
                ForEach(Array(content.customs.enumerated()), id: \.offset) { _, item in
                    bullet(item)
                }
            }

            // 5) الدليل الإرشادي.
            MrasemCard(title: mrasemString("mrasem_protocol_guides_title")) {
                MrasemFlowLayout(spacing: 6) {
                    ForEach(Array(content.guides.enumerated()), id: \.offset) { _, guide in
                        MrasemChip(guide) { onGuideClick(guide) }
                    }
                }
            }
        }
    }

    /// 2) زي اليوم: الرسمة + عمودين (للرجال / للنساء).
    private func dressCard(_ content: ProtocolContent) -> some View {
        MrasemCard(
            title: mrasemString("mrasem_protocol_dress_title"),
            headerEnd: AnyView(MrasemPill(mrasemString("mrasem_protocol_dress_approved"), kind: .ok))
        ) {
            HStack(alignment: .center, spacing: 12) {
                MrasemDressIllustration(kind: content.dressCode == .bisht ? .bisht : .formal, width: 96, height: 120)
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.dress.title)
                        .mrasemText(theme.type.strong)
                        .foregroundColor(theme.colors.ink)
                    Text(mrasemString("mrasem_protocol_dress_note"))
                        .mrasemText(theme.type.label)
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .top, spacing: 10) {
                dressColumn(titleKey: "mrasem_protocol_men", items: content.dress.men)
                dressColumn(titleKey: "mrasem_protocol_women", items: content.dress.women)
            }
        }
    }

    private func dressColumn(titleKey: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mrasemString(titleKey))
                .mrasemText(theme.type.strong)
                .foregroundColor(theme.colors.muted)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                bullet(item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 3) قبل الخروج من الفندق.
    private func checklistCard(_ content: ProtocolContent) -> some View {
        MrasemCard(title: mrasemString("mrasem_protocol_checklist_title")) {
            ForEach(content.checklist, id: \.index) { item in
                MrasemChecklistRow(text: item.label, checked: item.checked) { onCheckToggle(item.index) }
            }
            Text(mrasemString("mrasem_protocol_checklist_ready", [
                content.readyCount.toArabicDigits(),
                content.checklist.count.toArabicDigits(),
            ]))
            .mrasemText(theme.type.label)
            .foregroundColor(theme.colors.muted)
        }
    }

    private func bullet(_ text: String) -> some View {
        Text("• \(text)")
            .mrasemText(theme.type.bodySm)
            .foregroundColor(theme.colors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

private enum ProtocolPreviewData {
    static func state(_ mode: MissionMode, checked: Set<Int> = []) -> ProtocolUiState {
        var state = MrasemState(missions: MrasemDemoData.missions)
        state.mode = mode
        state.checks[mode] = checked
        let repo = InMemoryMissionRepository(missions: MrasemDemoData.missions)
        return ProtocolUiState(content: ProtocolStrategy(repository: repo).content(state: state))
    }
}

#Preview("Protocol inbound - Light") {
    MrasemScreenPreview(.light) {
        ProtocolContentView(state: ProtocolPreviewData.state(.inbound, checked: [0, 2]), onCheckToggle: { _ in }, onGuideClick: { _ in })
    }
}

#Preview("Protocol inbound - Dark") {
    MrasemScreenPreview(.dark) {
        ProtocolContentView(state: ProtocolPreviewData.state(.inbound, checked: [0, 2]), onCheckToggle: { _ in }, onGuideClick: { _ in })
    }
}

#Preview("Protocol outbound - Light") {
    MrasemScreenPreview(.light) {
        ProtocolContentView(state: ProtocolPreviewData.state(.outbound), onCheckToggle: { _ in }, onGuideClick: { _ in })
    }
}
