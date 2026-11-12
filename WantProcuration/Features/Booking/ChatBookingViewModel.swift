//
//  ChatBookingViewModel.swift
//  WantProcuration
//
//  Booking inside the assistant chat, after "Yes" (IOS_PORT_GUIDE.md §4.5):
//  office → transaction → day → time → national ID → confirm → ticket (+ checklist, share, reminder).
//  Same Booking API calls and rules as the normal booking form.
//

import Foundation
import Combine
internal import CoreLocation

struct OfficeChoice: Identifiable {
    var id: String { office.orgUnitID }
    let office: OfficeModel
    let distanceKm: Double
    /// yyyy-MM-dd
    let firstDate: String
    var isVip: Bool { OfficeDirectory.isVip(office) }
}

final class ChatBookingViewModel: ObservableObject, Identifiable {
    enum Step: Int, Comparable {
        case office, service, date, time, nid, confirm, done
        static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    enum LoadState { case idle, loading, loaded, failed }

    let id = UUID()
    let service: GatewayService
    private let nationalId: String

    @Published private(set) var step: Step = .office

    // 1. Office
    @Published private(set) var officesState: LoadState = .idle
    @Published private(set) var nearest: [OfficeChoice] = []
    @Published private(set) var earliest: [OfficeChoice] = []
    @Published private(set) var vip: [OfficeChoice] = []
    @Published private(set) var selectedOffice: OfficeChoice?

    // 2. Transaction
    @Published private(set) var serviceLoading = false
    @Published private(set) var categories: [TransactionCategory] = []
    @Published private(set) var types: [TransactionType] = []
    @Published private(set) var selectedCategory: TransactionCategory?
    @Published private(set) var selectedType: TransactionType?
    @Published private(set) var serviceNotInOffice = false

    // 3–4. Day and time
    @Published private(set) var agendaLoading = false
    @Published private(set) var agenda: OfficeAgendaResponse?
    @Published private(set) var dates: [ReservationDate] = []
    @Published private(set) var selectedDate: ReservationDate?
    @Published private(set) var selectedSlot: String?

    // 5. National ID
    @Published private(set) var nidChecking = false
    @Published private(set) var nidError: String?

    // 6–7. Confirm and ticket
    @Published private(set) var isBooking = false
    @Published private(set) var bookingError: String?
    @Published private(set) var attendance: AttendanceResponse?
    private(set) var submittedRequest: ReservationRequest?

    // After booking
    @Published private(set) var checklist: ChecklistResponse?
    @Published private(set) var checklistLoading = false
    @Published var checkedItems: Set<String> = []
    @Published private(set) var shareLoading = false

    private var agendaTask: Task<Void, Never>?

    /// Choices as they were before "Change" was tapped. While it is set, the step being changed shows
    /// «تراجع», which puts everything back. Picking something new in that step drops it.
    private struct Snapshot {
        let step: Step
        let selectedOffice: OfficeChoice?
        let categories: [TransactionCategory]
        let types: [TransactionType]
        let selectedCategory: TransactionCategory?
        let selectedType: TransactionType?
        let serviceNotInOffice: Bool
        let selectedDate: ReservationDate?
        let selectedSlot: String?
    }
    @Published private var snapshot: Snapshot?
    var isChanging: Bool { snapshot != nil }

    init(service: GatewayService, nationalId: String) {
        self.service = service
        self.nationalId = nationalId
    }

    var transactionName: String { selectedType?.desc ?? service.displayName }

    var slots: [String] {
        guard let selectedDate else { return [] }
        return BookingSlots.slots(for: selectedDate, vipFlag: agenda?.vipFlag)
    }

    // MARK: - 1. Office

    func start() async {
        guard officesState == .idle else { return }
        await loadOffices()
    }

    func loadOffices() async {
        officesState = .loading
        let origin = (try? await OneShotLocationProvider().currentLocation()) ?? OfficeDirectory.cairo

        let all: [OfficeModel]
        do {
            all = try await OfficeDirectory.offices()
        } catch {
            Logger.error("Chat booking: offices failed: \(error)")
            officesState = .failed
            return
        }
        let sorted = OfficeDirectory.sortedByDistance(all, from: origin)

        if await loadFromGateway(sorted) == false {
            await loadLocally(sorted)
        }
        officesState = .loaded
    }

