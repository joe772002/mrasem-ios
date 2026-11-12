//
//  MyReservationIntent.swift
//  WantProcuration
//
//  "موعد حجزي": asks for the national ID every time (nothing is stored)
//  and reads back the next upcoming reservation.
//

import AppIntents
import Foundation

nonisolated struct MyReservationIntent: AppIntent {
    static let title: LocalizedStringResource = "موعد حجزي"
    static let description = IntentDescription("الاستعلام عن حجوزاتك في مكاتب التوثيق باستخدام الرقم القومي.")

    @Parameter(
        title: "الرقم القومي",
        inputOptions: String.IntentInputOptions(keyboardType: .numberPad), requestValueDialog: IntentDialog("من فضلك، أخبرني بالرقم القومي المكوّن من 14 رقمًا.")
    )
    var nationalId: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let id = NationalIdNormalizer.normalize(nationalId)
        guard id.count == 14 else {
            throw $nationalId.needsValueError("يجب أن يتكون الرقم القومي من 14 رقمًا. يُرجى إعادة المحاولة.")
        }

        let response: InquireReserveResponse
        do {
            response = try await APIClient.shared.getInquireMyReserve(customerId: id)
        } catch {
            Logger.error("Intent: inquiry failed: \(error)")
            throw IntentError.from(error)
        }

        Logger.info("Intent: inquiry status \(response.statusCode), \(response.inquireReserve.count) items")
        let upcoming = response.inquireReserve
            .filter { $0.datePreview >= Self.todayString() }
            .sorted { $0.datePreview < $1.datePreview }

        guard let next = upcoming.first else {
            return .result(dialog: "لا توجد حجوزات قادمة مسجّلة بهذا الرقم القومي.")
        }

        let more = upcoming.count > 1 ? " عدد حجوزاتك القادمة الأخرى: \(upcoming.count - 1)." : ""
        return .result(dialog: "أقرب حجز لك يوم \(next.datePreview)، \(next.timeRangePreview)، في \(next.orgName)، لمعاملة \(next.transactionTypeDesc).\(more)")
    }

    /// "yyyy-MM-dd" so it compares as text with `InquireReserveItem.datePreview`.
    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
