//
//  GatewayClient.swift
//  WantProcuration
//
//  HTTP client for the AI Gateway (IOS_PORT_GUIDE.md §1.1, §2).
//  - Base URL and optional token come from Info.plist (AIGatewayURL / AIGatewayToken),
//    which read the build settings AI_GATEWAY_URL / AI_GATEWAY_TOKEN.
//  - The national ID is NEVER sent here.
//

import Foundation

enum GatewayConfig {
    /// UserDefaults key of the link a tester set in Settings (§4.11). It wins over the build link.
    static let overrideKey = "ai_gateway.url"

    /// The link from the build (xcconfig / build setting AI_GATEWAY_URL → Info.plist "AIGatewayURL").
    static var defaultURL: String {
        var value = (Bundle.main.object(forInfoDictionaryKey: "AIGatewayURL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") { value.removeLast() }
        return value
    }

    /// The link a tester saved in Settings, if any.
    static var overrideURL: String? {
        let value = UserDefaults.standard.string(forKey: overrideKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    /// Read on every request, so a change in Settings applies from the next message.
    static var baseURL: String { overrideURL ?? defaultURL }

    static var isUsingDefault: Bool { overrideURL == nil }

    static func saveOverride(_ url: String) {
        UserDefaults.standard.set(url, forKey: overrideKey)
    }

    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: overrideKey)
    }

    /// Adds "https://" when there is no scheme, removes trailing "/", rejects anything that is not http(s).
    /// Returns nil for an invalid link.
    static func normalize(_ input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if !value.contains("://") { value = "https://" + value }
        while value.hasSuffix("/") { value.removeLast() }
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return value
    }

    static var token: String {
        (Bundle.main.object(forInfoDictionaryKey: "AIGatewayToken") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// "ar" or "en", following the app language.
    static var lang: String {
        UserDefaults.standard.string(forKey: "selectedLanguage") == "en" ? "en" : "ar"
    }
}

enum GatewayError: Error {
    case notConfigured
    case badStatus(Int)
    case invalidResponse
    /// HTTP 429 "too-fast": `reply` is a ready message to show as an assistant bubble; resend after `retryAfter` s.
    case rateLimited(reply: String, retryAfter: Int)
}

/// Body of HTTP 429: {"error":"too-fast","reply":"...","retryAfter":2}
private struct RateLimitBody: Decodable {
    var reply: String
    var retryAfter: Int

    enum CodingKeys: String, CodingKey { case reply, retryAfter }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reply = c.lenient(.reply, "")
        if let seconds = try? c.decodeIfPresent(Int.self, forKey: .retryAfter) {
            retryAfter = seconds
        } else if let seconds = try? c.decodeIfPresent(Double.self, forKey: .retryAfter) {
            retryAfter = Int(seconds.rounded(.up))
        } else {
            retryAfter = 2
        }
    }
}

final class GatewayClient {
    static let shared = GatewayClient()

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 200
        session = URLSession(configuration: config)
    }

    // MARK: Endpoints

    /// POST /chat — timeout 180 s (the local model can be slow).
    func chat(_ body: ChatRequest) async throws -> ChatResponse {
        // Device id (+ optional signature) so the gateway can keep a fair daily share per device (§4.10).
        let data = try await send(path: "/chat", method: "POST", body: try encoder.encode(body), timeout: 180,
                                  extraHeaders: DeviceIdentity.gatewayHeaders())
        return try decode(ChatResponse.self, from: data)
    }

    /// GET /suggestions?lang=
    func suggestions(lang: String) async throws -> [GatewayOption] {
        let data = try await send(path: "/suggestions?lang=\(lang)", method: "GET", body: nil, timeout: 30)
        return try decode(SuggestionsResponse.self, from: data).suggestions
    }

    /// DELETE /chat/{sessionId} — errors are ignored.
    func endSession(_ sessionId: String) async {
        _ = try? await send(path: "/chat/\(sessionId)", method: "DELETE", body: nil, timeout: 15)
    }

    /// POST /feedback — fire-and-forget, errors are ignored.
    func sendFeedback(_ feedback: FeedbackRequest) {
        guard let body = try? encoder.encode(feedback) else { return }
        Task {
            _ = try? await send(path: "/feedback", method: "POST", body: body, timeout: 15)
        }
    }

    /// POST /offices/recommend — timeout 60 s.
    func recommendOffices(_ body: RecommendRequest) async throws -> RecommendResponse {
        let data = try await send(path: "/offices/recommend", method: "POST", body: try encoder.encode(body), timeout: 60)
        return try decode(RecommendResponse.self, from: data)
    }

    /// POST /offices/alternatives — timeout 30 s.
    func alternativeOffices(_ body: AlternativesRequest) async throws -> AlternativesResponse {
        let data = try await send(path: "/offices/alternatives", method: "POST", body: try encoder.encode(body), timeout: 30)
        return try decode(AlternativesResponse.self, from: data)
    }

    /// GET /checklist/{cat}/{type}?lang=
    func checklist(categoryCode: String, typeCode: String, lang: String) async throws -> ChecklistResponse {
        let cat = categoryCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? categoryCode
        let type = typeCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? typeCode
        let data = try await send(path: "/checklist/\(cat)/\(type)?lang=\(lang)", method: "GET", body: nil, timeout: 30)
        return try decode(ChecklistResponse.self, from: data)
    }

    /// POST /share
    func share(_ body: ShareRequest) async throws -> ShareResponse {
        let data = try await send(path: "/share", method: "POST", body: try encoder.encode(body), timeout: 30)
        return try decode(ShareResponse.self, from: data)
    }

    /// GET <url>/health — true when it answers with a JSON object that contains "profile" (§4.11).
    func checkHealth(of url: String) async -> Bool {
        guard let target = URL(string: url + "/health") else { return false }
        var request = URLRequest(url: target, timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let token = GatewayConfig.token
        if !token.isEmpty { request.setValue(token, forHTTPHeaderField: "X-Gateway-Token") }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
            return object["profile"] != nil
        } catch {
            Logger.warning("Gateway health check failed for \(url): \(error)")
            return false
        }
    }

    // MARK: Plumbing

    private func send(path: String, method: String, body: Data?, timeout: TimeInterval,
                      extraHeaders: [String: String] = [:]) async throws -> Data {
        let base = GatewayConfig.baseURL
        guard !base.isEmpty, let url = URL(string: base + path) else { throw GatewayError.notConfigured }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let token = GatewayConfig.token
        if !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "X-Gateway-Token")
        }
        for (name, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }

        Logger.debug("Gateway \(method) \(path)")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GatewayError.invalidResponse }
        if http.statusCode == 429 {
            let body = try? decoder.decode(RateLimitBody.self, from: data)
            Logger.warning("Gateway \(path) HTTP 429 (retry after \(body?.retryAfter ?? 2) s)")
            throw GatewayError.rateLimited(reply: body?.reply ?? "", retryAfter: max(1, body?.retryAfter ?? 2))
        }
        guard (200...299).contains(http.statusCode) else {
            Logger.error("Gateway \(path) HTTP \(http.statusCode)")
            throw GatewayError.badStatus(http.statusCode)
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.error("Gateway decode \(T.self) failed: \(error)")
            throw GatewayError.invalidResponse
        }
    }
}
