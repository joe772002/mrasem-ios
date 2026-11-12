//
//  BookingSupport.swift
//  WantProcuration
//
//  Shared helpers for booking from the assistant chat and for the "nearby offices" card
//  (IOS_PORT_GUIDE.md §3, §4.5, §4.8). Uses the same Booking API calls as the normal booking form.
//

import Foundation
internal import CoreLocation

// MARK: - Transaction matching (code first, then keywords)

enum TransactionMatching {
    /// Best item whose description matches one of the keywords (after Arabic normalization).
    /// Exact = 3, one contains the other = 2, otherwise the share of keyword words found (must be ≥ 0.6).
    static func bestMatch<T>(_ items: [T], desc: (T) -> String?, keywords: [String]) -> T? {
        let normalizedKeywords = keywords
            .map { ArabicSearchNormalizer.normalize($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !normalizedKeywords.isEmpty else { return nil }

        var best: (item: T, score: Double)?
        for item in items {
            let text = ArabicSearchNormalizer.normalize(desc(item) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let textWords = Set(text.split(separator: " "))
            var score = 0.0
            for keyword in normalizedKeywords {
                if text == keyword {
                    score = max(score, 3)
                } else if text.contains(keyword) || keyword.contains(text) {
                    score = max(score, 2)
                } else {
                    let words = keyword.split(separator: " ")
                    let found = words.filter { textWords.contains($0) }.count
                    let share = words.isEmpty ? 0 : Double(found) / Double(words.count)
                    if share >= 0.6 { score = max(score, share) }
                }
            }
            if score > 0, score > (best?.score ?? 0) {
                best = (item, score)
            }
        }
        return best?.item
    }

    static func category(for service: GatewayService, in categories: [TransactionCategory]) -> TransactionCategory? {
        if !service.categoryCode.isEmpty, let byCode = categories.first(where: { $0.code == service.categoryCode }) {
            return byCode
        }
        return bestMatch(categories, desc: { $0.desc }, keywords: service.classificationKeywords + [service.categoryDesc])
    }

    /// `sameCategory`: the picked category has the service's code, so the type code can be trusted.
    static func type(for service: GatewayService, in types: [TransactionType], sameCategory: Bool) -> TransactionType? {
        if sameCategory, !service.typeCode.isEmpty, let byCode = types.first(where: { $0.code == service.typeCode }) {
            return byCode
        }
        return bestMatch(types, desc: { $0.desc }, keywords: service.typeKeywords + [service.typeDesc, service.nameAr])
    }
}

// MARK: - Offices

enum OfficeDirectory {
    private static var cache: (offices: [OfficeModel], date: Date)?

    /// All offices (getOrgUnitStatus), cached for 5 minutes.
    static func offices() async throws -> [OfficeModel] {
        if let cache, Date().timeIntervalSince(cache.date) < 300 { return cache.offices }
        let offices = try await APIClient.shared.getOffices()
        cache = (offices, Date())
        return offices
    }

    /// VIP = orgType 1, or "مميز" in the type description.
    static func isVip(_ office: OfficeModel) -> Bool {
        office.orgType == 1 || office.orgTypeDesc.contains("مميز")
    }

    static func location(of office: OfficeModel) -> CLLocation? {
        guard office.hasCoordinates else { return nil }
        return CLLocation(latitude: office.coordinate.latitude, longitude: office.coordinate.longitude)
    }

    /// Offices with coordinates, with `distance` (km) from `origin`, nearest first.
    static func sortedByDistance(_ offices: [OfficeModel], from origin: CLLocation) -> [OfficeModel] {
        offices.compactMap { office -> OfficeModel? in
            guard let location = location(of: office) else { return nil }
            var updated = office
            updated.distance = origin.distance(from: location) / 1000
            return updated
        }
        .sorted { $0.distance < $1.distance }
    }

    /// Default location when the user refuses location access: Cairo.
    static let cairo = CLLocation(latitude: 30.0444, longitude: 31.2357)
}

// MARK: - Availability check from the app (fallback when the gateway fails)

struct OfficeAvailability {
    let office: OfficeModel
    /// yyyy-MM-dd
    let firstDate: String
    let vipFlag: String?
}

enum OfficeAvailabilityChecker {
    /// Returns the office's first free day if it offers the category (and type, when given) and has a free day.
    static func check(_ office: OfficeModel, categoryCode: String?, typeCode: String?) async -> OfficeAvailability? {
        do {
            if let categoryCode, !categoryCode.isEmpty {
                let categories = try await APIClient.shared.getTransactionCategories(selectedOffice: office)
                guard let category = categories.first(where: { $0.code == categoryCode }) else { return nil }
                if let typeCode, !typeCode.isEmpty {
                    let types = try await APIClient.shared.getTransactionTypes(selectedOffice: office, selectedCategory: category)
                    guard types.contains(where: { $0.code == typeCode }) else { return nil }
                }
            }
            let agenda = try await APIClient.shared.getOfficeAgenda(selectedOffice: office)
            if let flag = agenda.vipFlag, !flag.isEmpty, !["1", "2", "3", "4"].contains(flag) { return nil }
            guard let day = agenda.officeAgendaData.reservationDate.first(where: {
                !BookingSlots.slots(for: $0, vipFlag: agenda.vipFlag).isEmpty
            }) else { return nil }
            return OfficeAvailability(office: office, firstDate: day.dateReserved, vipFlag: agenda.vipFlag)
        } catch {
            Logger.warning("Availability check failed for \(office.orgUnitID): \(error)")
            return nil
        }
    }

    /// Checks offices with at most `limit` requests at the same time; keeps the input order.
    static func checkAll(_ offices: [OfficeModel], categoryCode: String?, typeCode: String?, limit: Int) async -> [OfficeAvailability] {
        var results: [OfficeAvailability] = []
        var start = 0
        while start < offices.count {
            let batch = Array(offices[start..<min(start + limit, offices.count)])
            let found = await withTaskGroup(of: (Int, OfficeAvailability?).self) { group in
                for (index, office) in batch.enumerated() {
                    group.addTask { (index, await check(office, categoryCode: categoryCode, typeCode: typeCode)) }
                }
                var items: [(Int, OfficeAvailability?)] = []
                for await item in group { items.append(item) }
                return items.sorted { $0.0 < $1.0 }.compactMap { $0.1 }
            }
            results += found
            start += limit
        }
        return results
    }
}

// MARK: - Days and times

enum BookingSlots {
    /// vipFlag "1"/"4" = exact times; otherwise periods (same rule as the booking form).
    static func usesExactTime(_ vipFlag: String?) -> Bool {
        vipFlag == "1" || vipFlag == "4"
    }

    static func slots(for day: ReservationDate, vipFlag: String?) -> [String] {
        if usesExactTime(vipFlag) {
            return (day.reservationTime ?? []).map(\.reserveTime)
        }
        return (day.reservePeriods ?? []).map(\.timePeriod)
    }
}

enum BookingDates {
    private static func parse(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(value.prefix(10)))
    }

    /// yyyy-MM-dd → dd/MM/yyyy
    static func slashed(_ value: String) -> String {
        let parts = value.prefix(10).split(separator: "-")
        guard parts.count == 3 else { return value }
        return "\(parts[2])/\(parts[1])/\(parts[0])"
    }

    /// yyyy-MM-dd → readable day, e.g. "الخميس 5 نوفمبر".
    static func readable(_ value: String) -> String {
        guard let date = parse(value) else { return value }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: GatewayConfig.lang == "en" ? "en_US" : "ar_EG")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }

    /// Start date for a calendar event: the day + the time when it contains HH:mm (AM/PM or ص/م supported).
    static func eventStart(day: String, time: String) -> (date: Date, hasTime: Bool)? {
        guard let date = parse(day) else { return nil }
        let normalized = NationalIDParser.normalizeDigits(time)
        guard let match = normalized.firstMatch(of: #/(\d{1,2}):(\d{2})/#),
              var hour = Int(match.1), let minute = Int(match.2) else {
            return (date, false)
        }
        let lower = normalized.lowercased()
        if (lower.contains("pm") || normalized.contains("م")) && hour < 12 { hour += 12 }
        if (lower.contains("am") || normalized.contains("ص")) && hour == 12 { hour = 0 }
        let start = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
        return (start, true)
    }
}
