//
//  GatewayModels.swift
//  WantProcuration
//
//  Models for the AI Gateway (IOS_PORT_GUIDE.md §2). Every field has a default and unknown keys are
//  ignored, because the gateway adds fields over time. A field with an unexpected type also falls back
//  to its default instead of failing the whole response.
//

import Foundation

// MARK: - Lenient decoding helper

extension KeyedDecodingContainer {
    /// Decodes the key if present and of the right type, otherwise returns `defaultValue`.
    func lenient<T: Decodable>(_ key: Key, _ defaultValue: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? defaultValue
    }
}

// MARK: - Service / documents / options

struct GatewayService: Codable, Hashable {
    var id: String
    var nameAr: String
    var nameEn: String
    var descriptionAr: String
    var categoryCode: String
    var categoryDesc: String
    var typeCode: String
    var typeDesc: String
    var classificationKeywords: [String]
    var typeKeywords: [String]
    var documentsAreGeneric: Bool

    enum CodingKeys: String, CodingKey {
        case id, nameAr, nameEn, descriptionAr, categoryCode, categoryDesc, typeCode, typeDesc
        case classificationKeywords, typeKeywords, documentsAreGeneric
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.lenient(.id, "")
        nameAr = c.lenient(.nameAr, "")
        nameEn = c.lenient(.nameEn, "")
        descriptionAr = c.lenient(.descriptionAr, "")
        categoryCode = c.lenient(.categoryCode, "")
        categoryDesc = c.lenient(.categoryDesc, "")
        typeCode = c.lenient(.typeCode, "")
        typeDesc = c.lenient(.typeDesc, "")
        classificationKeywords = c.lenient(.classificationKeywords, [])
        typeKeywords = c.lenient(.typeKeywords, [])
        documentsAreGeneric = c.lenient(.documentsAreGeneric, false)
    }

    /// Name to show: Arabic name, then type description.
    var displayName: String {
        if !nameAr.isEmpty { return nameAr }
        return typeDesc
    }
}

struct GatewayDocument: Codable, Hashable {
    var name: String
    var party: String
    var original: Bool

    enum CodingKeys: String, CodingKey { case name, party, original }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.lenient(.name, "")
        party = c.lenient(.party, "")
        original = c.lenient(.original, false)
    }
}

/// Used for clarifyOptions, suggestions and alternatives: a label, and either a resolved service or a text to send.
struct GatewayOption: Codable, Hashable {
    var label: String
    var text: String?
    var service: GatewayService?
    var documents: [GatewayDocument]

    enum CodingKeys: String, CodingKey { case label, text, service, documents }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(.label, "")
        text = c.lenient(.text, nil as String?)
        service = c.lenient(.service, nil as GatewayService?)
        documents = c.lenient(.documents, [])
        if label.isEmpty { label = text ?? service?.displayName ?? "" }
    }

    init(label: String, text: String? = nil, service: GatewayService? = nil, documents: [GatewayDocument] = []) {
        self.label = label
        self.text = text
        self.service = service
        self.documents = documents
    }
}

/// meta.quota — the device's fair share for today. When `limited` has a value, the reply came from the rules and
/// already explains it, so the app shows nothing extra (§4.10). Kept for the debug meta line only.
struct GatewayQuota: Codable, Hashable {
    var usedToday: Double
    var shareToday: Double
    var limited: String?

    enum CodingKeys: String, CodingKey { case usedToday, shareToday, limited }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        usedToday = c.lenient(.usedToday, 0)
        shareToday = c.lenient(.shareToday, 0)
        if let text = try? c.decodeIfPresent(String.self, forKey: .limited) {
            limited = text
        } else if let flag = try? c.decodeIfPresent(Bool.self, forKey: .limited) {
            limited = flag ? "true" : nil
        } else {
            limited = nil
        }
    }
}

struct GatewayMeta: Codable, Hashable {
    var provider: String
    var model: String
    var engine: String
    var path: String
    var note: String
    var error: String
    var latencyMs: Double
    var promptTokens: Double
    var completionTokens: Double
    var quota: GatewayQuota?

