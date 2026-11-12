// AI-FEATURE (disabled): describe-transaction feature, commented out on request. Search "AI-FEATURE" to delete or restore.
/*
//
//  FindTransactionIntent.swift
//  WantProcuration
//
//  "عايز أعمل توكيل": Siri asks the user to describe what they want, the app's own matcher
//  (AI/TransactionMatcher.swift) picks the category + type from the nearest office's real list,
//  and the reservation form opens with them selected. The user reviews and books in the app.
//

import AppIntents
internal import CoreLocation

nonisolated struct FindTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "اعرف نوع التوكيل من الوصف"
    static let description = IntentDescription("توصف المعاملة اللي عايزها، والتطبيق يختار النوع المناسب ويفتح فورم الحجز في أقرب مكتب.")
    static let openAppWhenRun: Bool = true

    @Parameter(
        title: "وصف المعاملة",
        requestValueDialog: IntentDialog("قولّي عايز تعمل إيه بالظبط؟ مثلًا: توكيل لأخويا عشان يبيع العربية.")
    )
    var transactionDescription: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Logger.info("Intent: FindTransaction \"\(transactionDescription)\"")
        let location = try await OneShotLocationProvider().currentLocation()
        let office = try await NearestOfficeFinder.find(from: location)

        let categories: [TransactionCategory]
        do {
            categories = try await APIClient.shared.getTransactionCategories(selectedOffice: office)
        } catch {
            throw IntentError.from(error)
        }

        let suggestion = await TransactionMatcher.suggest(
            description: transactionDescription,
            categories: categories,
            loadTypes: { category in
                try await APIClient.shared.getTransactionTypes(selectedOffice: office, selectedCategory: category)
            }
        )

        IntentRouter.shared.pendingReservation = PendingReservation(
            office: office,
            categoryCode: suggestion?.category.code,
            typeCode: suggestion?.type?.code
        )

        guard let suggestion else {
            return .result(dialog: "مقدرتش أحدد النوع من الوصف ده. فتحتلك فورم الحجز في \(office.orgUnitName) تختار بنفسك.")
        }
        let name = suggestion.type?.desc ?? suggestion.category.desc ?? ""
        return .result(dialog: "النوع المناسب: \(name). فتحتلك فورم الحجز في \(office.orgUnitName)، راجع البيانات وكمّل الحجز.")
    }
}
*/