    /// Returns false when the gateway failed (or has no index yet), so the app checks offices itself.
    private func loadFromGateway(_ sorted: [OfficeModel]) async -> Bool {
        let candidates = Array(sorted.prefix(200))
        let request = RecommendRequest(
            categoryCode: service.categoryCode,
            typeCode: service.typeCode,
            offices: candidates.map { OfficeDistance(id: $0.orgUnitID, distanceKm: ($0.distance * 10).rounded() / 10) }
        )
        do {
            let response = try await GatewayClient.shared.recommendOffices(request)
            if response.isClientAgenda {
                // §2.5: the gateway picked the offices that offer the type (its index); the free days are read
                // here (the cloud gateway can't reach the booking API). Offices it doesn't know: full check here.
                if response.candidates.isEmpty && !response.indexReady { return false }
                await loadFromCandidates(response.candidates, sorted: candidates)
                return true
            }
            if response.isEmpty && !response.indexReady { return false }
            let byId = Dictionary(candidates.map { ($0.orgUnitID, $0) }, uniquingKeysWith: { first, _ in first })
            func choices(_ list: [GatewayOffice]) -> [OfficeChoice] {
                list.compactMap { item in
                    guard let office = byId[item.id] else { return nil }
                    return OfficeChoice(office: office,
                                        distanceKm: item.distanceKm > 0 ? item.distanceKm : office.distance,
                                        firstDate: item.firstDate)
                }
                .sorted { $0.distanceKm < $1.distanceKm }
                .prefix(4)
                .map { $0 }
            }
            nearest = choices(response.nearest)
            earliest = choices(response.earliest)
            vip = choices(response.vip)
            return true
        } catch {
            Logger.warning("Chat booking: /offices/recommend failed, checking offices locally: \(error)")
            return false
        }
    }

    /// Free days of the gateway's candidates (8 at a time), then the three groups like `loadLocally`.
    private func loadFromCandidates(_ list: [GatewayCandidate], sorted: [OfficeModel]) async {
        let byId = Dictionary(sorted.map { ($0.orgUnitID, $0) }, uniquingKeysWith: { first, _ in first })
        let known = list.filter { !$0.verify }.compactMap { byId[$0.id] }
        let unknown = list.filter { $0.verify }.compactMap { byId[$0.id] }
        let freeDays = await OfficeAvailabilityChecker.checkAll(known, categoryCode: nil, typeCode: nil, limit: 8)
        let checked = await OfficeAvailabilityChecker.checkAll(
            unknown, categoryCode: service.categoryCode, typeCode: service.typeCode, limit: 4)
        let found = freeDays + checked
        setGroups(found.map { OfficeChoice(office: $0.office, distanceKm: $0.office.distance, firstDate: $0.firstDate) })
    }

    private func setGroups(_ all: [OfficeChoice]) {
        nearest = Array(all.sorted { $0.distanceKm < $1.distanceKm }.prefix(4))
        earliest = Array(all.sorted { ($0.firstDate, $0.distanceKm) < ($1.firstDate, $1.distanceKm) }.prefix(4))
            .sorted { $0.distanceKm < $1.distanceKm }
        vip = Array(all.filter(\.isVip).sorted { $0.distanceKm < $1.distanceKm }.prefix(4))
    }

    /// Nearest 12 offices + nearest 6 VIP offices, 6 checks at a time.
    private func loadLocally(_ sorted: [OfficeModel]) async {
        let regular = sorted.filter { !OfficeDirectory.isVip($0) }.prefix(12)
        let vipOffices = sorted.filter { OfficeDirectory.isVip($0) }.prefix(6)
        let found = await OfficeAvailabilityChecker.checkAll(
            Array(regular) + Array(vipOffices),
            categoryCode: service.categoryCode,
            typeCode: service.typeCode,
            limit: 6
        )
        setGroups(found.map { OfficeChoice(office: $0.office, distanceKm: $0.office.distance, firstDate: $0.firstDate) })
    }

