//
//  FAQViewModel.swift
//  WantProcuration
//

import Foundation
import Combine

final class FAQViewModel: ObservableObject {
    enum LoadState { case loading, loaded, failed }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var items: [FAQItem] = []
    @Published var searchText = ""
    /// Only one answer is open at a time.
    @Published var expandedId: String?

    let lang = GatewayConfig.lang

    /// Every word of the search must appear in the question or the answer (after normalization).
    var filteredItems: [FAQItem] {
        let words = ArabicSearchNormalizer.normalize(searchText)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard !words.isEmpty else { return items }
        return items.filter { item in
            let haystack = ArabicSearchNormalizer.normalize(item.question(lang: lang) + " " + item.answer(lang: lang))
            return words.allSatisfy { haystack.contains($0) }
        }
    }

    func load() {
        state = .loading
        guard let url = Bundle.main.url(forResource: "faq", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FAQFile.self, from: data) else {
            Logger.error("FAQ: could not load faq.json")
            state = .failed
            return
        }
        items = file.items.sorted { $0.order < $1.order }
        state = .loaded
    }

    func toggle(_ item: FAQItem) {
        expandedId = (expandedId == item.id) ? nil : item.id
    }
}
