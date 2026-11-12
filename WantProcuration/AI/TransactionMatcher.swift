// AI-FEATURE (disabled): describe-transaction feature, commented out on request. Search "AI-FEATURE" to delete or restore.
/*
//
//  TransactionMatcher.swift
//  WantProcuration
//
//  Picks the transaction category + type that best fits a free-text description
//  ("عايز أعمل توكيل لأخويا يبيع العربية"). Runs fully on the device, no backend.
//
//  How it works (step 1 of the plan):
//   1. Arabic text cleanup: removes diacritics, unifies أ/إ/آ→ا, ة→ه, ى→ي, drops "ال" etc.
//   2. Dialect words are mapped to one form (عربية/عربيتي/سيارة → سياره, يبيع/أبيع → بيع ...).
//   3. All types of the office are scored: matching words count more when they are rare
//      in the list (so "توكيل", which appears everywhere, counts less than "سياره").
//      A description made only of general words ("عايز أعمل توكيل") gets no suggestion.
//   4. If iOS has an Arabic sentence-embedding model (NLEmbedding), its "meaning" similarity
//      is blended in. This is not Apple Intelligence; it is part of the NaturalLanguage framework.
//  It only ranks names that came from the server, so it never invents a transaction type.
//

import Foundation
import NaturalLanguage

struct TransactionSuggestion {
    let category: TransactionCategory
    let type: TransactionType?
    /// 0...1, rough. Shown to the user as a suggestion either way; they confirm in the form.
    let confidence: Double
}

enum TransactionMatcher {

    /// - Parameters:
    ///   - description: what the user said / typed.
    ///   - categories: categories of the selected office (from the API).
    ///   - loadTypes: fetches the types of one category (from the API).
    static func suggest(
        description: String,
        categories: [TransactionCategory],
        loadTypes: (TransactionCategory) async throws -> [TransactionType]
    ) async -> TransactionSuggestion? {
        let validCategories = categories.filter { !($0.desc ?? "").isEmpty }
        guard !validCategories.isEmpty, !ArabicText.tokens(description).isEmpty else { return nil }

        // 1) Load the types of every category. Category names ("محاضر التصديق على التوقيعات")
        //    say nothing about the request, so we search all of them (max 10 categories).
        var candidates: [(category: TransactionCategory, type: TransactionType)] = []
        for category in validCategories.prefix(10) {
            do {
                for type in try await loadTypes(category) where !(type.desc ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
                    candidates.append((category, type))
                }
            } catch {
                Logger.error("Matcher: failed to load types for \(category.desc ?? ""): \(error)")
            }
        }
        guard !candidates.isEmpty else { return nil }

        let scorer = TextScorer(candidates: candidates.map { $0.type.desc ?? "" })

        // 2) The description must contain at least one "deciding" word: a word that appears in
        //    some names but not in too many. "توكيل", "عقد", "بيع" alone can't pick a type.
        let informative = scorer.informativeWords(in: description)
        guard !informative.isEmpty else {
            Logger.info("Matcher: description too general: \"\(description)\"")
            return nil
        }

        // 3) Rank all types.
        let ranked = zip(candidates.indices, scorer.scores(for: description))
            .sorted { $0.1 > $1.1 }

        for (index, score) in ranked.prefix(3) {
            Logger.info("Matcher: \(String(format: "%.2f", score))  \(candidates[index].category.desc ?? "") › \(candidates[index].type.desc ?? "")")
        }

        guard let best = ranked.first,
              best.1 > 0.05,
              scorer.contains(anyOf: informative, candidateAt: best.0) else {
            Logger.info("Matcher: no confident match for \"\(description)\"")
            return nil
        }
        let bestIndex = best.0
        let bestScore = best.1
        let second = ranked.dropFirst().first?.1 ?? 0
        // Confidence drops when the top two are close.
        let margin = (bestScore - second) / bestScore
        let confidence = min(1, bestScore) * (0.5 + 0.5 * margin)

        return TransactionSuggestion(category: candidates[bestIndex].category,
                                     type: candidates[bestIndex].type,
                                     confidence: confidence)
    }
}

// MARK: - Scoring

/// Scores a query against a fixed list of names. Returns one score (0...1) per candidate.
struct TextScorer {
    private let candidateTokens: [[String]]
    private let candidates: [String]
    private let idf: [String: Double]

    init(candidates: [String]) {
        self.candidates = candidates
        self.candidateTokens = candidates.map { Array(Set(ArabicText.tokens($0))) }
        var documentFrequency: [String: Int] = [:]
        for tokens in candidateTokens {
            for token in tokens { documentFrequency[token, default: 0] += 1 }
        }
        let count = Double(max(candidates.count, 1))
        self.idf = documentFrequency.mapValues { log(1 + count / Double($0)) }
    }

    /// A word in more than this share of the names (توكيل, عقد, بيع, اقرار ...) can't decide alone.
    static let genericShare = 0.10

    /// Query words that appear in at least one name but in no more than `genericShare` of them.
    func informativeWords(in query: String) -> [String] {
        let count = Double(max(candidates.count, 1))
        return Array(Set(ArabicText.tokens(query))).filter { word in
            let frequency = candidateTokens.filter { tokens in
                tokens.contains { ArabicText.similarity(word, $0) >= 0.8 }
            }.count
            return frequency > 0 && Double(frequency) / count <= TextScorer.genericShare
        }
    }

    /// True if the candidate's name contains one of the given words.
    func contains(anyOf words: [String], candidateAt index: Int) -> Bool {
        candidateTokens[index].contains { token in
            words.contains { ArabicText.similarity($0, token) >= 0.8 }
        }
    }

    func scores(for query: String) -> [Double] {
        let queryTokens = Array(Set(ArabicText.tokens(query)))
        guard !queryTokens.isEmpty, !candidates.isEmpty else { return candidates.map { _ in 0 } }

        // Word overlap, weighted by how rare the word is in the list.
        let keyword: [Double] = candidateTokens.map { tokens in
            guard !tokens.isEmpty else { return 0 }
            let total = tokens.reduce(0) { $0 + (idf[$1] ?? 0) }
            guard total > 0 else { return 0 }
            let matched = tokens.reduce(0.0) { sum, token in
                let best = queryTokens.map { ArabicText.similarity($0, token) }.max() ?? 0
                return sum + best * (idf[token] ?? 0)
            }
            return matched / total
        }

        // Meaning similarity, only if iOS ships an Arabic sentence embedding.
        guard let embedding = SemanticModel.arabic else { return keyword }
        let cleanQuery = ArabicText.normalize(query)
        let semantic: [Double] = candidates.map { name in
            let distance = embedding.distance(between: cleanQuery, and: ArabicText.normalize(name))
            return max(0, 1 - distance / 2)   // cosine distance 0...2 → similarity 1...0
        }
        return zip(keyword, semantic).map { 0.7 * $0 + 0.3 * $1 }
    }
}

enum SemanticModel {
    /// nil when the device/iOS has no Arabic sentence embedding.
    static let arabic: NLEmbedding? = {
        let model = NLEmbedding.sentenceEmbedding(for: .arabic)
        Logger.info("Matcher: Arabic sentence embedding \(model == nil ? "NOT available" : "available")")
        return model
    }()
}

// MARK: - Arabic text helpers

enum ArabicText {

    /// Words with no meaning for matching.
    private static let stopWords: Set<String> = [
        "انا", "عايز", "عايزه", "عاوز", "عاوزه", "محتاج", "محتاجه", "اريد", "ارغب", "نفسي",
        "اعمل", "اعملي", "عمل", "نعمل", "يعمل", "اطلع", "ابغي",
        "في", "من", "علي", "الي", "عن", "مع", "او", "و", "ل", "ب", "ده", "دي", "دا",
        "عشان", "علشان", "لكي", "حتي", "كده", "بس", "اللي", "الذي", "التي", "هو", "هي",
        "لو", "سمحت", "ممكن", "بالظبط", "فعلا", "ايوه", "يعني"
    ]

    /// Dialect / spelling variants mapped to one form. First item is the canonical word.
    private static let synonymGroups: [[String]] = [
        ["سياره", "عربيه", "عربيتي", "سيارتي", "عربات", "سيارات", "مركبه", "مركبات", "عربيات", "عربيتها"],
        ["بيع", "يبيع", "ابيع", "هبيع", "تبيع", "يبيعها", "بيعها", "ببيع"],
        ["شراء", "يشتري", "اشتري", "شرا", "تشتري", "هشتري", "يشتريلي"],
        // Note: شقة/بيت are NOT mapped to عقار, because names use "عقاري" for mortgage / funding.
        ["عقار", "عقارات"],
        ["قضايا", "قضيه", "محامي", "محام", "محاماه", "محكمه", "محاكم"],
        ["زواج", "جواز", "اتجوز", "زوجيه"],
        ["طلاق", "اطلق"],
        ["ورثه", "ميراث", "ورث", "وراثه", "تركه"],
        ["بنك", "بنوك", "مصرف", "حساب"],
        ["شركه", "شركات"],
        ["ترخيص", "رخصه", "تراخيص", "مرور"],
        ["اداره", "يدير", "ادير"],
        ["قبض", "يقبض", "استلام", "يستلم", "صرف", "يصرف"],
        ["معاش", "معاشات", "تامينات"],
        // Note: فسخ is NOT here, because names use "فسخ عقد" for contracts, not for a POA.
        ["الغاء", "الغي", "يلغي", "الغاءه"]
    ] + englishGroups

    /// Basic English words mapped to the same canonical Arabic words (keyword level only).
    private static let englishGroups: [[String]] = [
        ["توكيل", "attorney", "proxy", "poa"],
        ["سياره", "car", "cars", "vehicle"],
        ["بيع", "sell", "selling", "sale"],
        ["شراء", "buy", "buying", "purchase"],
        ["عقار", "apartment", "flat", "house", "land", "property"],
        ["قضايا", "lawyer", "court", "case", "lawsuit"],
        ["عام", "general"],
        ["الغاء", "cancel", "revoke"],
        ["معاش", "pension"],
        ["قبض", "collect", "receive"],
        ["شركه", "company"],
        ["زواج", "marriage"],
        ["طلاق", "divorce"],
        ["ورثه", "inheritance"],
        ["بنك", "bank"]
    ]

    private static let canonical: [String: String] = {
        var map: [String: String] = [:]
        for group in synonymGroups {
            guard let first = group.first else { continue }
            for word in group { map[word] = first }
        }
        return map
    }()

    /// Unifies letters and removes diacritics / tatweel / punctuation.
    static func normalize(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x064B...0x065F, 0x0670, 0x0640:      // harakat, superscript alef, tatweel
                continue
            case 0x0623, 0x0625, 0x0622, 0x0671:        // أ إ آ ٱ → ا
                result.append("ا")
            case 0x0629: result.append("ه")              // ة → ه
            case 0x0649: result.append("ي")              // ى → ي
            case 0x0624: result.append("و")              // ؤ → و
            case 0x0626: result.append("ي")              // ئ → ي
            case 0x0660...0x0669:                        // Arabic-Indic digits
                result.append(Character(UnicodeScalar(scalar.value - 0x0660 + 0x30)!))
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        return result.lowercased()
    }

    /// Cleaned, dialect-unified words without stop words.
    static func tokens(_ text: String) -> [String] {
        normalize(text)
            .components(separatedBy: CharacterSet.letters.union(.decimalDigits).inverted)
            .map { canonical[$0] != nil ? $0 : stripPrefixes($0) }   // keep known words like "الغاء" intact
            .filter { $0.count >= 2 && !stopWords.contains($0) }
            .map(canonicalize)
    }

    /// Maps a dialect word to its canonical form; also tries without a one-letter prefix (لمحامي → محامي).
    private static func canonicalize(_ word: String) -> String {
        if let mapped = canonical[word] { return mapped }
        if let first = word.first, "لبوف".contains(first), word.count > 3,
           let mapped = canonical[String(word.dropFirst())] {
            return mapped
        }
        return word
    }

    /// والعربيه → عربيه, بالعربيه → عربيه, للبيع → بيع, العربيه → عربيه
    private static func stripPrefixes(_ word: String) -> String {
        var w = word
        for prefix in ["وال", "بال", "كال", "فال"] where w.hasPrefix(prefix) && w.count > prefix.count + 2 {
            return String(w.dropFirst(prefix.count))
        }
        if w.hasPrefix("لل") && w.count > 4 { w = String(w.dropFirst(2)); return w }
        if w.hasPrefix("ال") && w.count > 4 { w = String(w.dropFirst(2)) }
        return w
    }

    /// 1 for the same word, 0.8 when one starts with the other (e.g. "توكيل" / "توكيلات"), else 0.
    static func similarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        let shorter = a.count <= b.count ? a : b
        let longer = a.count <= b.count ? b : a
        if shorter.count >= 3 && longer.hasPrefix(shorter) { return 0.8 }
        return 0
    }
}
*/