    var hasNoOffices: Bool { officesState == .loaded && nearest.isEmpty && earliest.isEmpty && vip.isEmpty }

    func selectOffice(_ choice: OfficeChoice) async {
        snapshot = nil
        selectedOffice = choice
        resetFrom(.service)
        step = .service
        loadAgenda(for: choice.office)
        await loadCategories(for: choice.office)
    }

    // MARK: - 2. Transaction

    private func loadCategories(for office: OfficeModel) async {
        serviceLoading = true
        defer { serviceLoading = false }
        do {
            categories = try await APIClient.shared.getTransactionCategories(selectedOffice: office)
        } catch {
            Logger.error("Chat booking: categories failed: \(error)")
            categories = []
        }
        guard selectedOffice?.office.orgUnitID == office.orgUnitID else { return }

        if let category = TransactionMatching.category(for: service, in: categories) {
            serviceNotInOffice = false
            await choose(category, auto: true)
        } else {
            serviceNotInOffice = true
        }
    }

    func pickCategory(_ category: TransactionCategory) async {
        snapshot = nil
        resetFrom(.date)
        await choose(category, auto: false)
    }

    private func choose(_ category: TransactionCategory, auto: Bool) async {
        guard let office = selectedOffice?.office else { return }
        selectedCategory = category
        selectedType = nil
        types = []
        serviceLoading = true
        do {
            types = try await APIClient.shared.getTransactionTypes(selectedOffice: office, selectedCategory: category)
        } catch {
            Logger.error("Chat booking: types failed: \(error)")
        }
        serviceLoading = false
        if let type = TransactionMatching.type(for: service, in: types, sameCategory: category.code == service.categoryCode) {
            selectedType = type
            if auto { step = .date }
        }
    }

    func pickType(_ type: TransactionType) {
        snapshot = nil
        selectedType = type
        resetFrom(.date)
        step = .date
    }

    // MARK: - 3–4. Day and time

    private func loadAgenda(for office: OfficeModel) {
        agendaTask?.cancel()
        agendaLoading = true
        agenda = nil
        dates = []
        agendaTask = Task {
            let result = try? await APIClient.shared.getOfficeAgenda(selectedOffice: office)
            guard !Task.isCancelled, selectedOffice?.office.orgUnitID == office.orgUnitID else { return }
            agenda = result
            dates = Array((result?.officeAgendaData.reservationDate ?? []).prefix(10))
            agendaLoading = false
        }
    }

    func pickDate(_ date: ReservationDate) {
        snapshot = nil
        selectedDate = date
        selectedSlot = nil
        resetFrom(.nid)
        step = .time
    }

    func pickSlot(_ slot: String) async {
        snapshot = nil
        selectedSlot = slot
        step = .nid
        await verifyNationalId()
    }

    // MARK: - 5. National ID (checked again, same as the form)

    func verifyNationalId() async {
        nidError = nil
        nidChecking = true
        defer { nidChecking = false }
        do {
            if try await APIClient.shared.validateCustomerId(nationalId) {
                step = .confirm
            } else {
                nidError = "assistant_nid_invalid".localized()
            }
        } catch {
            nidError = "assistant_nid_error".localized()
        }
    }

    // MARK: - 6. Confirm

    func confirm() async {
        guard let office = selectedOffice?.office, let category = selectedCategory, let type = selectedType,
              let date = selectedDate, let slot = selectedSlot, !isBooking else { return }
        bookingError = nil
        isBooking = true
        defer { isBooking = false }

        let request = ReservationRequest()
        request.customerId = nationalId
        request.customerIdType = "1"
        request.orgUnitId = office.orgUnitID
        request.transactionTypeCategory = category
        request.transactionType = type
        request.reservationDay = date
        if BookingSlots.usesExactTime(agenda?.vipFlag) {
            request.reservationTime = date.reservationTime?.first { $0.reserveTime == slot }
            request.prepareForVIPSubmission()
        } else {
            request.reservationPeriod = date.reservePeriods?.first { $0.timePeriod == slot }
            request.prepareForRegularSubmission()
        }

        do {
            let response = try await APIClient.shared.submitReservation(request: request, office: office)
            if response.statusCode == "200" {
                submittedRequest = request
                attendance = response
                step = .done
                AssistantSuggestionStore.shared.service = nil
                await loadChecklist(category: category, type: type)
            } else {
                bookingError = "booking_failed".localized() + ": " + response.statusDesc
            }
        } catch {
            Logger.error("Chat booking: reserveProc failed: \(error)")
            bookingError = "booking_failed".localized() + ": " + error.localizedDescription
        }
    }

