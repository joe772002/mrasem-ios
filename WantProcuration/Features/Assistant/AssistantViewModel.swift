//
//  AssistantViewModel.swift
//  WantProcuration
//
//  State and logic of the assistant chat (IOS_PORT_GUIDE.md §4.3 – §4.6).
//  - The national ID is checked with the Booking API only, and is never sent to the gateway.
//  - "Yes" opens the booking card inside the chat (§4.5); "Book this transaction" opens the normal
//    booking flow with the suggested transaction pre-selected (AssistantSuggestionStore, §4.8 A).
//

import Foundation
import Combine

struct AssistantEntry: Identifiable {
    enum Kind {
        case user(String)
        case bot(ChatResponse)
        case failure(retryText: String, choiceKey: String?)
        case info(String, isError: Bool)
        case booking(ChatBookingViewModel)
    }

    let id = UUID()
    let kind: Kind
}

final class AssistantViewModel: ObservableObject {
    @Published private(set) var entries: [AssistantEntry] = []
    @Published var input = ""
    @Published private(set) var isSending = false
    /// True for a few seconds after HTTP 429 ("too fast"); the send button is disabled meanwhile.
    @Published private(set) var isCoolingDown = false

    // National ID step
    @Published var nidInput = ""
    @Published private(set) var nidChecking = false
    /// Set only after the Booking API confirms it. Lives in memory only, while the screen is open.
    @Published private(set) var nationalId: String?

    // Suggestion chips (after the ID is verified, and after a "No")
    @Published private(set) var suggestionChips: [GatewayOption] = []
    @Published private(set) var showSuggestions = false
    private var suggestions: [GatewayOption] = []

    /// Bot replies whose Yes/No was already answered (their buttons are replaced by "Done").
    @Published private(set) var answeredIds: Set<UUID> = []
    /// Plan steps whose booking was started, per bot reply: «بدأ الحجز بالأسفل» (§4.13).
    @Published private(set) var planStarted: [UUID: Set<Int>] = [:]


    private(set) var sessionId: String?
    /// Service id the user said "No" to, waiting to be reported (§4.6).
    private var pendingRejected: String?

    static let maxInputLength = 1000

    var isVerified: Bool { nationalId != nil }

    /// Reads every new message aloud until muted (§4.14).
    let voice = AssistantVoice.shared
    private var isArabic: Bool { GatewayConfig.lang == "ar" }

    // MARK: - National ID

    func verifyNationalId() async {
        let digits = ArabicSearchNormalizer.digitsOnly(nidInput)
        nidInput = digits
        guard digits.count == 14 else {
            addInfo("error_national_id_length".localized(), isError: true)
            return
        }
        guard !nidChecking else { return }
        nidChecking = true
        defer { nidChecking = false }

        do {
            let response: CustomerValidationResponse =
                try await APIClient.shared.get("parties/validateIdentityNumber/\(digits)", requiresAuth: false)
            if response.statusCode == "1" {
                nationalId = digits
                nidInput = ""
                let infoId = addInfo("assistant_nid_verified".localized(), isError: false)
                await loadSuggestions()
                readWithSuggestions(infoId, "assistant_nid_verified".localized())
            } else {
                let desc = response.statusDesc.trimmingCharacters(in: .whitespacesAndNewlines)
                let text = desc.isEmpty
                    ? "assistant_nid_invalid".localized()
                    : "assistant_nid_invalid".localized() + " (\(desc))"
                addInfo(text, isError: true)
                nidInput = ""
            }
        } catch {
            Logger.error("Assistant: national ID check failed: \(error)")
            addInfo("assistant_nid_error".localized(), isError: true)
        }
    }

    /// Number confirmed by the ID card scanner.
    func useScannedNationalId(_ number: String) async {
        nidInput = number
        await verifyNationalId()
    }

    /// Voice result (§4.7): before the ID is verified it fills the ID field (digits only) and verifies at 14 digits;
    /// after that it is sent as a message.
    func handleVoice(_ text: String) async {
        if isVerified {
            await send(text)
        } else {
            nidInput = String(ArabicSearchNormalizer.digitsOnly(text).prefix(14))
            if nidInput.count == 14 { await verifyNationalId() }
        }
    }

    private func loadSuggestions() async {
        let loaded = (try? await GatewayClient.shared.suggestions(lang: GatewayConfig.lang)) ?? []
        suggestions = loaded.isEmpty ? Self.exampleOptions : loaded
        suggestionChips = suggestions
        showSuggestions = true
    }

    private static var exampleOptions: [GatewayOption] {
        ["assistant_example_1", "assistant_example_2", "assistant_example_3"].map {
            let text = $0.localized()
            return GatewayOption(label: text, text: text)
        }
    }

    // MARK: - Sending

    /// Sends the text in the input field.
    func sendInput() async {
        let text = input
        input = ""
        await send(text)
    }

