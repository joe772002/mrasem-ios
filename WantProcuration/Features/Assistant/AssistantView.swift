//
//  AssistantView.swift
//  WantProcuration
//
//  Assistant chat screen (IOS_PORT_GUIDE.md §4.3, §4.4).
//  IQKeyboardManager is turned off here so the keyboard shrinks the chat instead of pushing the screen.
//

import SwiftUI
import SwiftfulRouting
import IQKeyboardManagerSwift

struct AssistantView: View {
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    /// True when presented as a sheet (floating button on Home): shows a close button in the header.
    var showsCloseButton: Bool = false
    @StateObject private var viewModel = AssistantViewModel()
    /// Reads every reply aloud until muted from the header (§4.14).
    @ObservedObject private var voice = AssistantVoice.shared
    @State private var showScanner = false
    @State private var showVoice = false
    @FocusState private var inputFocused: Bool

    private let bottomId = "assistant-bottom"


    var body: some View {
        ZStack {
            // One flat color (no blue gradient) for the chat.
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                messages
                inputBar
            }
        }
        // Don't lose the chat by an accidental swipe while a reply or a booking is in progress.
        .interactiveDismissDisabled(viewModel.isSending)
        .onAppear { IQKeyboardManager.shared.isEnabled = false }
        .onDisappear {
            IQKeyboardManager.shared.isEnabled = true
            voice.stop()        // leaving the chat stops the voice
        }
        // the microphone must not hear the reply being read
        .onChange(of: showVoice) { if showVoice { voice.stop() } }
        .alert("assistant_voice_missing".localized(), isPresented: $voice.arabicMissing) {
            Button("ok".localized(), role: .cancel) {}
        }
        .sheet(isPresented: $showVoice) {
            VoiceInputSheet { text in
                Task { await viewModel.handleVoice(text) }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            NationalIDScanSheet { number in
                Task { await viewModel.useScannedNationalId(number) }
            }
        }
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
    }

    // MARK: - Header

