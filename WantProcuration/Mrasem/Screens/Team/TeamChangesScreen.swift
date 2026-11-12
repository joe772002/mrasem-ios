//
//  TeamChangesScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamChangesScreen.kt
//

import SwiftUI

/// تاب «التغييرات» للفريق: تأجيل ٣٠ دقيقة + تنبيه عام (01-DESIGN-SPEC §8).
struct TeamChangesScreen: View {
    @StateObject private var viewModel: TeamChangesViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: TeamChangesViewModel(
            session: context.container.session,
            team: context.container.team,
            program: context.container.program,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        TeamChangesContent(
            state: viewModel.uiState,
            onSection: viewModel.onSection,
            onPostpone: viewModel.onPostpone,
            onBroadcast: viewModel.onBroadcast
        )
    }
}

struct TeamChangesContent: View {
    @Environment(\.mrasem) private var theme

    let state: TeamChangesUiState
    let onSection: (TeamTab) -> Void
    let onPostpone: () -> Void
    let onBroadcast: (String) -> Bool

    @State private var input = ""

    var body: some View {
        MrasemScreenContent {
            TeamHeader(header: state.header, onSection: onSection)

            MrasemCard(title: mrasemString("mrasem_team_changes_title")) {
                Text(mrasemString("mrasem_team_changes_hint"))
                    .mrasemText(theme.type.label)
                    .foregroundColor(theme.colors.muted)
                if let item = state.keyItem {
                    MrasemActionRow(
                        title: item.title,
                        subtitle: mrasemString("mrasem_team_changes_when", [item.dayLabel, item.time])
                    ) {
                        MrasemButton(mrasemString("mrasem_team_changes_postpone"), variant: .primary, action: onPostpone)
                    }
                }
            }

            MrasemCard(title: mrasemString("mrasem_team_broadcast_title")) {
                MrasemAskBar(
                    value: $input,
                    placeholder: mrasemString("mrasem_team_broadcast_placeholder"),
                    sendLabel: mrasemString("mrasem_team_broadcast_send")
                ) {
                    if onBroadcast(input) {
                        input = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

#Preview("Team changes - Light") {
    MrasemScreenPreview(.light) {
        TeamChangesContent(state: TeamPreviewData.changes(), onSection: { _ in }, onPostpone: {}, onBroadcast: { _ in true })
    }
}

#Preview("Team changes - Dark") {
    MrasemScreenPreview(.dark) {
        TeamChangesContent(state: TeamPreviewData.changes(), onSection: { _ in }, onPostpone: {}, onBroadcast: { _ in true })
    }
}
