//
//  WantProcurationShortcuts.swift
//  WantProcuration
//
//  Registers the Siri phrases. Arabic phrases live in AppShortcuts.xcstrings.
//

import AppIntents

nonisolated struct WantProcurationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BookNearestOfficeIntent(),
            phrases: [
                "Book at the nearest office in \(.applicationName)",
                "Book an appointment at the nearest office with \(.applicationName)",
                "Find the nearest office in \(.applicationName)"
            ],
            shortTitle: "الحجز في أقرب مكتب",
            systemImageName: "calendar.badge.plus"
        )
        /* AI-FEATURE (disabled)
        AppShortcut(
            intent: FindTransactionIntent(),
            phrases: [
                "I want to make a power of attorney in \(.applicationName)",
                "Which power of attorney do I need in \(.applicationName)",
                "Find my transaction type in \(.applicationName)"
            ],
            shortTitle: "اعرف نوع التوكيل",
            systemImageName: "sparkles"
        )
        */
        AppShortcut(
            intent: MyReservationIntent(),
            phrases: [
                "When is my reservation in \(.applicationName)",
                "What is my appointment in \(.applicationName)",
                "Check my reservation in \(.applicationName)"
            ],
            shortTitle: "موعد حجزي",
            systemImageName: "magnifyingglass.circle.fill"
        )
    }
}
