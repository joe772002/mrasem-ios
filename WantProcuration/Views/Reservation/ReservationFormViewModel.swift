import Combine
import Foundation

/// Data passed to the booking form opened from the "nearby offices" card (used once, before the assistant suggestion).
struct FormHandoff {
    let nationalId: String
    let categoryCode: String?
    let typeCode: String?
}

/// "Nearby offices with free days" card state (IOS_PORT_GUIDE.md §4.8 B).
enum AlternativesState {
    case hidden, loading, empty
    case found([OfficeChoice])
}

// MARK: - Validation Response Model
struct CustomerValidationResponse: Codable {
    let statusCode: String
    let statusDesc: String
}

class ReservationFormViewModel: ObservableObject {
    var reservationRequest = ReservationRequest()
    let office: OfficeModel
    @Published var formArray: [FormField] = []
    @Published var validationErrors: [String: String] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var transactionCategories: [TransactionCategory] = []
    @Published var transactionTypes: [TransactionType] = []
    @Published var reservationDates: [ReservationDate] = []
    @Published var reservationPeriods: [ReservePeriod] = []
    @Published var reservationTimes: [ReservationTime] = []
    @Published var officeAgenda: OfficeAgendaResponse?
    @Published var isValidatingCustomerId = false
    @Published var isInputsConfirmed = false
    @Published var customerIdValidationMessage: String?
    @Published var isCustomerIdValid = false
    @Published var attendanceResponse : AttendanceResponse?
    /// Changing this re-creates the national ID field so it shows a number set from code (ID scan).
    @Published var customerIdFieldToken = UUID()
    /// Changing this re-creates the category / type pickers so they show a value set from code
    /// (transaction suggested by the assistant).
    @Published var pickerRefreshToken = UUID()

    // Nearby offices with free days, shown when this office has none (§4.8 B)
    @Published private(set) var agendaFinished = false
    @Published private(set) var alternativesState: AlternativesState = .hidden
    private var alternativesKey: String?
    /// Set when the form is opened from the nearby offices card.
    let handoff: FormHandoff?

    /* AI-FEATURE (disabled)
    // MARK: Transaction suggestion (describe → category + type)
    /// Changing this re-creates the picker fields so they show a value set from code.
    @Published var formRefreshToken = UUID()
    @Published var isSuggesting = false
    @Published var suggestionMessage: String?
    @Published var suggestionFound = false
    /// Types per category code, cached so repeated suggestions don't re-download them.
    private var typesCache: [String: [TransactionType]] = [:]
    */
    
    @Published var selectedReservationDate: ReservationDate? {
        didSet {
            updateReservationOptions()
        }
    }
    
    // NEW: Computed property to check if user should see time or period
    var shouldShowReservationTime: Bool {
        guard let agenda = officeAgenda else { return false }
        return agenda.vipFlag == "1" || agenda.vipFlag == "4"
    }

    init(office: OfficeModel, handoff: FormHandoff? = nil) {
        self.office = office
        self.handoff = handoff
        buildFormArray()
    }
    
    private func buildFormArray() {
        var fields: [FormField] = [
            FormField(
                id: "customerId",
                title: "customerId".localized(),
                type: .number,
                placeholder: "enterCustomerId".localized(),
                hint: nil,
                required: true,
                value: reservationRequest.customerId,
                maxLength: 14

            ),
            FormField(
                id: "transactionTypeCategory",
                title: "transactionTypeCategory".localized(),
                type: .picker,
                placeholder: "enterTransactionTypeCategory".localized(),
                hint: nil,
                required: true,
                value: reservationRequest.transactionTypeCategory,
                options: transactionCategories
            ),
            FormField(
                id: "transactionTypeCode",
                title: "transactionTypeCode".localized(),
                type: .picker,
                placeholder: "enterTransactionTypeCode".localized(),
                hint: nil,
                required: true,
                value: reservationRequest.transactionType,
                options: transactionTypes
            ),
            FormField(
                id: "reservationDay",
                title: "reservationDay".localized(),
                type: .picker,
                placeholder: "enterReservationDay".localized(),
                hint: nil,
                required: true,
                value: reservationRequest.reservationDay,
                options: reservationDates
            )
        ]
        
        // Add either reservation time or period based on vipFlag
        if shouldShowReservationTime {
            fields.append(
                FormField(
                    id: "reservationTime",
                    title: "reservationPeriod".localized(),
                    type: .picker,
                    placeholder: "enterReservationPeriod".localized(),
                    hint: nil,
                    required: true,
                    value: reservationRequest.reservationTime,
                    options: reservationTimes
                )
            )
        } else {
            fields.append(
                FormField(
                    id: "reservationPeriod",
                    title: "reservationPeriod".localized(),
                    type: .picker,
                    placeholder: "enterReservationPeriod".localized(),
                    hint: nil,
                    required: true,
                    value: reservationRequest.reservationPeriod,
                    options: reservationPeriods
                )
            )
        }
        
        
        self.formArray = fields
    }
    