    /// Sends a message. `choiceKey` = "cat/type" when the user picked a clarify option.
    func send(_ text: String, choiceKey: String? = nil) async {
        let message = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxInputLength))
        guard !message.isEmpty, isVerified, !isSending, !isCoolingDown else { return }

        showSuggestions = false
        voice.stop()
        // The rejection must reach the gateway BEFORE the next /chat (it is linked to the last message).
        reportPendingRejection(chosen: choiceKey)

        entries.append(AssistantEntry(kind: .user(message)))
        await perform(message, choiceKey: choiceKey)
    }

    private func perform(_ message: String, choiceKey: String?) async {
        isSending = true
        defer { isSending = false }

        let request = ChatRequest(
            message: message,
            sessionId: sessionId,
            lang: GatewayConfig.lang,
            choiceKey: choiceKey
        )
        do {
            let response = try await GatewayClient.shared.chat(request)
            if let id = response.sessionId, !id.isEmpty { sessionId = id }
            let entry = AssistantEntry(kind: .bot(response))
            entries.append(entry)
            voice.speakNew(entry.id, speechText(response), arabic: isArabic)
        } catch GatewayError.rateLimited(let reply, let retryAfter) {
            // Sent too fast (§4.10): not an error. Show the gateway's message as a normal assistant bubble,
            // take the message back into the input so the user can resend it after `retryAfter` seconds.
            if let last = entries.last, case .user(let text) = last.kind, text == message {
                entries.removeLast()
            }
            let text = reply.isEmpty ? "assistant_too_fast".localized() : reply
            let entry = AssistantEntry(kind: .bot(ChatResponse(plainReply: text)))
            entries.append(entry)
            voice.speakNew(entry.id, AssistantVoice.cleanForSpeech(text), arabic: isArabic)
            if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { input = message }
            isCoolingDown = true
            Task {
                try? await Task.sleep(for: .seconds(retryAfter))
                isCoolingDown = false
            }
        } catch {
            Logger.error("Assistant: /chat failed: \(error)")
            entries.append(AssistantEntry(kind: .failure(retryText: message, choiceKey: choiceKey)))
        }
    }

    /// Removes the failure bubble and the user bubble before it, then sends the same text again.
    func retry(_ entry: AssistantEntry) async {
        guard case let .failure(text, choiceKey) = entry.kind,
              let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries.remove(at: index)
        if index > 0, case .user = entries[index - 1].kind {
            entries.remove(at: index - 1)
        }
        entries.append(AssistantEntry(kind: .user(text)))
        await perform(text, choiceKey: choiceKey)
    }


    // MARK: - Chips

    /// A suggestion / alternative chip.
    func pick(_ option: GatewayOption) async {
        if let service = option.service, !service.id.isEmpty {
            // Already resolved: answer locally, without calling the gateway.
            showSuggestions = false
            reportPendingRejection(chosen: service.id)
            entries.append(AssistantEntry(kind: .user(option.label)))
            let docs = option.documents
            let reply = ChatResponse(localReply: "assistant_picked_reply".localized(), service: service, documents: docs)
            let entry = AssistantEntry(kind: .bot(reply))
            entries.append(entry)
            voice.speakNew(entry.id, speechText(reply), arabic: isArabic)
        } else {
            await send(option.text ?? option.label)
        }
    }

    /// A clarify option under the last bot reply.
    func pickClarify(_ option: GatewayOption) async {
        await send(option.label, choiceKey: option.service?.id)
    }

    /// Chips shown under the last bot reply (hidden while sending or once the user replies).
    var replyChips: (clarify: [GatewayOption], quick: [String]) {
        guard !isSending, let last = entries.last, case let .bot(response) = last.kind else { return ([], []) }
        if !response.clarifyOptions.isEmpty { return (response.clarifyOptions, []) }
        return ([], response.quickReplies)
    }

    // MARK: - Yes / No / Book

    /// "Yes": reports the acceptance and opens the booking card in the chat (only one booking card at a time).
    func confirm(_ entry: AssistantEntry) {
        guard case let .bot(response) = entry.kind, let service = response.service, let nationalId else { return }
        answeredIds.insert(entry.id)
        reportPendingRejection(chosen: service.id)
        if let sessionId {
            GatewayClient.shared.sendFeedback(
                FeedbackRequest(sessionId: sessionId, accepted: true, serviceId: service.id, chosenServiceId: nil)
            )
        }
        AssistantSuggestionStore.shared.service = service
        showSuggestions = false
        voice.stop()
        entries.removeAll { if case .booking = $0.kind { return true } else { return false } }
        entries.append(AssistantEntry(kind: .booking(ChatBookingViewModel(service: service, nationalId: nationalId))))
    }

    /// «احجز هذه الخطوة»: the same in-chat booking (§4.5) for the step's service (§4.13).
    func bookPlanStep(_ entry: AssistantEntry, stepIndex: Int, service: GatewayService) {
        guard let nationalId, !service.id.isEmpty else { return }
        reportPendingRejection(chosen: service.id)
        // tells the gateway this plan step was useful (its self-learned guidance steps count bookings), once
        if !(planStarted[entry.id]?.contains(stepIndex) ?? false), let sessionId {
            GatewayClient.shared.sendFeedback(
                FeedbackRequest(sessionId: sessionId, accepted: true, serviceId: service.id, chosenServiceId: nil,
                                stage: "plan_step")
            )
        }
        voice.stop()
        planStarted[entry.id, default: []].insert(stepIndex)
        AssistantSuggestionStore.shared.service = service
        showSuggestions = false
        entries.removeAll { if case .booking = $0.kind { return true } else { return false } }
        entries.append(AssistantEntry(kind: .booking(ChatBookingViewModel(service: service, nationalId: nationalId))))
    }

    /// "No": nothing is sent now; the rejection is reported with the user's next action (§4.6).
    func reject(_ entry: AssistantEntry) {
        guard case let .bot(response) = entry.kind, let service = response.service else { return }
        answeredIds.insert(entry.id)
        pendingRejected = service.id
        let infoId = addInfo("assistant_rejected".localized(), isError: false)
        suggestionChips = response.alternatives.isEmpty ? suggestions : response.alternatives
        showSuggestions = !suggestionChips.isEmpty
        readWithSuggestions(infoId, "assistant_rejected".localized())
    }

    /// "Book this transaction": opens the normal booking flow with the service pre-selected.
    private func reportPendingRejection(chosen: String?) {
        guard let rejected = pendingRejected else { return }
        pendingRejected = nil
        guard let sessionId else { return }
        let chosenId = (chosen == rejected) ? nil : chosen
        GatewayClient.shared.sendFeedback(
            FeedbackRequest(sessionId: sessionId, accepted: false, serviceId: rejected, chosenServiceId: chosenId)
        )
    }

    // MARK: - New chat

    /// Clears the chat but keeps the verified national ID and the suggestions.
    func restart() {
        voice.stop()
        reportPendingRejection(chosen: nil)
        if let sessionId {
            Task { await GatewayClient.shared.endSession(sessionId) }
        }
        sessionId = nil
        entries = []
        answeredIds = []
        planStarted = [:]
        input = ""
        if isVerified {
            let infoId = addInfo("assistant_nid_verified".localized(), isError: false)
            suggestionChips = suggestions
            showSuggestions = !suggestions.isEmpty
            readWithSuggestions(infoId, "assistant_nid_verified".localized())
        }
    }

    /// An app message in the chat; read aloud like the replies.
    @discardableResult
    private func addInfo(_ text: String, isError: Bool) -> UUID {
        let entry = AssistantEntry(kind: .info(text, isError: isError))
        entries.append(entry)
        voice.speakNew(entry.id, AssistantVoice.cleanForSpeech(text), arabic: isArabic)
        return entry.id
    }

    /// The app message just shown, read again with the suggestion chips under it.
    private func readWithSuggestions(_ infoId: UUID, _ text: String) {
        guard showSuggestions, !suggestionChips.isEmpty, entries.last?.id == infoId,
              voice.speakingId == nil || voice.speakingId == infoId else { return }
        let labels = suggestionChips.map { $0.label.replacingOccurrences(of: " — ", with: "، ") }
        let lead = isArabic ? " الاقتراحات: " : " Suggestions: "
        voice.speakNew(infoId, AssistantVoice.cleanForSpeech(text) + lead + labels.joined(separator: isArabic ? "؛ " : "; ") + ".",
                       arabic: isArabic)
    }

    // MARK: - Voice

    /// «استمع» / «إيقاف» on a reply (reads it even when muted).
    func toggleSpeak(_ entry: AssistantEntry) {
        switch entry.kind {
        case .bot(let response): voice.toggle(entry.id, speechText(response), arabic: isArabic)
        case .info(let text, _): voice.toggle(entry.id, AssistantVoice.cleanForSpeech(text), arabic: isArabic)
        default: break
        }
    }

    /// The gateway's `speech` (the whole message for the ear); for a reply made in the app, the same parts here.
    private func speechText(_ response: ChatResponse) -> String {
        if !response.speech.isEmpty { return response.speech }
        var text = AssistantVoice.cleanForSpeech(response.reply)
        let docs = response.documents.map { $0.name.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if response.isMatched && !docs.isEmpty {
            text += (isArabic ? " المستندات المطلوبة: " : " Documents needed: ") + docs.joined(separator: isArabic ? "؛ " : "; ") + "."
        }
        let options = response.clarifyOptions.map { $0.label.replacingOccurrences(of: " — ", with: "، ") }
        if !options.isEmpty {
            text += (isArabic ? " الاختيارات: " : " The options: ") + options.joined(separator: isArabic ? "؛ " : "; ") + "."
        }
        return text
    }
}
