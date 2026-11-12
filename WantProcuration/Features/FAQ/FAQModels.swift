//
//  FAQModels.swift
//  WantProcuration
//
//  FAQ content (IOS_PORT_GUIDE.md §4.2, Appendix A). Loaded from the bundled faq.json;
//  the same shape is expected if it moves to the server later.
//

import Foundation

struct FAQFile: Decodable {
    var version: Int
    var items: [FAQItem]

    enum CodingKeys: String, CodingKey { case version, items }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = c.lenient(.version, 1)
        items = c.lenient(.items, [])
    }
}

struct FAQItem: Decodable, Identifiable, Hashable {
    var id: String
    var order: Int
    var questionAr: String
    var answerAr: String
    var questionEn: String
    var answerEn: String
    var actionRoute: String?

    enum CodingKeys: String, CodingKey { case id, order, questionAr, answerAr, questionEn, answerEn, actionRoute }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(.id, UUID().uuidString)
        order = c.lenient(.order, 0)
        questionAr = c.lenient(.questionAr, "")
        answerAr = c.lenient(.answerAr, "")
        questionEn = c.lenient(.questionEn, "")
        answerEn = c.lenient(.answerEn, "")
        actionRoute = c.lenient(.actionRoute, nil as String?)
    }

    /// Question in the app language; English falls back to Arabic when empty.
    func question(lang: String) -> String { lang == "en" && !questionEn.isEmpty ? questionEn : questionAr }
    func answer(lang: String) -> String { lang == "en" && !answerEn.isEmpty ? answerEn : answerAr }
}
