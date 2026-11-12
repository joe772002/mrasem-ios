//
//  ChatBookingCard.swift
//  WantProcuration
//
//  The booking card shown in the assistant chat after "Yes" (IOS_PORT_GUIDE.md §4.5).
//  Steps open one after another; a finished step collapses to a summary with a "Change" button.
//

import SwiftUI
import EventKit
import EventKitUI

struct ChatBookingCard: View {
    @ObservedObject var viewModel: ChatBookingViewModel
    /// Opens the full ticket screen.
    let onViewTicket: () -> Void

    @State private var shareItem: ShareItem?
    @State private var showCalendar = false
    @State private var calendarUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: "booking_chat_intro".localized(), viewModel.service.displayName))
                .font(.setFont(size: 15))
                .foregroundColor(.theme.text)
                .fixedSize(horizontal: false, vertical: true)

            stepBlock(.office, title: "booking_step_office", summary: viewModel.selectedOffice?.office.orgUnitName) {
                officeStep
            }
            if viewModel.step >= .service {
                stepBlock(.service, title: "booking_step_service", summary: serviceSummary) { serviceStep }
            }
            if viewModel.step >= .date {
                stepBlock(.date, title: "booking_step_date",
                          summary: viewModel.selectedDate.map { BookingDates.readable($0.dateReserved) }) { dateStep }
            }
            if viewModel.step >= .time {
                stepBlock(.time, title: "booking_step_time", summary: viewModel.selectedSlot.map(TimeDisplay.twelveHour)) { timeStep }
            }
            if viewModel.step >= .nid {
                stepBlock(.nid, title: "booking_step_nid", summary: viewModel.step > .nid ? "✔" : nil) { nidStep }
            }
            if viewModel.step == .confirm {
                confirmStep
            }
            if viewModel.step == .done {
                ticket
                checklistSection
                afterBookingActions
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await viewModel.start() }
        .sheet(item: $shareItem) { item in
            ActivityShareSheet(text: item.text)
        }
        .sheet(isPresented: $showCalendar) {
            if let reminder = viewModel.reminder {
                CalendarEventSheet(title: reminder.title, location: reminder.location, notes: reminder.notes,
                                   start: reminder.start, hasTime: reminder.hasTime)
                    .ignoresSafeArea()
            }
        }
        .alert("booking_calendar_unavailable".localized(), isPresented: $calendarUnavailable) {
            Button("موافق") {}
        }
    }

    private var serviceSummary: String? {
        guard let type = viewModel.selectedType?.desc else { return nil }
        return [viewModel.selectedCategory?.desc, type].compactMap { $0 }.joined(separator: " ← ")
    }

    // MARK: - Step frame

    @ViewBuilder
    private func stepBlock<Content: View>(_ step: ChatBookingViewModel.Step, title: String, summary: String?,
                                          @ViewBuilder content: () -> Content) -> some View {
        let isCurrent = viewModel.step == step
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isCurrent ? "circle.inset.filled" : "checkmark.circle.fill")
                    .foregroundColor(isCurrent ? .theme.themeBlue : .green)
                Text(title.localized())
                    .font(.setFontSemiBold(size: 14))
                    .foregroundColor(.theme.text)
                if !isCurrent, let summary {
                    Text(summary)
                        .font(.setFont(size: 13))
                        .foregroundColor(.theme.themeGray)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                if !isCurrent && viewModel.step != .done && !viewModel.isChanging {
                    Button("booking_change".localized()) { viewModel.change(step) }
                        .font(.setFont(size: 13))
                        .foregroundColor(.theme.themeBlue)
                        .disabled(viewModel.isBooking)
                }
                if isCurrent && viewModel.isChanging {
                    // Leave the step without changing anything.
                    Button {
                        viewModel.cancelChange()
                    } label: {
                        Text("booking_cancel_change".localized())
                            .font(.setFontSemiBold(size: 13))
                            .foregroundColor(.theme.themeBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.theme.themeBlue.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            if isCurrent {
                content()
            }
        }
        .padding(10)
        .background(Color.theme.themeBlue.opacity(isCurrent ? 0.05 : 0.02),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 1. Office

    @ViewBuilder
    private var officeStep: some View {
        switch viewModel.officesState {
        case .idle, .loading:
            loadingRow("booking_finding_offices".localized())
        case .failed:
            VStack(alignment: .leading, spacing: 8) {
                Text("booking_no_offices".localized())
                    .font(.setFont(size: 14)).foregroundColor(.red)
                Button("retry".localized()) { Task { await viewModel.loadOffices() } }
                    .font(.setFont(size: 14)).buttonStyle(.bordered)
            }
        case .loaded:
            if viewModel.hasNoOffices {
                Text("booking_no_offices".localized())
                    .font(.setFont(size: 14)).foregroundColor(.theme.themeGray)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    officeGroup("booking_group_nearest", viewModel.nearest)
                    officeGroup("booking_group_earliest", viewModel.earliest)
                    officeGroup("booking_group_vip", viewModel.vip)
                }
            }
        }
    }

    private func officeGroup(_ titleKey: String, _ offices: [OfficeChoice]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titleKey.localized())
                .font(.setFontSemiBold(size: 13))
                .foregroundColor(.theme.text)
            if offices.isEmpty {
                Text("booking_group_empty".localized())
                    .font(.setFont(size: 12)).foregroundColor(.theme.themeGray)
            } else {
                ForEach(offices) { choice in
                    Button {
                        Task { await viewModel.selectOffice(choice) }
                    } label: {
                        OfficeChoiceRow(choice: choice)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 2. Transaction

    private var serviceStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.serviceNotInOffice {
                Text("booking_service_not_in_office".localized())
                    .font(.setFont(size: 13)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewModel.serviceLoading && viewModel.categories.isEmpty {
                loadingRow(nil)
            } else {
                Text("booking_pick_classification".localized())
                    .font(.setFont(size: 13)).foregroundColor(.theme.themeGray)
                AssistantChipsFlow(labels: viewModel.categories.map { $0.desc ?? "" },
                                   selectedIndex: viewModel.categories.firstIndex { $0.code == viewModel.selectedCategory?.code }) { index in
                    let category = viewModel.categories[index]
                    Task { await viewModel.pickCategory(category) }
                }
                if viewModel.selectedCategory != nil {
                    Text("booking_pick_type".localized())
                        .font(.setFont(size: 13)).foregroundColor(.theme.themeGray)
                    if viewModel.serviceLoading {
                        loadingRow(nil)
                    } else {
                        AssistantChipsFlow(labels: viewModel.types.map { $0.desc ?? "" },
                                           selectedIndex: viewModel.types.firstIndex { $0.code == viewModel.selectedType?.code }) { index in
                            viewModel.pickType(viewModel.types[index])
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3. Day / 4. Time

    @ViewBuilder
    private var dateStep: some View {
        if viewModel.agendaLoading {
            loadingRow(nil)
        } else if viewModel.dates.isEmpty {
            Text("no_available_dates".localized())
                .font(.setFont(size: 14)).foregroundColor(.red)
        } else {
            AssistantChipsFlow(labels: viewModel.dates.map { BookingDates.readable($0.dateReserved) }) { index in
                viewModel.pickDate(viewModel.dates[index])
            }
        }
    }

    @ViewBuilder
    private var timeStep: some View {
        let slots = viewModel.slots
        if slots.isEmpty {
            Text("booking_no_times".localized())
                .font(.setFont(size: 14)).foregroundColor(.red)
        } else {
            AssistantChipsFlow(labels: slots.map(TimeDisplay.twelveHour)) { index in
                let slot = slots[index]
                Task { await viewModel.pickSlot(slot) }
            }
        }
    }

    // MARK: - 5. National ID / 6. Confirm

    @ViewBuilder
    private var nidStep: some View {
        if viewModel.nidChecking {
            loadingRow("validating".localized())
        } else if let error = viewModel.nidError {
            VStack(alignment: .leading, spacing: 8) {
                Text(error).font(.setFont(size: 13)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                Button("retry".localized()) { Task { await viewModel.verifyNationalId() } }
                    .font(.setFont(size: 14)).buttonStyle(.bordered)
            }
        }
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("booking_nid_note".localized())
                .font(.setFont(size: 12)).foregroundColor(.theme.themeGray)
                .fixedSize(horizontal: false, vertical: true)
            if let error = viewModel.bookingError {
                Text(error).font(.setFont(size: 13)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Task { await viewModel.confirm() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isBooking { ProgressView().tint(.white) }
                    Text("booking_confirm".localized()).font(.setFontSemiBold(size: 15))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBooking)
        }
    }

    // MARK: - 7. Ticket

    private var ticket: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("booking_success_title".localized(), systemImage: "checkmark.seal.fill")
                .font(.setFontBold(size: 16))
                .foregroundColor(.green)
            if let ticketNo = viewModel.attendance?.ticketNo, !ticketNo.isEmpty {
                infoRow("booking_ticket_no", ticketNo)
            }
            if let attended = viewModel.attendance?.attendedNo {
                infoRow("booking_attended_no", String(attended))
            }
            if let time = viewModel.attendance?.actualTimeToAttend, !time.isEmpty {
                infoRow("booking_time_to_attend", time)
            }
            infoRow("booking_step_office", viewModel.selectedOffice?.office.orgUnitName ?? "")
            infoRow("booking_step_service", viewModel.transactionName)
            infoRow("booking_step_date", "\(viewModel.dayText) · \(viewModel.selectedSlot.map(TimeDisplay.twelveHour) ?? "")")
            Button("booking_view_ticket".localized(), action: onViewTicket)
                .font(.setFontSemiBold(size: 14))
                .buttonStyle(.borderedProminent)
                .tint(Color.theme.themeBlue)
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key.localized()).font(.setFont(size: 13)).foregroundColor(.theme.themeGray)
            Spacer(minLength: 8)
            Text(value).font(.setFontSemiBold(size: 13)).foregroundColor(.theme.text)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Checklist

    @ViewBuilder
    private var checklistSection: some View {
        if viewModel.checklistLoading {
            loadingRow(nil)
        } else if let checklist = viewModel.checklist, !checklist.items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("booking_checklist_title".localized())
                        .font(.setFontSemiBold(size: 15)).foregroundColor(.theme.text)
                    Spacer()
                    Text(String(format: "booking_checklist_progress".localized(),
                                viewModel.checkedItems.count, checklist.items.count))
                        .font(.setFont(size: 12)).foregroundColor(.theme.themeBlue)
                }
                ForEach(checklist.items) { item in
                    Button {
                        viewModel.toggle(item)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: viewModel.checkedItems.contains(item.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(.theme.themeBlue)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.setFont(size: 14)).foregroundColor(.theme.text)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !item.note.isEmpty {
                                    Text(item.note).font(.setFont(size: 12)).foregroundColor(.theme.themeGray)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                ForEach(checklist.tips, id: \.self) { tip in
                    Text("• " + tip).font(.setFont(size: 12)).foregroundColor(.theme.themeGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !checklist.disclaimer.isEmpty {
                    Text(checklist.disclaimer).font(.setFont(size: 11)).foregroundColor(.theme.themeGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
            }
        }
    }

    private var afterBookingActions: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    let text = await viewModel.shareText()
                    shareItem = ShareItem(text: text)
                }
            } label: {
                Label("booking_share".localized(), systemImage: "square.and.arrow.up")
                    .font(.setFont(size: 14))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.shareLoading)

            Button {
                if viewModel.reminder != nil {
                    showCalendar = true
                } else {
                    calendarUnavailable = true
                }
            } label: {
                Label("booking_add_calendar".localized(), systemImage: "calendar.badge.plus")
                    .font(.setFont(size: 14))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .tint(Color.theme.themeBlue)
    }

    private func loadingRow(_ text: String?) -> some View {
        HStack(spacing: 8) {
            ProgressView()
            if let text {
                Text(text).font(.setFont(size: 13)).foregroundColor(.theme.themeGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Office row

struct OfficeChoiceRow: View {
    let choice: OfficeChoice
    /// Optional text instead of the default "first free day" line.
    var dateText: String? = nil

    private var officeName: String {
        choice.isVip ? choice.office.orgUnitName + "  •  VIP" : choice.office.orgUnitName
    }

    /// "2.5 km  ·  أول يوم متاح: 05/11/2026" with the distance in bold — built in steps so the compiler checks it quickly.
    private var detailsLine: AttributedString {
        var distance = AttributedString(String(format: "%.1f", choice.distanceKm) + " " + "km_unit".localized())
        distance.font = .setFontBold(size: 12)
        distance.foregroundColor = .theme.themeBlue
        let defaultDate: String = "booking_first_free_day".localized() + " " + BookingDates.slashed(choice.firstDate)
        let date: String = dateText ?? defaultDate
        return distance + AttributedString("  ·  " + date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(choice.isVip ? .theme.gold : .theme.themeBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(officeName)
                    .font(.setFontBold(size: 15))
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.leading)
                Text(detailsLine)
                    .font(.setFont(size: 12))
                    .foregroundColor(.theme.themeGray)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.theme.themeGray)
                .padding(.top, 4)
        }
        .padding(10)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Share sheet

struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Calendar ("Add reminder")

/// System "new event" screen, pre-filled. No calendar permission is needed for this screen.
struct CalendarEventSheet: UIViewControllerRepresentable {
    let title: String
    let location: String
    let notes: String
    let start: Date
    let hasTime: Bool
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: { dismiss() }) }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = title
        event.location = location
        event.notes = notes.isEmpty ? nil : notes
        event.startDate = start
        event.endDate = start.addingTimeInterval(3600)
        event.isAllDay = !hasTime
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: () -> Void
        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            dismiss()
        }
    }
}
