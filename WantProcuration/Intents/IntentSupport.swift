//
//  IntentSupport.swift
//  WantProcuration
//
//  Helpers shared by the App Intents: errors, one-shot location, nearest office, national ID.
//

import Foundation
import AppIntents
internal import CoreLocation

// MARK: - Errors shown by Siri

nonisolated enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case locationDenied
    case locationUnavailable
    case noOffices
    /// No connection / timeout / server 5xx. `detail` is shown only in Debug builds.
    case network(String)
    /// The server answered but the response could not be read (status code or JSON shape).
    case badResponse(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .locationDenied:
            return "تعذّر الوصول إلى موقعك. يُرجى السماح للتطبيق باستخدام الموقع من الإعدادات."
        case .locationUnavailable:
            return "تعذّر تحديد موقعك حاليًا. يُرجى المحاولة مرة أخرى لاحقًا."
        case .noOffices:
            return "لا توجد مكاتب توثيق متاحة حاليًا."
        case .network(let detail):
            return "حدث خطأ في الاتصال. يُرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى.\(Self.debugSuffix(detail))"
        case .badResponse(let detail):
            return "تعذّرت قراءة الرد من الخادم. يُرجى المحاولة مرة أخرى لاحقًا.\(Self.debugSuffix(detail))"
        }
    }

    /// Maps any error from `APIClient` to a message Siri can say.
    @MainActor
    static func from(_ error: Error) -> IntentError {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidResponse, .dataError, .notFound, .unauthorized:
                return .badResponse(String(describing: apiError))
            default:
                return .network(String(describing: apiError))
            }
        }
        if error is DecodingError {
            return .badResponse(String(describing: error))
        }
        return .network(String(describing: error))
    }

    private static func debugSuffix(_ detail: String) -> String {
        #if DEBUG
        return "\n[Debug] \(detail)"
        #else
        return ""
        #endif
    }
}

// MARK: - One-shot location

/// Requests the current location once. Same delegate pattern as `LocationManager`.
final class OneShotLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    func currentLocation() async throws -> CLLocation {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            handleAuthorization(manager.authorizationStatus)
        }
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            finish(.failure(IntentError.locationDenied))
        }
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil, manager.authorizationStatus != .notDetermined else { return }
        handleAuthorization(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            finish(.success(location))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            finish(.failure(IntentError.locationDenied))
        } else {
            finish(.failure(IntentError.locationUnavailable))
        }
    }
}

// MARK: - Nearest office

enum NearestOfficeFinder {
    /// Nearest regular office (premium offices are skipped because they show a notice before booking).
    static func find(from location: CLLocation) async throws -> OfficeModel {
        let offices: [OfficeModel]
        do {
            offices = try await APIClient.shared.getOffices()
        } catch {
            Logger.error("Intent: failed to fetch offices: \(error)")
            throw IntentError.from(error)
        }

        let candidates: [OfficeModel] = offices
            .filter { !$0.isSpecial && $0.hasCoordinates }
            .map { office in
                var updated = office
                let officeLocation = CLLocation(latitude: office.coordinate.latitude,
                                                longitude: office.coordinate.longitude)
                updated.distance = location.distance(from: officeLocation) / 1000.0
                return updated
            }

        Logger.info("Intent: \(offices.count) offices, \(candidates.count) candidates")
        guard let nearest = candidates.min(by: { $0.distance < $1.distance }) else {
            throw IntentError.noOffices
        }
        return nearest
    }
}

// MARK: - National ID

enum NationalIdNormalizer {
    /// Converts Arabic-Indic / Persian digits (from dictation) to ASCII and drops anything else.
    static func normalize(_ input: String) -> String {
        let map: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"
        ]
        return String(input.compactMap { char -> Character? in
            if let mapped = map[char] { return mapped }
            return char.isASCII && char.isNumber ? char : nil
        })
    }
}