    private func updateReservationOptions() {
        if let selectedDate = selectedReservationDate {
            if shouldShowReservationTime {
                // Update reservation times for VIP users
                reservationTimes = selectedDate.reservationTime ?? []
                reservationRequest.reservationTime = nil
                Logger.info("Updated reservation times: \(reservationTimes.count) times available")
            } else {
                // Update reservation periods for regular users
                reservationPeriods = selectedDate.reservePeriods ?? []
                reservationRequest.reservationPeriod = nil
                Logger.info("Updated reservation periods: \(reservationPeriods.count) periods available")
            }
            
            // Rebuild form to update options
            buildFormArray()
        } else {
            reservationPeriods = []
            reservationTimes = []
            buildFormArray()
        }
    }
    
    func updateField(id: String, value: Any, value2: Any?) {
        reservationRequest.updateField(id: id, value: value)
        
        if id == "transactionTypeCode" {
            Task { await refreshAlternatives() }
        }

        if id == "transactionTypeCategory" {
            // The old type belongs to the old category: clear it so it can't be submitted by mistake.
            reservationRequest.transactionType = nil
            transactionTypes = []
            buildFormArray()
            Task {
                await fetchTransactionTypes()
            }
        }
        
        // Validate customer ID when it reaches 14 digits
        if id == "customerId", let customerIdString = value as? String {
            let digitsOnly = customerIdString.filter { $0.isNumber }
            if digitsOnly.count == 14 {
                Task {
                    await validateCustomerId(customerIdString)
                }
            } else {
                // Reset validation state if less than 14 digits
                isCustomerIdValid = false
                customerIdValidationMessage = nil
            }
        }
        
        
        if id == "reservationDay" {
            if let selectedDate = value as? ReservationDate {
                selectedReservationDate = selectedDate
            } else if let dateString = value as? String {
                // If value comes as string, find the matching date
                selectedReservationDate = reservationDates.first { $0.dateReserved == dateString }
            }
        }
        
        setValueForFormField(id: id, value: value)
        validationErrors.removeValue(forKey: id)
    }
    
