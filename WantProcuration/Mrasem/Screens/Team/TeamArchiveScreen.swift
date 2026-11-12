//
//  TeamArchiveScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamArchiveScreen.kt
//

import SwiftUI

/// تاب «الأرشيف» للفريق (01-DESIGN-SPEC §8).
struct TeamArchiveScreen: View {
    @StateObject private var viewModel: TeamArchiveViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: TeamArchiveViewModel(
            session: context.container.session,
            team: context.container.team,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        TeamArchiveContent(state: viewModel.uiState, onSection: viewModel.onSection, onReport: viewModel.onReport)
    }
}

struct TeamArchiveContent: View {
    @Environment(\.mrasem) private var theme

    let state: TeamArchiveUiState
    let onSection: (TeamTab) -> Void
    let onReport: () -> Void

    var body: some View {
        let archive = state.archive

        MrasemScreenContent {
            TeamHeader(header: state.header, onSection: onSection)
            MrasemCard(title: mrasemString("mrasem_team_archive_title")) {
                MrasemKeyValueList([
                    KeyValue(mrasemString("mrasem_team_archive_guest"), archive.guest),
                    KeyValue(mrasemString("mrasem_team_archive_host"), archive.host),
                    // التواريخ ISO بالأرقام اللاتينية زي المصدر (01-DESIGN-SPEC §10).
                    KeyValue(
                        mrasemString("mrasem_team_archive_period"),
                        mrasemString("mrasem_team_archive_period_value", [archive.start.iso, archive.end.iso])
                    ),
                    KeyValue(mrasemString("mrasem_team_archive_items"), archive.officialCount.toArabicDigits()),
                    KeyValue(mrasemString("mrasem_team_archive_gifts"), mrasemString("mrasem_team_archive_gifts_value")),
                ])
                Text(mrasemString("mrasem_team_archive_hint"))
                    .mrasemText(theme.type.label)
                    .foregroundColor(theme.colors.muted)
                MrasemButton(mrasemString("mrasem_team_archive_report"), action: onReport)
            }
        }
    }
}

#Preview("Team archive - Light") {
    MrasemScreenPreview(.light) {
        TeamArchiveContent(state: TeamPreviewData.archive(), onSection: { _ in }, onReport: {})
    }
}

#Preview("Team archive - Dark") {
    MrasemScreenPreview(.dark) {
        TeamArchiveContent(state: TeamPreviewData.archive(), onSection: { _ in }, onReport: {})
    }
}
