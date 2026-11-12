//
//  TeamVisitScreen.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/screens/team/TeamVisitScreen.kt
//

import SwiftUI

/// تاب «الزيارة» للفريق: نموذج 8 حقول (01-DESIGN-SPEC §8).
struct TeamVisitScreen: View {
    @StateObject private var viewModel: TeamVisitViewModel

    init(context: MrasemAppContext) {
        _viewModel = StateObject(wrappedValue: TeamVisitViewModel(
            session: context.container.session,
            team: context.container.team,
            visit: context.container.visitUpdate,
            toastBus: context.toastBus
        ))
    }

    var body: some View {
        TeamVisitContent(state: viewModel.uiState, onSection: viewModel.onSection, onSave: viewModel.onSave)
    }
}

/// حقل نصي في شبكة العمودين.
private struct VisitField {
    let labelKey: String
    let ltr: Bool
    let keyPath: WritableKeyPath<VisitData, String>
}

private let visitFields: [VisitField] = [
    VisitField(labelKey: "mrasem_team_field_receiver_name", ltr: false, keyPath: \.receiverName),
    VisitField(labelKey: "mrasem_team_field_receiver_phone", ltr: true, keyPath: \.receiverPhone),
    VisitField(labelKey: "mrasem_team_field_car_type", ltr: false, keyPath: \.carType),
    VisitField(labelKey: "mrasem_team_field_car_plate", ltr: true, keyPath: \.carPlate),
    VisitField(labelKey: "mrasem_team_field_driver", ltr: false, keyPath: \.driver),
    VisitField(labelKey: "mrasem_team_field_hall", ltr: false, keyPath: \.hall),
    VisitField(labelKey: "mrasem_team_field_floor", ltr: false, keyPath: \.floor),
]

struct TeamVisitContent: View {
    @Environment(\.mrasem) private var theme

    let state: TeamVisitUiState
    let onSection: (TeamTab) -> Void
    let onSave: (VisitForm) -> Void

    // المسودة بتبدأ من القيم الحالية وبتتصفّر لما الـ source يتغير (حفظ أو تغيير الوضع).
    @State private var data: VisitData
    @State private var dressIndex: Int

    init(state: TeamVisitUiState, onSection: @escaping (TeamTab) -> Void, onSave: @escaping (VisitForm) -> Void) {
        self.state = state
        self.onSection = onSection
        self.onSave = onSave
        _data = State(initialValue: state.form.data)
        _dressIndex = State(initialValue: DressCode.allCases.firstIndex(of: state.form.dress) ?? 0)
    }

    var body: some View {
        MrasemScreenContent {
            TeamHeader(header: state.header, onSection: onSection)
            MrasemCard(title: state.guest) {
                Text(mrasemString("mrasem_team_visit_hint"))
                    .mrasemText(theme.type.label)
                    .foregroundColor(theme.colors.muted)

                // 7 حقول نصية + زي اليوم = 8 في عمودين.
                ForEach(Array(stride(from: 0, through: visitFields.count, by: 2)), id: \.self) { start in
                    HStack(alignment: .bottom, spacing: 10) {
                        cell(start).frame(maxWidth: .infinity)
                        cell(start + 1).frame(maxWidth: .infinity)
                    }
                }

                MrasemButton(mrasemString("mrasem_team_visit_save"), variant: .primary, block: true) {
                    onSave(VisitForm(data: data, dress: DressCode.allCases[dressIndex]))
                }
            }
        }
        .onChange(of: state.form) { _, form in
            data = form.data
            dressIndex = DressCode.allCases.firstIndex(of: form.dress) ?? 0
        }
    }

    @ViewBuilder
    private func cell(_ index: Int) -> some View {
        if index < visitFields.count {
            let field = visitFields[index]
            MrasemTextField(
                value: Binding(get: { data[keyPath: field.keyPath] }, set: { data[keyPath: field.keyPath] = $0 }),
                label: mrasemString(field.labelKey),
                ltr: field.ltr
            )
        } else if index == visitFields.count {
            MrasemSelect(
                options: [mrasemString("mrasem_dress_option_formal"), mrasemString("mrasem_dress_option_bisht")],
                selectedIndex: $dressIndex,
                label: mrasemString("mrasem_team_field_dress")
            )
        } else {
            Color.clear.frame(maxWidth: .infinity)
        }
    }
}

#Preview("Team visit - Light") {
    MrasemScreenPreview(.light) {
        TeamVisitContent(state: TeamPreviewData.visit(), onSection: { _ in }, onSave: { _ in })
    }
}

#Preview("Team visit - Dark") {
    MrasemScreenPreview(.dark) {
        TeamVisitContent(state: TeamPreviewData.visit(), onSection: { _ in }, onSave: { _ in })
    }
}