    // MARK: - Customer ID Validation
    func validateCustomerId(_ customerId: String) async {
        isValidatingCustomerId = true
        customerIdValidationMessage = nil
        isCustomerIdValid = false
        
        do {
            let isValid = try await APIClient.shared.validateCustomerId(customerId)
            
            await MainActor.run {
                isCustomerIdValid = isValid
                if isValid {
                    customerIdValidationMessage = "الرقم القومي صحيح"
                    validationErrors.removeValue(forKey: "customerId")
                    Logger.info("Customer ID validated successfully: \(customerId)")
                } else {
                    customerIdValidationMessage = "الرقم القومي غير صحيح"
                    validationErrors["customerId"] = customerIdValidationMessage
                    Logger.warning("Customer ID validation failed: \(customerId)")
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                customerIdValidationMessage = error.localizedDescription
                validationErrors["customerId"] = customerIdValidationMessage
                Logger.error("Failed to validate customer ID: \(error)")
            }
        } catch {
            await MainActor.run {
                customerIdValidationMessage = "حدث خطأ أثناء التحقق من الرقم القومي"
                validationErrors["customerId"] = customerIdValidationMessage
                Logger.error("Unexpected error during customer ID validation: \(error)")
            }
        }
        
        await MainActor.run {
            isValidatingCustomerId = false
        }
    }
    
    /// Puts a number read from the ID card into the form, then validates it like a typed one.
    func applyScannedCustomerId(_ number: String) {
        updateField(id: "customerId", value: number, value2: nil)
        customerIdFieldToken = UUID()
    }

    func getFormFieldById(_ id: String) -> FormField? {
        return formArray.first(where: { $0.id == id })
    }
    
    func setValueForFormField(id: String, value: Any) {
        if let index = formArray.firstIndex(where: { $0.id == id }) {
            formArray[index].value = "\(value)"
        }
    }
    
    // MARK: - Validation
    func validateAllFields() -> Bool {
        var isValid = true
        validationErrors.removeAll()
        
        // Check the national ID: exactly 14 digits, and confirmed valid by the server
        let customerIdDigits = reservationRequest.customerId.filter { $0.isNumber }
        if customerIdDigits.count != 14 {
            validationErrors["customerId"] = "يجب أن يتكون الرقم القومي من 14 رقمًا"
            isValid = false
        } else if !isCustomerIdValid {
            validationErrors["customerId"] = "يرجى التحقق من صحة الرقم القومي"
            isValid = false
        }
        
        // Check if user confirmed the inputs
        if !isInputsConfirmed {
            validationErrors["confirmation"] = "يجب تأكيد صحة البيانات المدخلة"
            isValid = false
        }
        
        for field in formArray {
            if let error = field.validateField() {
                validationErrors[field.id] = error
                isValid = false
            }
        }
        
        return isValid
    }
    
    // MARK: - Submit Reservation
    func submitReservation() async -> Bool {
        guard validateAllFields() else {
            Logger.warning("Validation failed")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Set orgUnitId from office
        reservationRequest.orgUnitId = office.orgUnitID
        
        // Prepare request based on VIP status
        if shouldShowReservationTime {
            reservationRequest.prepareForVIPSubmission()
        } else {
            reservationRequest.prepareForRegularSubmission()
        }
        
        do {
            let response = try await APIClient.shared.submitReservation(
                request: reservationRequest,
                office: office
            )
            
            await MainActor.run {
                isLoading = false
            }
            let success = response.statusCode == "200"
            if success {
                // Keep the server's answer (ticket number, attendance time, queue number) for the success screen.
                attendanceResponse = response
                Logger.info("Reservation submitted successfully")
                return true
            } else {
                await MainActor.run {
                    errorMessage = response.statusDesc
                }
                Logger.error("Reservation submission failed")
                return false
            }
        } catch let error as APIError {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            Logger.error("Failed to submit reservation: \(error)")
            return false
        } catch {
            await MainActor.run {
                errorMessage = "حدث خطأ غير متوقع"
                isLoading = false
            }
            Logger.error("Unexpected error: \(error)")
            return false
        }
    }
    
    func fetchTransactionCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            transactionCategories = try await APIClient.shared.getTransactionCategories(selectedOffice: office)
            buildFormArray()
            Logger.info("Successfully loaded \(transactionCategories.count) category")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Failed to fetch transactionCategories: \(error)")
        } catch {
            Logger.error("Unexpected error: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchTransactionTypes() async {
        guard let category = reservationRequest.transactionTypeCategory else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            transactionTypes = try await APIClient.shared.getTransactionTypes(selectedOffice: office, selectedCategory: category)
            buildFormArray()
            Logger.info("Successfully loaded \(transactionTypes.count) Types")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Failed to fetch transactionTypes: \(error)")
        } catch {
            Logger.error("Unexpected error: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchOfficeAgenda() async {
        isLoading = true
        errorMessage = nil
        
        do {
            officeAgenda = try await APIClient.shared.getOfficeAgenda(selectedOffice: office)
            if let agenda = officeAgenda {
                reservationDates = agenda.officeAgendaData.reservationDate
                // Demo offices (§4.12): chosen in Settings › developer section; never applies to an office
                // opened from the alternatives card.
                if handoff == nil && BookingTestConfig.hidesFreeDays(of: office.orgUnitID) {
                    Logger.warning("Demo office: hiding the free days of \(office.orgUnitID)")
                    reservationDates = []
                }
                buildFormArray()
            } else {
                errorMessage = "agendaError".localized()
            }
            Logger.info("Successfully loaded \(reservationDates.count) dates")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Failed to fetch agenda: \(error)")
        } catch {
            Logger.error("Unexpected error: \(error)")
        }
        
        isLoading = false
        // Loaded (or failed): if there are no days, look for nearby offices that have some.
        agendaFinished = true
        Task { await refreshAlternatives() }
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchTransactionCategories()
            }
            
            group.addTask {
                await self.fetchOfficeAgenda()
            }
        }
        
        isLoading = false
    }

    // MARK: - Opened from the nearby offices card (§4.8 B)

    /// Puts the national ID and validates it, then selects the category and type by code.
    func applyHandoff(_ handoff: FormHandoff) async {
        if !handoff.nationalId.isEmpty {
            applyScannedCustomerId(handoff.nationalId)
        }
        guard let categoryCode = handoff.categoryCode else { return }
        if transactionCategories.isEmpty {
            await fetchTransactionCategories()
        }
        guard let category = transactionCategories.first(where: { $0.code == categoryCode }) else { return }
        reservationRequest.transactionTypeCategory = category
        reservationRequest.transactionType = nil
        transactionTypes = []
        await fetchTransactionTypes()
        if let typeCode = handoff.typeCode {
            reservationRequest.transactionType = transactionTypes.first { $0.code == typeCode }
        }
        validationErrors.removeValue(forKey: "transactionTypeCategory")
        if reservationRequest.transactionType != nil { validationErrors.removeValue(forKey: "transactionTypeCode") }
        buildFormArray()
        pickerRefreshToken = UUID()
        await refreshAlternatives()
    }

    // MARK: - Nearby offices with free days (§4.8 B)

    /// Shown only after the agenda finished loading with no days. Searches again when both
    /// category and type get selected (they are sent only together).
    func refreshAlternatives() async {
        guard agendaFinished, reservationDates.isEmpty else {
            alternativesState = .hidden
            return
        }
        let categoryCode = reservationRequest.transactionTypeCategory?.code
        let typeCode = reservationRequest.transactionType?.code
        let both = categoryCode != nil && typeCode != nil
        let key = both ? "\(categoryCode ?? "")/\(typeCode ?? "")" : "-"
        guard key != alternativesKey else { return }
        alternativesKey = key
        alternativesState = .loading

        let sendCategory = both ? categoryCode : nil
        let sendType = both ? typeCode : nil
        let all = (try? await OfficeDirectory.offices()) ?? []
        var choices = await alternativesFromGateway(all, categoryCode: sendCategory, typeCode: sendType)
        if choices == nil {
            choices = await alternativesLocally(all, categoryCode: sendCategory, typeCode: sendType)
        }
        guard alternativesKey == key else { return } // a newer search started
        let list = choices ?? []
        alternativesState = list.isEmpty ? .empty : .found(list)
    }

    /// nil = gateway failed (or empty with no index yet) → search from the app.
    private func alternativesFromGateway(_ all: [OfficeModel], categoryCode: String?, typeCode: String?) async -> [OfficeChoice]? {
        do {
            let response = try await GatewayClient.shared.alternativeOffices(
                AlternativesRequest(officeId: office.orgUnitID, categoryCode: categoryCode, typeCode: typeCode, limit: 4)
            )
            let byId = Dictionary(all.map { ($0.orgUnitID, $0) }, uniquingKeysWith: { first, _ in first })
            if response.isClientAgenda {
                // §2.6: nearest offices (from this office) that offer the type, by the gateway's index; the free
                // days are read here, 5 at a time, until 4 offices with a free day are found.
                if response.candidates.isEmpty && !response.indexReady { return nil }
                var found: [OfficeChoice] = []
                var start = 0
                let list = response.candidates
                while start < list.count && found.count < 4 {
                    let batch = Array(list[start..<min(start + 5, list.count)])
                    start += 5
                    let known = batch.filter { !$0.verify }.compactMap { byId[$0.id] }
                    let unknown = batch.filter { $0.verify }.compactMap { byId[$0.id] }
                    let distance = Dictionary(batch.map { ($0.id, $0.distanceKm) }, uniquingKeysWith: { first, _ in first })
                    let free = await OfficeAvailabilityChecker.checkAll(known, categoryCode: nil, typeCode: nil, limit: 5)
                    let checked = await OfficeAvailabilityChecker.checkAll(unknown, categoryCode: categoryCode,
                                                                           typeCode: typeCode, limit: 5)
                    let hits = free + checked
                    found += hits.map {
                        OfficeChoice(office: $0.office, distanceKm: distance[$0.office.orgUnitID] ?? $0.office.distance,
                                     firstDate: $0.firstDate)
                    }
                }
                return Array(found.sorted { $0.distanceKm < $1.distanceKm }.prefix(4))
            }
            if response.offices.isEmpty && !response.indexReady { return nil }
            return response.offices.compactMap { item -> OfficeChoice? in
                guard let model = byId[item.id] else { return nil }
                return OfficeChoice(office: model, distanceKm: item.distanceKm, firstDate: item.firstDate)
            }
            .sorted { $0.distanceKm < $1.distanceKm }
        } catch {
            Logger.warning("/offices/alternatives failed, searching locally: \(error)")
            return nil
        }
    }

    /// Nearest 10 offices to this office (no 0,0 coordinates), 5 checks at a time, first 4 by distance.
    private func alternativesLocally(_ all: [OfficeModel], categoryCode: String?, typeCode: String?) async -> [OfficeChoice] {
        guard let origin = OfficeDirectory.location(of: office) else { return [] }
        let nearest = OfficeDirectory.sortedByDistance(all.filter { $0.orgUnitID != office.orgUnitID }, from: origin)
            .prefix(10)
        let found = await OfficeAvailabilityChecker.checkAll(Array(nearest), categoryCode: categoryCode,
                                                             typeCode: typeCode, limit: 5)
        return Array(found.map { OfficeChoice(office: $0.office, distanceKm: $0.office.distance, firstDate: $0.firstDate) }
            .sorted { $0.distanceKm < $1.distanceKm }
            .prefix(4))
    }

    // MARK: - Transaction suggested by the assistant (IOS_PORT_GUIDE.md §4.8 A)

    /// Pre-selects the category, then the type, from the assistant's service:
    /// by code first, otherwise by the closest keyword match. No match = the user picks manually.
    func applyAssistantSuggestion(_ service: GatewayService) async {
        if transactionCategories.isEmpty {
            await fetchTransactionCategories()
        }
        let category = TransactionMatching.category(for: service, in: transactionCategories)
        guard let category else {
            Logger.warning("Assistant suggestion: category \(service.categoryCode) not offered by this office")
            return
        }
        reservationRequest.transactionTypeCategory = category
        reservationRequest.transactionType = nil
        transactionTypes = []
        await fetchTransactionTypes()

        let sameCategory = category.code == service.categoryCode
        let type = TransactionMatching.type(for: service, in: transactionTypes, sameCategory: sameCategory)
        reservationRequest.transactionType = type

        validationErrors.removeValue(forKey: "transactionTypeCategory")
        if type != nil { validationErrors.removeValue(forKey: "transactionTypeCode") }
        buildFormArray()
        pickerRefreshToken = UUID()
        await refreshAlternatives()
        Logger.info("Assistant suggestion applied: \(category.desc ?? "") / \(type?.desc ?? "-")")
    }

    /* AI-FEATURE (disabled)
    // MARK: - Transaction suggestion

    /// Understands a free-text description and pre-selects the matching category + type.
    func suggestTransaction(from description: String) async {
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSuggesting = true
        defer { isSuggesting = false }

        if transactionCategories.isEmpty {
            await fetchTransactionCategories()
        }

        let office = self.office
        let suggestion = await TransactionMatcher.suggest(
            description: text,
            categories: transactionCategories,
            loadTypes: { [self] category in
                if let code = category.code, let cached = typesCache[code] { return cached }
                let types = try await APIClient.shared.getTransactionTypes(selectedOffice: office, selectedCategory: category)
                if let code = category.code { typesCache[code] = types }
                return types
            }
        )

        guard let suggestion else {
            suggestionFound = false
            suggestionMessage = "مقدرتش أحدد نوع المعاملة من الوصف ده. اختار الفئة والنوع بنفسك."
            return
        }
        await applySuggestion(categoryCode: suggestion.category.code, typeCode: suggestion.type?.code)
        suggestionFound = true
        let typeName = suggestion.type?.desc ?? ""
        let picked = typeName.isEmpty ? (suggestion.category.desc ?? "") : "\(suggestion.category.desc ?? "") ← \(typeName)"
        // Low confidence = the top two choices were close.
        suggestionMessage = suggestion.confidence < 0.35
            ? "اقتراح مش مؤكد: \(picked). راجع النوع كويس قبل الحجز."
            : "اخترنالك: \(picked). راجعها قبل الحجز."
    }

    /// Selects a category / type by code (used by the description box and by Siri).
    func applySuggestion(categoryCode: String?, typeCode: String?) async {
        guard let categoryCode,
              let category = transactionCategories.first(where: { $0.code == categoryCode }) else {
            Logger.warning("Suggestion: category \(categoryCode ?? "nil") not found in this office")
            return
        }
        reservationRequest.transactionTypeCategory = category
        reservationRequest.transactionType = nil
        await fetchTransactionTypes()

        if let typeCode, let type = transactionTypes.first(where: { $0.code == typeCode }) {
            reservationRequest.transactionType = type
        }
        validationErrors.removeValue(forKey: "transactionTypeCategory")
        validationErrors.removeValue(forKey: "transactionTypeCode")
        buildFormArray()
        formRefreshToken = UUID()
        Logger.info("Suggestion applied: \(category.desc ?? "") / \(reservationRequest.transactionType?.desc ?? "-")")
    }
    */
}

// MARK: - API Client Extension
extension APIClient {
    func getTransactionCategories(selectedOffice: OfficeModel) async throws -> [TransactionCategory] {
        var endpoint = "ReservationMobile/getTrxCatByOrg/\(selectedOffice.orgUnitID)"
        if selectedOffice.QMeEnable == 1 {
            endpoint = "GetClassifications/\(selectedOffice.orgUnitID)"
        }
        Logger.info("Fetching transaction categories...")
        let response: [TransactionCategory] = try await get(endpoint, requiresAuth: false)
        Logger.info("Fetched \(response.count) transaction categories")
        return response
    }
    
