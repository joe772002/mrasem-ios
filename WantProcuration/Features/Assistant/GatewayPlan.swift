//
//  GatewayPlan.swift
//  WantProcuration
//
//  Requests with more than one need (IOS_PORT_GUIDE.md §4.13). The gateway returns `plan`:
//  ordered steps, each maybe bookable with its own service, plus notes. Decoded leniently like the rest.
//

import SwiftUI

struct GatewayPlanStep: Codable, Hashable {
    var n: Int
    var title: String
    var detail: String
    var who: String
    /// office | court | self | other
    var place: String
    var bookable: Bool
    var urgent: Bool
    /// Warning text; a bare `true` becomes "true" (shown as the «مهم» chip only).
    var warning: String
    var service: GatewayService?
    var documents: [GatewayDocument]
    var alternatives: [GatewayOption]

    enum CodingKeys: String, CodingKey {
        case n, title, detail, who, place, bookable, urgent, warning, service, documents, alternatives
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? c.decodeIfPresent(Int.self, forKey: .n) {
            n = number
        } else if let text = try? c.decodeIfPresent(String.self, forKey: .n), let number = Int(text) {
            n = number
        } else {
            n = 0
        }
        title = c.lenient(.title, "")
        detail = c.lenient(.detail, "")
        who = c.lenient(.who, "")
        place = c.lenient(.place, "")
        bookable = c.lenient(.bookable, false)
        urgent = c.lenient(.urgent, false)
        if let text = try? c.decodeIfPresent(String.self, forKey: .warning) {
            warning = text
        } else if let flag = try? c.decodeIfPresent(Bool.self, forKey: .warning) {
            warning = flag ? "true" : ""
        } else {
            warning = ""
        }
        service = c.lenient(.service, nil as GatewayService?)
        documents = c.lenient(.documents, [])
        alternatives = c.lenient(.alternatives, [])
    }

    var hasWarning: Bool { !warning.isEmpty && warning.lowercased() != "false" }
    /// Real warning sentence (not just a true flag).
    var warningText: String? { hasWarning && warning.lowercased() != "true" ? warning : nil }
    /// Service to book, when the step is bookable.
    var bookableService: GatewayService? {
        guard bookable, let service, !service.id.isEmpty else { return nil }
        return service
    }
}

struct GatewayPlan: Codable, Hashable {
    var isPlan: Bool
    var steps: [GatewayPlanStep]
    var notes: [String]
    var oneBookingPerDay: Bool

    enum CodingKeys: String, CodingKey { case isPlan, steps, notes, oneBookingPerDay }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isPlan = c.lenient(.isPlan, false)
        steps = c.lenient(.steps, [])
        notes = c.lenient(.notes, [])
        oneBookingPerDay = c.lenient(.oneBookingPerDay, false)
    }

    var isEmpty: Bool { steps.isEmpty && notes.isEmpty }
}

// MARK: - Card

/// «خطواتك بالترتيب» (plan) or «معلومة مهمة» (extra info under a normal transaction card).
struct AssistantPlanCard: View {
    let plan: GatewayPlan
    let title: String
    /// Steps (by position in `plan.steps`) whose booking was already started.
    let startedSteps: Set<Int>
    let canBook: Bool
    let onBook: (Int, GatewayService) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.setFontBold(size: 15))
                .foregroundColor(.theme.text)

            ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                stepRow(step, index: index)
            }

            if !plan.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(plan.notes.enumerated()), id: \.offset) { _, note in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").font(.setFontBold(size: 13)).foregroundColor(.theme.themeBlue)
                            Text(note)
                                .font(.setFontRegular(size: 13))
                                .foregroundColor(.theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if plan.oneBookingPerDay {
                Label("plan_one_per_day".localized(), systemImage: "calendar.badge.exclamationmark")
                    .font(.setFontSemiBold(size: 12))
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("plan_disclaimer".localized())
                .font(.setFontRegular(size: 11))
                .foregroundColor(.theme.themeGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.theme.themeBlue.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.theme.themeBlue.opacity(0.12), lineWidth: 1)
        }
    }

    private func stepRow(_ step: GatewayPlanStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(step.n > 0 ? step.n : index + 1)")
                .font(.setFontBold(size: 13))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(step.urgent ? Color.red : Color.theme.themeBlue, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(step.who.isEmpty ? step.title : "\(step.title) (\(step.who))")
                    .font(.setFontSemiBold(size: 14))
                    .foregroundColor(.theme.text)
                    .fixedSize(horizontal: false, vertical: true)

                chipsRow(step)

                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(.setFontRegular(size: 13))
                        .foregroundColor(.theme.themeGray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let warning = step.warningText {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.setFontRegular(size: 12))
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let service = step.bookableService {
                    bookingPart(step, service, index: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func chipsRow(_ step: GatewayPlanStep) -> some View {
        let place = placeText(step.place)
        if step.urgent || step.hasWarning || place != nil {
            HStack(spacing: 6) {
                if step.urgent { chip("plan_urgent".localized(), .red) }
                if step.hasWarning { chip("plan_warning".localized(), .orange) }
                if let place { chip(place, .theme.themeBlue) }
            }
        }
    }

    private func chip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.setFontSemiBold(size: 11))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func placeText(_ place: String) -> String? {
        switch place.lowercased() {
        case "office": return "plan_place_office".localized()
        case "court": return "plan_place_court".localized()
        case "self": return "plan_place_self".localized()
        case "other": return "plan_place_other".localized()
        default: return nil
        }
    }

    @ViewBuilder
    private func bookingPart(_ step: GatewayPlanStep, _ service: GatewayService, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(service.displayName)
                .font(.setFontSemiBold(size: 13))
                .foregroundColor(.theme.themeBlue)
            let others = step.alternatives.map(\.label).filter { !$0.isEmpty }
            if !others.isEmpty {
                Text("plan_or".localized() + " " + others.joined(separator: " / "))
                    .font(.setFontRegular(size: 12))
                    .foregroundColor(.theme.themeGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if startedSteps.contains(index) {
                Label("plan_booking_started".localized(), systemImage: "checkmark.circle.fill")
                    .font(.setFontSemiBold(size: 12))
                    .foregroundColor(.green)
            } else {
                Button {
                    onBook(index, service)
                } label: {
                    Text("plan_book_step".localized())
                        .font(.setFontSemiBold(size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.theme.themeBlue, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canBook)
                .opacity(canBook ? 1 : 0.5)
            }
        }
        .padding(.top, 2)
    }
}
