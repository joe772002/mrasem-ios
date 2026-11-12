//
//  MrasemContainer.swift
//  Mrasem
//
//  تجميع الاعتماديات — بديل الـ Hilt في Android (di/module/MrasemModule.kt + RepositoryModule.kt).
//  الحقن بالـ initializer (قاعدة A4).
//

import Foundation

/// كل تبعيات مراسم في مكان واحد. الـ ViewModels بتاخدها من هنا.
nonisolated final class MrasemContainer {
    let repository: MissionRepository
    let preferences: MrasemPreferences

    let session: MrasemSessionStrategy
    let missionSummary: MissionSummaryStrategy
    let program: ProgramStrategy
    let explore: ExploreStrategy
    let assistant: AssistantStrategy
    let visitUpdate: VisitUpdateStrategy
    let team: TeamStrategy
    let protocolStrategy: ProtocolStrategy

    init(
        repository: MissionRepository = InMemoryMissionRepository(),
        preferences: MrasemPreferences = UserDefaultsMrasemPreferences(),
        now: @escaping () -> MrasemDate = { MrasemDate.today() }
    ) {
        self.repository = repository
        self.preferences = preferences

        self.session = MrasemSessionStrategy(repository: repository, preferences: preferences)
        self.missionSummary = MissionSummaryStrategy(repository: repository, now: now)
        self.program = ProgramStrategy(repository: repository)
        self.explore = ExploreStrategy(repository: repository)
        self.assistant = AssistantStrategy(repository: repository)
        self.visitUpdate = VisitUpdateStrategy(repository: repository)
        self.team = TeamStrategy(repository: repository)
        self.protocolStrategy = ProtocolStrategy(repository: repository)
    }
}
