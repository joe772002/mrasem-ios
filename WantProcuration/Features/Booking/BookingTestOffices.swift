//
//  BookingTestOffices.swift
//  WantProcuration
//
//  Settings → «مكاتب ليس بها مواعيد (للعرض)» (IOS_PORT_GUIDE.md §4.12).
//  Replaces the old debug-only TestFlags.simulateNoFreeDays: offices chosen here open in the booking form as if they
//  had no free days, so the «nearby offices» card can be demonstrated. Active only while the developer section is
//  unlocked on this device (Debug, or 7 taps on «Version»).
//

import SwiftUI

/// One office in the demo list — stored as JSON `[{id,name,gov}]`.
struct DemoOffice: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var gov: String

    init(id: String, name: String, gov: String) {
        self.id = id
        self.name = name
        self.gov = gov
    }

    enum CodingKeys: String, CodingKey { case id, name, gov }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // The id may come as a string or a number.
        if let text = try? c.decodeIfPresent(String.self, forKey: .id) {
            id = text
        } else if let number = try? c.decodeIfPresent(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = ""
        }
        name = c.lenient(.name, "")
        gov = c.lenient(.gov, "")
    }
}

/// GET /offices/lookup response.
struct OfficeLookupResponse: Decodable {
    var offices: [DemoOffice]

    enum CodingKeys: String, CodingKey { case offices }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        offices = c.lenient(.offices, [])
    }
}

/// UserDefaults-backed list of demo offices.
enum BookingTestConfig {
    static let storageKey = "booking_test.no_free_days_offices"

    static var offices: [DemoOffice] {
        get {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let list = try? JSONDecoder().decode([DemoOffice].self, from: data) else { return [] }
            return list
        }
        set {
            if newValue.isEmpty {
                UserDefaults.standard.removeObject(forKey: storageKey)
            } else if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
        }
    }

    /// True when the office must look like it has no free days (only while the developer section is unlocked).
    static func hidesFreeDays(of officeId: String) -> Bool {
        guard GatewaySettingsAccess.isVisible, !officeId.isEmpty else { return false }
        return offices.contains { $0.id == officeId }
    }
}

extension GatewayClient {
    /// GET /offices/lookup?q=&limit=10 — search by office name or area (§4.12).
    func lookupOffices(_ query: String, limit: Int = 10) async throws -> [DemoOffice] {
        let base = GatewayConfig.baseURL
        guard !base.isEmpty, var components = URLComponents(string: base + "/offices/lookup") else {
            throw GatewayError.notConfigured
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components.url else { throw GatewayError.notConfigured }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let token = GatewayConfig.token
        if !token.isEmpty { request.setValue(token, forHTTPHeaderField: "X-Gateway-Token") }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GatewayError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GatewayError.badStatus(http.statusCode) }
        do {
            return try JSONDecoder().decode(OfficeLookupResponse.self, from: data).offices.filter { !$0.id.isEmpty }
        } catch {
            Logger.error("Gateway decode OfficeLookupResponse failed: \(error)")
            throw GatewayError.invalidResponse
        }
    }
}

struct BookingTestSection: View {
    /// The app switches language itself, so the search field is pinned to the reading side.
    let isRTL: Bool

    @State private var selected = BookingTestConfig.offices
    @State private var query = ""
    @State private var results: [DemoOffice] = []
    @State private var isSearching = false
    @State private var errorText: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("booking_test_section".localized())
                .font(.setFontBold(size: 18))
                .foregroundColor(Color.theme.text)

            Text("booking_test_hint".localized())
                .font(.setFontRegular(size: 13))
                .foregroundColor(Color.theme.themeGray)
                .fixedSize(horizontal: false, vertical: true)

            // Chosen offices — tap to remove.
            if selected.isEmpty {
                Text("booking_test_none".localized())
                    .font(.setFontRegular(size: 13))
                    .foregroundColor(Color.theme.themeGray)
            } else {
                VStack(spacing: 6) {
                    ForEach(selected) { office in
                        row(office, isSelected: true) { remove(office) }
                    }
                }
                Button {
                    selected = []
                    BookingTestConfig.offices = []
                } label: {
                    Text("booking_test_clear".localized())
                        .font(.setFont(size: 14))
                        .foregroundColor(.red)
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.theme.themeGray)
                TextField("booking_test_search".localized(), text: $query)
                    .font(.setFontRegular(size: 14))
                    .autocorrectionDisabled()
                    .textAlignedToReadingSide(isRTL: isRTL)
                    .submitLabel(.search)
                    .onSubmit { search(now: true) }
                if isSearching { ProgressView() }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.white1))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
            .onChange(of: query) { _, _ in search(now: false) }

            if let errorText {
                Text(errorText)
                    .font(.setFontRegular(size: 13))
                    .foregroundColor(.red)
            }

            // Results — tap to add (or remove when already chosen).
            if !results.isEmpty {
                VStack(spacing: 6) {
                    ForEach(results) { office in
                        let isSelected = selected.contains { $0.id == office.id }
                        row(office, isSelected: isSelected) {
                            if isSelected { remove(office) } else { add(office) }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .onAppear { selected = BookingTestConfig.offices }
        .onDisappear { searchTask?.cancel() }
    }

    private func row(_ office: DemoOffice, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isSelected ? Color.theme.themeBlue : Color.theme.themeGray)
                VStack(alignment: .leading, spacing: 2) {
                    Text(office.name)
                        .font(.setFont(size: 14))
                        .foregroundColor(Color.theme.text)
                        .multilineTextAlignment(.leading)
                    if !office.gov.isEmpty {
                        Text(office.gov)
                            .font(.setFontRegular(size: 12))
                            .foregroundColor(Color.theme.themeGray)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.white1.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }

    private func add(_ office: DemoOffice) {
        guard !selected.contains(where: { $0.id == office.id }) else { return }
        selected.append(office)
        BookingTestConfig.offices = selected
    }

    private func remove(_ office: DemoOffice) {
        selected.removeAll { $0.id == office.id }
        BookingTestConfig.offices = selected
    }

    /// Debounced lookup (400 ms while typing, immediate on submit).
    private func search(now: Bool) {
        searchTask?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            errorText = nil
            isSearching = false
            return
        }
        searchTask = Task {
            if !now {
                try? await Task.sleep(nanoseconds: 400_000_000)
                if Task.isCancelled { return }
            }
            isSearching = true
            defer { isSearching = false }
            do {
                let found = try await GatewayClient.shared.lookupOffices(text)
                if Task.isCancelled { return }
                results = found
                errorText = nil
            } catch {
                if Task.isCancelled { return }
                Logger.warning("Office lookup failed: \(error)")
                results = []
                errorText = "booking_test_error".localized()
            }
        }
    }
}
