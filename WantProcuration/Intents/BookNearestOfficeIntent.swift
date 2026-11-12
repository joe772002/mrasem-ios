//
//  BookNearestOfficeIntent.swift
//  WantProcuration
//
//  "احجزلي في أقرب مكتب": finds the nearest office and opens its reservation form.
//  The user completes and confirms the booking in the app.
//

import AppIntents
internal import CoreLocation

nonisolated struct BookNearestOfficeIntent: AppIntent {
    static let title: LocalizedStringResource = "الحجز في أقرب مكتب توثيق"
    static let description = IntentDescription("يحدد أقرب مكتب توثيق إلى موقعك ويفتح نموذج الحجز الخاص به.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Logger.info("Intent: BookNearestOffice started")
        let location = try await OneShotLocationProvider().currentLocation()
        Logger.info("Intent: location \(location.coordinate.latitude), \(location.coordinate.longitude)")
        let office = try await NearestOfficeFinder.find(from: location)
        Logger.info("Intent: nearest office \(office.orgUnitName) (\(office.distance) km)")

        IntentRouter.shared.pendingReservation = PendingReservation(office: office)

        let km = String(format: "%.1f", office.distance)
        return .result(dialog: "أقرب مكتب إليك: \(office.orgUnitName)، على بُعد \(km) كم. تم فتح نموذج الحجز.")
    }
}
