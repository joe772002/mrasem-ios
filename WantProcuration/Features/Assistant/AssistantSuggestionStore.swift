//
//  AssistantSuggestionStore.swift
//  WantProcuration
//
//  Holds the transaction the assistant suggested, so the normal booking form can pre-select
//  the category and type (IOS_PORT_GUIDE.md §4.8 A). Contains no personal data.
//

import Foundation
import Combine

final class AssistantSuggestionStore: ObservableObject {
    static let shared = AssistantSuggestionStore()

    @Published var service: GatewayService?

    private init() {}
}
