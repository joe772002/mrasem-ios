//
//  TeamHeader.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamHeader.kt
//

import SwiftUI

/// رأس لوحة الفريق المشترك: 3 KPIs + chips الأقسام (متزامنة مع الـ bottom bar) (01-DESIGN-SPEC §8).
struct TeamHeaderUi: Equatable {
    let kpis: TeamKpis
    let tab: TeamTab

    static func make(_ state: MrasemState, team: TeamStrategy) -> TeamHeaderUi {
        TeamHeaderUi(kpis: team.kpis(state: state), tab: state.teamTab)
    }
}

extension TeamTab {
    var sectionLabelKey: String {
        switch self {
        case .visit: return "mrasem_team_section_visit"
        case .changes: return "mrasem_tab_team_changes"
        case .requests: return "mrasem_tab_team_requests"
        case .archive: return "mrasem_tab_team_archive"
        }
    }
}

struct TeamHeader: View {
    let header: TeamHeaderUi
    let onSection: (TeamTab) -> Void

    var body: some View {
        let kpis = header.kpis

        HStack(alignment: .top, spacing: 8) {
            MrasemKpiTile(
                value: kpis.arrivalCompleted
                    ? mrasemString("mrasem_team_kpi_arrival_done")
                    : mrasemString("mrasem_team_kpi_arrival_value", [kpis.arrivalStage.toArabicDigits()]),
                label: mrasemString("mrasem_team_kpi_arrival")
            )
            MrasemKpiTile(value: kpis.newRequests.toArabicDigits(), label: mrasemString("mrasem_team_kpi_requests"))
            MrasemKpiTile(value: kpis.sentUpdates.toArabicDigits(), label: mrasemString("mrasem_team_kpi_updates"))
        }

        MrasemFlowLayout(spacing: 6) {
            ForEach(TeamTab.allCases, id: \.self) { tab in
                MrasemChip(mrasemString(tab.sectionLabelKey), selected: tab == header.tab) { onSection(tab) }
            }
        }
    }
}
