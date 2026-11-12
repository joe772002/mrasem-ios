//
//  TeamRequestsScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamRequestsScreen.kt
//

import SwiftUI

/// تاب «الطلبات» للفريق (01-DESIGN-SPEC §8).
struct TeamRequestsScreen: View {
    @StateObject private var viewModel: TeamRequestsViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: TeamRequestsViewModel(
            session: context.container.session,
            team: context.container.team,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        TeamRequestsContent(state: viewModel.uiState, onSection: viewModel.onSection, onResolve: viewModel.onResolve)
    }
}

struct TeamRequestsContent: View {
    @Environment(\.mrasem) private var theme

    let state: TeamRequestsUiState
    let onSection: (TeamTab) -> Void
    let onResolve: (Int64) -> Void

    var body: some View {
        MrasemScreenContent {
            TeamHeader(header: state.header, onSection: onSection)
            MrasemCard(title: mrasemString("mrasem_team_requests_title")) {
                if state.requests.isEmpty {
                    Text(mrasemString("mrasem_team_requests_empty"))
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.muted)
                } else {
                    VStack(spacing: 8) {
                        ForEach(state.requests) { request in
                            requestRow(request)
                        }
                    }
                }
            }
        }
    }

    private func requestRow(_ request: GuestRequest) -> some View {
        let done = request.status == .done
        let title = request.place.map { mrasemString("mrasem_team_request_visit", [$0]) }
            ?? mrasemString("mrasem_team_request_question", [request.text ?? ""])

        return MrasemActionRow(
            title: title,
            subtitle: mrasemString(done ? "mrasem_team_request_arranged" : "mrasem_team_request_pending")
        ) {
            if done {
                MrasemPill(mrasemString("mrasem_team_request_done"), kind: .ok)
            } else {
                MrasemButton(mrasemString("mrasem_team_request_arranged"), variant: .primary) {
                    onResolve(request.id)
                }
            }
        }
    }
}

#Preview("Team requests - Light") {
    MrasemScreenPreview(.light) {
        TeamRequestsContent(state: TeamPreviewData.requests(), onSection: { _ in }, onResolve: { _ in })
    }
}

#Preview("Team requests - Dark") {
    MrasemScreenPreview(.dark) {
        TeamRequestsContent(state: TeamPreviewData.requests(), onSection: { _ in }, onResolve: { _ in })
    }
}

#Preview("Team requests empty - Light") {
    MrasemScreenPreview(.light) {
        TeamRequestsContent(state: TeamPreviewData.requests(empty: true), onSection: { _ in }, onResolve: { _ in })
    }
}
