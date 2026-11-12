// AI-FEATURE (disabled): describe-transaction feature, commented out on request. Search "AI-FEATURE" to delete or restore.
/*
//
//  TransactionDebugTools.swift
//  WantProcuration
//
//  DEBUG ONLY. Two helpers for testing the "describe → transaction" feature:
//   1. exportCatalog: prints every category + type of an office as JSON, so it can be shared and reviewed.
//   2. runTestSuite: runs the same meaning written in Egyptian dialect, Modern Standard Arabic and English,
//      and prints what the matcher picked for each.
//  Nothing here is compiled into Release builds.
//

#if DEBUG
import Foundation

enum TransactionDebugTools {

    struct CatalogCategory: Codable {
        let code: String
        let name: String
        let types: [CatalogType]
    }
    struct CatalogType: Codable {
        let code: String
        let name: String
    }

    /// Loads all categories and their types once (one request per category).
    static func loadCatalog(office: OfficeModel) async throws -> [(TransactionCategory, [TransactionType])] {
        let categories = try await APIClient.shared.getTransactionCategories(selectedOffice: office)
        var result: [(TransactionCategory, [TransactionType])] = []
        for category in categories {
            let types = (try? await APIClient.shared.getTransactionTypes(selectedOffice: office, selectedCategory: category)) ?? []
            result.append((category, types))
        }
        return result
    }

    /// Prints the office catalog as JSON between two marker lines. Copy everything between them.
    static func exportCatalog(office: OfficeModel) async {
        do {
            let catalog = try await loadCatalog(office: office)
            let export = catalog.map { category, types in
                CatalogCategory(code: category.code ?? "", name: category.desc ?? "",
                                types: types.map { CatalogType(code: $0.code ?? "", name: $0.desc ?? "") })
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let json = String(data: try encoder.encode(export), encoding: .utf8) ?? "[]"
            print("===== CATALOG START office=\(office.orgUnitID) \(office.orgUnitName) =====")
            print(json)
            print("===== CATALOG END (\(export.count) categories, \(export.reduce(0) { $0 + $1.types.count }) types) =====")
        } catch {
            print("CATALOG ERROR: \(error)")
        }
    }

    /// Same meaning in three styles + two sentences where the right answer is "no match".
    static let testSentences: [(id: String, style: String, text: String)] = [
        ("1", "عامية", "توكيل لأخويا عشان يبيع العربية"),
        ("1", "فصحى", "أريد توكيلًا لأخي لبيع السيارة"),
        ("1", "English", "power of attorney for my brother to sell my car"),
        ("2", "عامية", "عايزة أبيع شقتي"),
        ("2", "فصحى", "أرغب في بيع شقتي"),
        ("2", "English", "I want to sell my apartment"),
        ("3", "عامية", "توكيل لمحامي عشان القضية"),
        ("3", "فصحى", "توكيل لمحامٍ في قضية"),
        ("3", "English", "power of attorney for a lawyer in a court case"),
        ("4", "عامية", "توكيل عام لجوزي"),
        ("4", "فصحى", "توكيل عام لزوجي"),
        ("4", "English", "general power of attorney for my husband"),
        ("5", "عامية", "عايز حد يشتريلي عربية"),
        ("5", "فصحى", "توكيل لشراء سيارة"),
        ("5", "English", "buy a car for me"),
        ("6", "عامية", "توكيل لابني يقبض المعاش"),
        ("6", "فصحى", "توكيل لابني لصرف المعاش"),
        ("6", "English", "collect my pension"),
        ("7", "عامية", "عايز ألغي توكيل قديم"),
        ("7", "فصحى", "إلغاء توكيل سابق"),
        ("7", "English", "cancel an old power of attorney"),
        ("8", "ناقص", "عايز أعمل توكيل"),
        ("9", "مش متعلق", "عايز أحجز تذكرة طيارة")
    ]

    /// Runs all test sentences against one office and prints one line per sentence.
    static func runTestSuite(office: OfficeModel) async {
        let catalog: [(TransactionCategory, [TransactionType])]
        do {
            catalog = try await loadCatalog(office: office)
        } catch {
            print("TEST ERROR: \(error)")
            return
        }
        let categories = catalog.map { $0.0 }
        print("===== TEST START office=\(office.orgUnitID) \(office.orgUnitName) =====")
        print("Arabic sentence embedding: \(SemanticModel.arabic == nil ? "NOT available" : "available")")
        for sentence in testSentences {
            let suggestion = await TransactionMatcher.suggest(
                description: sentence.text,
                categories: categories,
                loadTypes: { category in
                    catalog.first(where: { $0.0.code == category.code })?.1 ?? []
                }
            )
            let picked = suggestion.map { "\($0.category.desc ?? "") › \($0.type?.desc ?? "-")" } ?? "لا يوجد اختيار"
            let confidence = suggestion.map { String(format: "%.2f", $0.confidence) } ?? "-"
            print("TEST | \(sentence.id) | \(sentence.style) | \(sentence.text) | → \(picked) | \(confidence)")
        }
        print("===== TEST END =====")
    }
}
#endif
*/