    // MARK: - Change a finished step

    /// Opens a finished step again. Nothing is cleared yet: the later steps only reset when something new is
    /// picked, so «تراجع» can bring the booking back exactly as it was.
    func change(_ target: Step) {
        guard step != .done, !isBooking else { return }
        if snapshot == nil {
            snapshot = Snapshot(step: step, selectedOffice: selectedOffice, categories: categories, types: types,
                                selectedCategory: selectedCategory, selectedType: selectedType,
                                serviceNotInOffice: serviceNotInOffice, selectedDate: selectedDate,
                                selectedSlot: selectedSlot)
        }
        nidError = nil
        bookingError = nil
        step = target
    }

    /// «تراجع»: back to the choices made before "Change".
    func cancelChange() {
        guard let saved = snapshot, !isBooking else { return }
        snapshot = nil
        selectedOffice = saved.selectedOffice
        categories = saved.categories
        types = saved.types
        selectedCategory = saved.selectedCategory
        selectedType = saved.selectedType
        serviceNotInOffice = saved.serviceNotInOffice
        selectedDate = saved.selectedDate
        selectedSlot = saved.selectedSlot
        step = saved.step
    }

    /// Clears the selections of `first` and the steps after it.
    private func resetFrom(_ first: Step) {
        if first <= .service {
            categories = []
            types = []
            selectedCategory = nil
            selectedType = nil
            serviceNotInOffice = false
        }
        if first <= .date { selectedDate = nil }
        if first <= .time { selectedSlot = nil }
        if first <= .nid { nidError = nil }
        bookingError = nil
    }

    // MARK: - After booking: checklist, share, reminder

    private func loadChecklist(category: TransactionCategory, type: TransactionType) async {
        checklistLoading = true
        defer { checklistLoading = false }
        checklist = try? await GatewayClient.shared.checklist(
            categoryCode: category.code ?? service.categoryCode,
            typeCode: type.code ?? service.typeCode,
            lang: GatewayConfig.lang
        )
    }

    func toggle(_ item: ChecklistItem) {
        if checkedItems.contains(item.id) {
            checkedItems.remove(item.id)
        } else {
            checkedItems.insert(item.id)
        }
    }

    var dayText: String { selectedDate.map { BookingDates.slashed($0.dateReserved) } ?? "" }

    /// Text to share: from /share, or a local text when the gateway fails.
    func shareText() async -> String {
        let office = selectedOffice?.office
        let ticket = attendance?.ticketNo ?? ""
        shareLoading = true
        defer { shareLoading = false }
        let serviceId = [selectedCategory?.code, selectedType?.code].compactMap { $0 }.joined(separator: "/")
        let request = ShareRequest(
            serviceId: serviceId.isEmpty ? service.id : serviceId,
            lang: GatewayConfig.lang,
            audience: "agent",
            officeName: office?.orgUnitName ?? "",
            officeAddress: office?.address,
            date: dayText,
            time: selectedSlot ?? "",
            ticketNo: ticket
        )
        if let response = try? await GatewayClient.shared.share(request), !response.text.isEmpty {
            return response.text
        }
        return "\(transactionName)\n\(office?.orgUnitName ?? "")\n\(dayText) \(selectedSlot ?? "")\n#\(ticket)"
    }

    /// Calendar event data (title, place, notes, start, has exact time).
    var reminder: (title: String, location: String, notes: String, start: Date, hasTime: Bool)? {
        guard let day = selectedDate?.dateReserved,
              let start = BookingDates.eventStart(day: day, time: selectedSlot ?? "") else { return nil }
        return (transactionName,
                selectedOffice?.office.orgUnitName ?? "",
                checklist?.reminder?.text ?? "",
                start.date,
                start.hasTime)
    }
}
