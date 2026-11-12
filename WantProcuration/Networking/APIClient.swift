//
//  APIClient.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//



import Foundation
import UIKit

// MARK: - API Client
class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.baseURL = AppConfiguration.environment.baseURL
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .useDefaultKeys
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .useDefaultKeys
    }
    
    
    // MARK: - Generic Request Methods
    
    internal func get<T: Decodable>(_ endpoint: String, requiresAuth: Bool = false) async throws -> T {
        let request = try createRequest(endpoint, method: "GET", requiresAuth: requiresAuth)
        return try await performRequest(request)
    }
    
    internal func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U, requiresAuth: Bool = false) async throws -> T {
        var request = try createRequest(endpoint, method: "POST", requiresAuth: requiresAuth)
        let jsonData = try encoder.encode(body)
        // Only the endpoint: the body holds the national ID and printing it slowed the Xcode console.
        Logger.debug("POST \(endpoint) (\(jsonData.count) bytes)")
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await performRequest(request)
    }
    
    internal func post<T: Decodable>(_ endpoint: String, body: [String: Any], requiresAuth: Bool = false) async throws -> T {
        var request = try createRequest(endpoint, method: "POST", requiresAuth: requiresAuth)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await performRequest(request)
    }
    
    internal func put<T: Decodable, U: Encodable>(_ endpoint: String, body: U, requiresAuth: Bool = false) async throws -> T {
        var request = try createRequest(endpoint, method: "PUT", requiresAuth: requiresAuth)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await performRequest(request)
    }
    
    internal func delete(_ endpoint: String, requiresAuth: Bool = false) async throws {
        let request = try createRequest(endpoint, method: "DELETE", requiresAuth: requiresAuth)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    internal func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.error("Failed to decode response: \(error)")
            Logger.debug("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
            throw APIError.invalidResponse
        }
    }
    
    internal func createRequest(_ endpoint: String, method: String, requiresAuth: Bool) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidResponse
        }
        Logger.debug("url is \(url)")   // Debug builds only (the URL can contain the national ID)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("iOS/\(UIDevice.current.systemVersion)", forHTTPHeaderField: "User-Agent")
        
        if requiresAuth {
            // TODO: get token from storage
//            guard let token = SecureStorageManager().retrieve(key: "auth_token") else {
//                throw APIError.unauthorized
//            }
//            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    internal func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 408:
            throw APIError.timeout
        case 500...599:
            throw APIError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw APIError.invalidResponse
        }
    }
}
// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case authenticationFailed
    case submissionFailed
    case networkError
    case invalidResponse
    case serverError(String)
    case unauthorized
    case notFound
    case timeout
    case dataError
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .submissionFailed:
            return "Failed to submit application. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized access. Please log in again."
        case .notFound:
            return "Resource not found."
        case .timeout:
            return "Request timeout. Please try again."
        case .dataError:
            return "Data error."
        }
    }
}

// MARK: - App Configuration
enum AppConfiguration {
    static var environment: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://ms.tawseek.gov.eg/CityStar/AOAS_RestServiceMobile_v2/api/"
            case .staging:
                return "https://ms.tawseek.gov.eg/CityStar/AOAS_RestServiceMobile_v2/api/"
            case .production:
                return "https://ms.tawseek.gov.eg/CityStar/AOAS_RestServiceMobile_v2/api/"
            }
        }
        
        var isDebugMode: Bool {
            switch self {
            case .development, .staging:
                return true
            case .production:
                return false
            }
        }
        
        var certificatePins: [String] {
            switch self {
            case .development:
                return ["sha256/devCertHash"]
            case .staging:
                return ["sha256/stagingCertHash"]
            case .production:
                return ["sha256/prodCertHash1", "sha256/prodCertHash2"]
            }
        }
    }
}


// MARK: - Application APIs
// Example POST Parameters
//    func submitVesselRegistration(_ registration: VesselRegistration) async throws -> VesselRegistration {
//        let endpoint = "/api/v1/applications/vessel-registration"
//
//        Logger.info("Submitting vessel registration: \(registration.id)")
//
//        let result: VesselRegistration = try await post(endpoint, body: registration, requiresAuth: true)
//
//        Logger.info("Vessel registration submitted successfully: \(result.applicationNumber)")
//
//        return result
//    }


// Example get

//    func getApplication(id: String) async throws -> VesselRegistration {
//        let endpoint = "/api/v1/applications/\(id)"
//        return try await get(endpoint, requiresAuth: true)
//    }


// MARK: - Document APIs

// Example Multipart Post
//    func uploadDocument(_ document: Data, fileName: String, mimeType: String) async throws -> ApplicationDocument {
//        let endpoint = "/api/v1/documents/upload"
//
//        let boundary = UUID().uuidString
//        var request = try createRequest(endpoint, method: "POST", requiresAuth: true)
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        var body = Data()
//
//        // Add file data
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
//        body.append(document)
//        body.append("\r\n".data(using: .utf8)!)
//
//        // End boundary
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//
//        request.httpBody = body
//
//        let (data, response) = try await session.data(for: request)
//        try validateResponse(response)
//
//        return try decoder.decode(ApplicationDocument.self, from: data)
//    }