    private var header: some View {
        // Title on one side, small round buttons on the other, centred on the title block
        // (they used to sit at the very top corner).
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("assistant_title".localized())
                    .font(.setFontBold(size: 22))
                    .foregroundColor(.theme.text)
                Text("assistant_subtitle".localized())
                    .font(.setFontRegular(size: 13))
                    .foregroundColor(.theme.themeGray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                // mute / unmute the assistant's voice (kept on the phone)
                headerButton(icon: voice.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                             tint: voice.isMuted ? .theme.themeGray : .theme.themeBlue,
                             label: (voice.isMuted ? "assistant_voice_unmute" : "assistant_voice_mute").localized()) {
                    voice.toggleMute()
                }
                if viewModel.isVerified {
                    headerButton(icon: "arrow.clockwise", tint: .theme.themeBlue,
                                 label: "assistant_restart".localized()) {
                        viewModel.restart()
                    }
                    .disabled(viewModel.isSending)
                    .opacity(viewModel.isSending ? 0.4 : 1)
                }
                if showsCloseButton {
                    headerButton(icon: "xmark", tint: .theme.text,
                                 label: "assistant_voice_close".localized()) {
                        router.dismissScreen()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private func headerButton(icon: String, tint: Color, label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(Color.theme.themeGray.opacity(0.12), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }


    // MARK: - Messages

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    BotBubble { BubbleText(text: "assistant_welcome".localized()) }

                    ForEach(viewModel.entries) { entry in
                        entryView(entry)
                    }

                    if viewModel.isSending {
                        BotBubble { TypingIndicator() }
                    }

                    chips

                    Color.clear.frame(height: 1).id(bottomId)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.entries.count) { scrollToBottom(proxy) }
            .onChange(of: viewModel.isSending) { scrollToBottom(proxy) }
            .onChange(of: viewModel.showSuggestions) { scrollToBottom(proxy) }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(bottomId, anchor: .bottom)
        }
    }

    @ViewBuilder
    private func entryView(_ entry: AssistantEntry) -> some View {
        switch entry.kind {
        case .user(let text):
            HStack {
                Spacer(minLength: 48)
                Text(text)
                    .font(.setFont(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

        case .bot(let response):
            BotBubble {
                VStack(alignment: .leading, spacing: 10) {
                    if response.isPlan, let plan = response.plan {
                        // §4.13: first line of the reply, then «خطواتك بالترتيب».
                        if !response.firstReplyLine.isEmpty {
                            BubbleText(text: response.firstReplyLine)
                        }
                        listenButton(entry)
                        planCard(plan, title: "plan_title".localized(), entry: entry)
                    } else {
                        if !response.reply.isEmpty {
                            BubbleText(text: response.reply)
                            listenButton(entry)
                        }
                        if response.isMatched, let service = response.service {
                            AssistantServiceCard(
                                service: service,
                                documents: response.documents,
                                answered: viewModel.answeredIds.contains(entry.id),
                                onYes: { viewModel.confirm(entry) },
                                onNo: { viewModel.reject(entry) }
                            )
                        }
                        if let info = response.infoPlan {
                            planCard(info, title: "plan_tips_title".localized(), entry: entry)
                        }
                    }
                }
            }

        case .failure:
            BotBubble {
                VStack(alignment: .leading, spacing: 8) {
                    Label("assistant_error".localized(), systemImage: "wifi.exclamationmark")
                        .font(.setFont(size: 14))
                        .foregroundColor(.red)
                    Button("retry".localized()) {
                        Task { await viewModel.retry(entry) }
                    }
                    .font(.setFont(size: 14))
                    .buttonStyle(.bordered)
                    .tint(Color.theme.themeBlue)
                    .disabled(viewModel.isSending)
                }
            }

        case .booking(let booking):
            BotBubble {
                ChatBookingCard(viewModel: booking) {
                    openTicket(booking)
                }
            }

        case let .info(text, isError):
            BotBubble(tint: isError ? .red : nil) {
                VStack(alignment: .leading, spacing: 8) {
                    BubbleText(text: text, color: isError ? .red : .theme.text)
                    listenButton(entry)
                }
            }
        }
    }

    /// «استمع» / «إيقاف» under a message: reads it even when the voice is muted.
    private func listenButton(_ entry: AssistantEntry) -> some View {
        let speaking = voice.speakingId == entry.id
        return Button {
            viewModel.toggleSpeak(entry)
        } label: {
            Label((speaking ? "assistant_listen_stop" : "assistant_listen").localized(),
                  systemImage: speaking ? "stop.fill" : "speaker.wave.2")
                .font(.setFont(size: 12))
                .foregroundColor(.theme.themeBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.theme.themeBlue.opacity(speaking ? 0.14 : 0.07), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func planCard(_ plan: GatewayPlan, title: String, entry: AssistantEntry) -> some View {
        AssistantPlanCard(
            plan: plan,
            title: title,
            startedSteps: viewModel.planStarted[entry.id] ?? [],
            canBook: viewModel.isVerified && !viewModel.isSending
        ) { index, service in
            viewModel.bookPlanStep(entry, stepIndex: index, service: service)
        }
    }

    // MARK: - Chips

    @ViewBuilder
    private var chips: some View {
        let reply = viewModel.replyChips
        if viewModel.showSuggestions && !viewModel.isSending {
            AssistantChipsFlow(labels: viewModel.suggestionChips.map(\.label)) { index in
                let option = viewModel.suggestionChips[index]
                Task { await viewModel.pick(option) }
            }
        } else if !reply.clarify.isEmpty {
            AssistantChipsFlow(labels: reply.clarify.map(\.label)) { index in
                let option = reply.clarify[index]
                Task { await viewModel.pickClarify(option) }
            }
        } else if !reply.quick.isEmpty {
            AssistantChipsFlow(labels: reply.quick) { index in
                let text = reply.quick[index]
                Task { await viewModel.send(text) }
            }
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        VStack(spacing: 6) {
            if viewModel.isVerified {
                messageInput
            } else {
                nationalIdInput
            }
            Text("assistant_disclaimer".localized())
                .font(.setFont(size: 11))
                .foregroundColor(.theme.themeGray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var nationalIdInput: some View {
        HStack(spacing: 8) {
            TextField("enter_national_id".localized(), text: $viewModel.nidInput)
                .keyboardType(.numberPad)
                .font(.setFont(size: 15))
                .textAlignedToReadingSide()
                .focused($inputFocused)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                }
                .onChange(of: viewModel.nidInput) { _, newValue in
                    let digits = ArabicSearchNormalizer.digitsOnly(newValue)
                    let limited = String(digits.prefix(14))
                    if limited != newValue { viewModel.nidInput = limited }
                }

            Button {
                showScanner = true
            } label: {
                Image(systemName: "viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.theme.themeBlue)
                    .frame(width: 44, height: 44)
                    .background(Color.theme.themeBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel.nidChecking)
            .accessibilityLabel("مسح البطاقة ضوئيًا")

            micButton(disabled: viewModel.nidChecking)

            Button {
                inputFocused = false
                Task { await viewModel.verifyNationalId() }
            } label: {
                ZStack {
                    if viewModel.nidChecking {
                        ProgressView().tint(.white)
                    } else {
                        Text("assistant_verify".localized())
                            .font(.setFontSemiBold(size: 15))
                    }
                }
                .foregroundColor(.white)
                .frame(minWidth: 64)
                .frame(height: 44)
                .padding(.horizontal, 8)
                .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel.nidChecking || viewModel.nidInput.isEmpty)
        }
    }

    private var messageInput: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("assistant_input_hint".localized(), text: $viewModel.input, axis: .vertical)
                .lineLimit(1...4)
                .font(.setFont(size: 15))
                .textAlignedToReadingSide()
                .focused($inputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                }
                .onChange(of: viewModel.input) { _, newValue in
                    if newValue.count > AssistantViewModel.maxInputLength {
                        viewModel.input = String(newValue.prefix(AssistantViewModel.maxInputLength))
                    }
                }

            micButton(disabled: viewModel.isSending)

            Button {
                Task { await viewModel.sendInput() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(canSend ? Color.theme.themeBlue : Color.theme.themeGray.opacity(0.5), in: Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel("assistant_send".localized())
        }
    }

    /// Always visible next to the send / verify button: light background, colored icon.
    private func micButton(disabled: Bool) -> some View {
        Button {
            inputFocused = false
            showVoice = true
        } label: {
            Image(systemName: "mic.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(disabled ? .theme.themeGray : .theme.themeBlue)
                .frame(width: 44, height: 44)
                .background(Color.theme.themeBlue.opacity(0.1), in: Circle())
        }
        .disabled(disabled)
        .accessibilityLabel("assistant_voice_input".localized())
    }

    private var canSend: Bool {
        !viewModel.isSending && !viewModel.isCoolingDown
            && !viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Navigation

    private func openTicket(_ booking: ChatBookingViewModel) {
        guard let office = booking.selectedOffice?.office, let request = booking.submittedRequest else { return }
        let exactTime = BookingSlots.usesExactTime(booking.agenda?.vipFlag)
        router.showScreen(.fullScreenCover) { _ in
            ReservationDetailsView(appManager: appManager, office: office, reservationRequest: request,
                                   attendance: booking.attendance, shouldShowReservationTime: exactTime)
        }
    }

}

// MARK: - Building blocks

private struct BotBubble<Content: View>: View {
    var tint: Color? = nil
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder((tint ?? Color.secondary).opacity(tint == nil ? 0.12 : 0.35), lineWidth: 1)
                }
            Spacer(minLength: 32)
        }
    }
}

private struct BubbleText: View {
    let text: String
    var color: Color = .theme.text

    var body: some View {
        Text(text)
            .font(.setFont(size: 15))
            .foregroundColor(color)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.theme.themeGray)
                    .frame(width: 7, height: 7)
                    .opacity(animate ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: animate)
            }
        }
        .padding(.vertical, 4)
        .onAppear { animate = true }
    }
}

/// Wrapping row of tappable chips.
struct AssistantChipsFlow: View {
    let labels: [String]
    /// Highlighted chip (used by the booking steps), nil = none.
    var selectedIndex: Int? = nil
    let onTap: (Int) -> Void

    var body: some View {
        AssistantFlowLayout(spacing: 8) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Button {
                    onTap(index)
                } label: {
                    Text(label)
                        .font(.setFont(size: 14))
                        .foregroundColor(index == selectedIndex ? .white : .theme.themeBlue)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(index == selectedIndex ? Color.theme.themeBlue : Color.theme.themeBlue.opacity(0.08), in: Capsule())
                        .overlay { Capsule().strokeBorder(Color.theme.themeBlue.opacity(0.3), lineWidth: 1) }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Simple flow layout (wraps to the next line when a row is full). Respects RTL through the layout direction.
struct AssistantFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Suggested transaction card (§4.4).
private struct AssistantServiceCard: View {
    let service: GatewayService
    let documents: [GatewayDocument]
    let answered: Bool
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("assistant_suggested_service".localized())
                    .font(.setFont(size: 12))
                    .foregroundColor(.theme.themeGray)
                Text(service.displayName)
                    .font(.setFontBold(size: 16))
                    .foregroundColor(.theme.text)
                if !service.categoryDesc.isEmpty {
                    Text("reservation_classification".localized() + ": " + service.categoryDesc)
                        .font(.setFont(size: 13))
                        .foregroundColor(.theme.themeGray)
                }
            }

            if !documents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("assistant_required_documents".localized())
                        .font(.setFontSemiBold(size: 14))
                        .foregroundColor(.theme.text)
                    ForEach(Array(documents.enumerated()), id: \.offset) { _, doc in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.top, 3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(doc.name)
                                    .font(.setFont(size: 14))
                                    .foregroundColor(.theme.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                if doc.original {
                                    Text("•  " + "assistant_original".localized())
                                        .font(.setFont(size: 12))
                                        .foregroundColor(.theme.themeBlue)
                                }
                            }
                        }
                    }
                }
            }

            if service.documentsAreGeneric {
                Text("assistant_generic_docs_note".localized())
                    .font(.setFont(size: 12))
                    .foregroundColor(.theme.themeGray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            if answered {
                Label("assistant_answered".localized(), systemImage: "checkmark.circle.fill")
                    .font(.setFont(size: 14))
                    .foregroundColor(.green)
            } else {
                Text("assistant_confirm_question".localized())
                    .font(.setFontSemiBold(size: 14))
                    .foregroundColor(.theme.text)

                Button(action: onYes) {
                    Text("assistant_confirm_yes".localized())
                        .font(.setFontSemiBold(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onNo) {
                    Text("assistant_confirm_no".localized())
                        .font(.setFont(size: 14))
                        .foregroundColor(.theme.themeBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.theme.themeBlue.opacity(0.5), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            // No "book manually" button: booking is done inside the chat only.
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