    func getTransactionTypes(selectedOffice: OfficeModel, selectedCategory: TransactionCategory) async throws -> [TransactionType] {
        guard let categoryCode = selectedCategory.code else {
            throw APIError.dataError
        }
        var endpoint = "ReservationMobile/getTrxCatByOrg/\(selectedOffice.orgUnitID)/\(categoryCode)"
        if selectedOffice.QMeEnable == 1 {
            endpoint = "GetServiceTypes/\(selectedOffice.orgUnitID)?classficationid=\(categoryCode)"
        }
        Logger.info("Fetching transaction types...")
        let response: [TransactionType] = try await get(endpoint, requiresAuth: false)
        Logger.info("Fetched \(response.count) transaction types")
        return response
    }
    
    func getOfficeAgenda(selectedOffice: OfficeModel) async throws -> OfficeAgendaResponse {
        var endpoint = "ReservationMobile/getOfficeAgenda/\(selectedOffice.orgUnitID)/1/1/1/1/1"
        if selectedOffice.QMeEnable == 1 {
            endpoint = "GetOfficeAgenda/\(selectedOffice.orgUnitID)"
        }
        Logger.info("Fetching office agenda...")
        let response: OfficeAgendaResponse = try await get(endpoint, requiresAuth: false)
        Logger.info("Fetched \(response.officeAgendaData.reservationDate.count) agenda items")
        return response
    }
    
    func validateCustomerId(_ customerId: String) async throws -> Bool {
        let endpoint = "parties/validateIdentityNumber/\(customerId)"
        Logger.info("Validating customer ID: \(customerId)")
        
        let response: CustomerValidationResponse = try await get(endpoint, requiresAuth: false)
        Logger.info("Customer ID validation response: \(response.statusDesc)")
        
        // statusCode "1" means valid
        return response.statusCode == "1"
    }
    func submitReservation(request: ReservationRequest,office: OfficeModel) async throws -> AttendanceResponse {
        let endpoint = "ReservationMobile/reserveProc"
        Logger.info("submit JSON: \(request)")
        Logger.info("submiting Reservation")
        let response: AttendanceResponse = try await post(endpoint, body: request, requiresAuth: false)
        Logger.info("Submit response: \(response.statusDesc)")
        return response
//        return AttendanceResponse.preview
    }
    
}