    enum CodingKeys: String, CodingKey {
        case provider, model, engine, path, note, error, latencyMs, promptTokens, completionTokens, quota
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        provider = c.lenient(.provider, "")
        model = c.lenient(.model, "")
        engine = c.lenient(.engine, "")
        path = c.lenient(.path, "")
        note = c.lenient(.note, "")
        error = c.lenient(.error, "")
        latencyMs = c.lenient(.latencyMs, 0)
        promptTokens = c.lenient(.promptTokens, 0)
        completionTokens = c.lenient(.completionTokens, 0)
        quota = c.lenient(.quota, nil as GatewayQuota?)
    }
}

// MARK: - /chat

struct ChatRequest: Encodable {
    let message: String
    let sessionId: String?
    let lang: String
    let choiceKey: String?
}

struct ChatResponse: Codable, Hashable {
    var status: String
    var reply: String
    /// The whole message written for the ear (§4.14); empty from older gateways.
    var speech: String
    var service: GatewayService?
    var documents: [GatewayDocument]
    var quickReplies: [String]
    var clarifyOptions: [GatewayOption]
    var alternatives: [GatewayOption]
    var confidence: Double
    var needsConfirmation: Bool
    var piiRemoved: Bool
    var meta: GatewayMeta?
    var sessionId: String?
    /// Steps for requests with more than one need (§4.13).
    var plan: GatewayPlan?

    enum CodingKeys: String, CodingKey {
        case status, reply, speech, service, documents, quickReplies, clarifyOptions, alternatives
        case confidence, needsConfirmation, piiRemoved, meta, sessionId, plan
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.lenient(.status, "error")
        reply = c.lenient(.reply, "")
        speech = c.lenient(.speech, "")
        service = c.lenient(.service, nil as GatewayService?)
        documents = c.lenient(.documents, [])
        quickReplies = c.lenient(.quickReplies, [])
        clarifyOptions = c.lenient(.clarifyOptions, [])
        // Alternatives may come as options or as bare services.
        if let options = try? c.decodeIfPresent([GatewayOption].self, forKey: .alternatives) {
            alternatives = options
        } else if let services = try? c.decodeIfPresent([GatewayService].self, forKey: .alternatives) {
            alternatives = services.map { GatewayOption(label: $0.displayName, service: $0) }
        } else {
            alternatives = []
        }
        confidence = c.lenient(.confidence, 0)
        needsConfirmation = c.lenient(.needsConfirmation, false)
        piiRemoved = c.lenient(.piiRemoved, false)
        meta = c.lenient(.meta, nil as GatewayMeta?)
        sessionId = c.lenient(.sessionId, nil as String?)
        plan = c.lenient(.plan, nil as GatewayPlan?)
    }

    /// A plain assistant message built in the app (e.g. the gateway's "too fast" reply on HTTP 429).
    init(plainReply: String) {
        status = "info"
        reply = plainReply
        speech = ""
        service = nil
        documents = []
        quickReplies = []
        clarifyOptions = []
        alternatives = []
        confidence = 0
        needsConfirmation = false
        piiRemoved = false
        meta = nil
        sessionId = nil
        plan = nil
    }

    /// A reply built in the app (no gateway call), used when the user picks a resolved suggestion.
    init(localReply: String, service: GatewayService, documents: [GatewayDocument]) {
        status = "matched"
        reply = localReply
        speech = ""
        self.service = service
        self.documents = documents
        quickReplies = []
        clarifyOptions = []
        alternatives = []
        confidence = 1
        needsConfirmation = true
        piiRemoved = false
        meta = nil
        sessionId = nil
        plan = nil
    }

    var isMatched: Bool { status == "matched" && service != nil }

    /// status "plan": only the first line of `reply` is shown, the steps come in the plan card (§4.13).
    var isPlan: Bool { status == "plan" && plan?.isPlan == true && plan?.isEmpty == false }

    /// A non-plan `plan` shown as «معلومة مهمة» under the normal reply.
    var infoPlan: GatewayPlan? {
        guard let plan, !plan.isPlan, !plan.isEmpty else { return nil }
        return plan
    }

    var firstReplyLine: String {
        reply.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init) ?? reply
    }
}

// MARK: - /suggestions, /feedback

struct SuggestionsResponse: Decodable {
    var suggestions: [GatewayOption]

    enum CodingKeys: String, CodingKey { case suggestions }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        suggestions = c.lenient(.suggestions, [])
    }
}

struct FeedbackRequest: Encodable {
    let sessionId: String
    let accepted: Bool
    let serviceId: String
    let chosenServiceId: String?
    /// nil = the type confirmation; "plan_step" = a plan step was booked (§4.13).
    var stage: String? = nil
}
