//
//  IntentRouter.swift
//  WantProcuration
//
//  Bridges App Intents (Siri / Shortcuts) to in-app navigation.
//

import SwiftUI
import Combine
import SwiftfulRouting

/// Shared state that an App Intent writes to, and the UI reads from, to open a screen.
final class IntentRouter: ObservableObject {
    static let shared = IntentRouter()

    /// When set, the app pushes the reservation form for this office.
    @Published var pendingReservation: PendingReservation?

    private init() {}
}

struct PendingReservation {
    let office: OfficeModel
    // AI-FEATURE (disabled): suggested category / type from FindTransactionIntent
    // var categoryCode: String? = nil
    // var typeCode: String? = nil
}

/// Attach inside `RouterView` so it has access to the router.
/// `@Published` replays its current value on subscribe, so this also works on a cold launch.
struct IntentRoutingModifier: ViewModifier {
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    private let intentRouter = IntentRouter.shared

    func body(content: Content) -> some View {
        content
            .onReceive(intentRouter.$pendingReservation.compactMap { $0 }) { pending in
                Logger.info("Intent: opening reservation form for \(pending.office.orgUnitName)")
                // @Published emits in willSet, so clear it on the next run loop, not inside the emission.
                DispatchQueue.main.async {
                    intentRouter.pendingReservation = nil
                }
                router.showScreen(.push) { _ in
                    ReservationFormView(appManager: appManager, office: pending.office)
                    // AI-FEATURE (disabled):
                    // ReservationFormView(appManager: appManager,
                    //                     office: pending.office,
                    //                     suggestedCategoryCode: pending.categoryCode,
                    //                     suggestedTypeCode: pending.typeCode)
                }
            }
    }
}
