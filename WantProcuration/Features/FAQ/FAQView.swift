//
//  FAQView.swift
//  WantProcuration
//
//  Frequently asked questions (IOS_PORT_GUIDE.md §4.2): search, accordion (one open answer),
//  optional action button ("book_appointment" opens the office list for booking).
//

import SwiftUI
import SwiftfulRouting

struct FAQView: View {
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    @StateObject private var viewModel = FAQViewModel()

    var body: some View {
        ZStack {
            HomeBackground().ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    searchField
                    content
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .task { if viewModel.items.isEmpty { viewModel.load() } }
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
    }

    // MARK: Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("faq_title".localized())
                .font(.setFontBold(size: 26))
                .foregroundColor(.theme.text)
            Text("faq_subtitle".localized())
                .font(.setFont(size: 14))
                .foregroundColor(.theme.themeGray)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.theme.themeGray)
            TextField("faq_search_hint".localized(), text: $viewModel.searchText)
                .font(.setFont(size: 15))
                .textAlignedToReadingSide(isRTL: appManager.isRTL)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.theme.themeGray)
                }
                .accessibilityLabel("faq_clear_search".localized())
            }
        }
        .padding(12)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        case .failed:
            VStack(spacing: 12) {
                Text("faq_error".localized())
                    .font(.setFont())
                    .foregroundColor(.theme.themeGray)
                Button("retry".localized()) { viewModel.load() }
                    .font(.setFont())
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        case .loaded:
            let items = viewModel.filteredItems
            if items.isEmpty {
                VStack(spacing: 12) {
                    Text("faq_no_results".localized())
                        .font(.setFont())
                        .foregroundColor(.theme.themeGray)
                    Button("faq_clear_search".localized()) { viewModel.searchText = "" }
                        .font(.setFont())
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        FAQRow(
                            item: item,
                            lang: viewModel.lang,
                            isExpanded: viewModel.expandedId == item.id,
                            onToggle: { withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggle(item) } },
                            onAction: { route in open(route) }
                        )
                    }
                }
            }
        }
    }

    private func open(_ route: String) {
        switch route {
        case "book_appointment":
            router.showScreen(.push) { _ in
                OfficeListView(appManager: appManager, category: .reserve)
            }
        case "inquire_reservation":
            router.showScreen(.push) { _ in
                ReservationInquiryView(appManager: appManager)
            }
        case "open_assistant":
            router.showScreen(.push) { _ in
                AssistantView(appManager: appManager)
            }
        default:
            Logger.warning("FAQ: unknown actionRoute \(route)")
        }
    }
}

private struct FAQRow: View {
    /// Button text for each action route; nil = unknown route, no button.
    static func actionTitle(_ route: String) -> String? {
        switch route {
        case "book_appointment": return "Reserve".localized()
        case "inquire_reservation": return "faq_action_inquire".localized()
        case "open_assistant": return "faq_action_assistant".localized()
        default: return nil
        }
    }

    let item: FAQItem
    let lang: String
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAction: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 10) {
                    Text(item.question(lang: lang))
                        .font(.setFontSemiBold(size: 15))
                        .foregroundColor(.theme.text)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.theme.themeGray)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(.top, 4)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer(lang: lang))
                    .font(.setFont(size: 14))
                    .foregroundColor(.theme.themeGray)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let route = item.actionRoute, let title = Self.actionTitle(route) {
                    Button {
                        onAction(route)
                    } label: {
                        Text(title)
                            .font(.setFont(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.theme.themeBlue, in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        }
    }
}
