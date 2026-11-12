//
//  VisitUpdateStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/VisitUpdateStrategy.kt
//

import Foundation

/// محتوى نموذج «بيانات الزيارة».
struct VisitForm: Equatable {
    let data: VisitData
    let dress: DressCode
}

enum VisitSaveResult: Equatable {
    /// «لا توجد تغييرات لحفظها.»
    case noChanges
    /// «تم الحفظ. وصل تنبيه للضيف…»
    case saved(sections: Set<ChangedSection>, dressChanged: Bool)
}

final class VisitUpdateStrategy {
    private let repository: MissionRepository

    init(repository: MissionRepository) {
        self.repository = repository
    }

    func currentForm(state: MrasemState? = nil) -> VisitForm {
        let state = state ?? repository.state
        return VisitForm(data: Self.visitData(state.mission), dress: state.dress)
    }

    /// يحفظ النموذج: الحقل الفاضي يحتفظ بالقيمة القديمة، الأقسام اللي اتغيرت فعلاً تتعلّم «محدَّث»،
    /// ويتضاف Notice (زي اتغيّر ← dressApproved، غير كده ← visitDataUpdated).
    func save(_ form: VisitForm) -> VisitSaveResult {
        let state = repository.state
        let before = Self.visitData(state.mission)
        let after = Self.merge(before, input: form.data)
        let sections = Self.changedSections(before, after: after)
        let dressChanged = form.dress != state.dress

        guard !sections.isEmpty || dressChanged else { return .noChanges }

        repository.updateVisitData(mode: state.mode, data: after)
        repository.setDress(form.dress)
        repository.markChanged(Set(sections.map { ChangeKey.section(mode: state.mode, section: $0) }))
        repository.addNotice(
            mode: state.mode,
            content: dressChanged ? .dressApproved(form.dress) : .visitDataUpdated
        )

        return .saved(sections: sections, dressChanged: dressChanged)
    }

    static func visitData(_ mission: Mission) -> VisitData {
        VisitData(
            receiverName: mission.receiver.name,
            receiverPhone: mission.receiver.phone,
            carType: mission.car.type,
            carPlate: mission.car.plate,
            driver: mission.car.driver,
            hall: mission.venue.hall,
            floor: mission.venue.floor
        )
    }

    /// القيمة المكتوبة بعد trim، أو القديمة لو فاضية.
    static func merge(_ old: VisitData, input: VisitData) -> VisitData {
        func pick(_ new: String, _ previous: String) -> String {
            let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? previous : trimmed
        }

        return VisitData(
            receiverName: pick(input.receiverName, old.receiverName),
            receiverPhone: pick(input.receiverPhone, old.receiverPhone),
            carType: pick(input.carType, old.carType),
            carPlate: pick(input.carPlate, old.carPlate),
            driver: pick(input.driver, old.driver),
            hall: pick(input.hall, old.hall),
            floor: pick(input.floor, old.floor)
        )
    }

    static func changedSections(_ before: VisitData, after: VisitData) -> Set<ChangedSection> {
        var sections: Set<ChangedSection> = []

        if before.receiverName != after.receiverName || before.receiverPhone != after.receiverPhone {
            sections.insert(.receiver)
        }
        if before.carType != after.carType || before.carPlate != after.carPlate || before.driver != after.driver {
            sections.insert(.car)
        }
        if before.hall != after.hall || before.floor != after.floor {
            sections.insert(.venue)
        }

        return sections
    }
}
