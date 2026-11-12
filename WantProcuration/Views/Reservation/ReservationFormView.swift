//
//  ReservationFormView.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI
import SwiftfulRouting
import SwiftfulUI

struct ReservationFormView: View {
   
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    @StateObject var viewModel: ReservationFormViewModel
    @State private var showErrorAlert = false
    /// Transaction suggested by the assistant (IOS_PORT_GUIDE.md §4.8 A).
    @ObservedObject private var assistantStore = AssistantSuggestionStore.shared
    let office : OfficeModel
    // AI-FEATURE (disabled):
    // /// Set when the form is opened from Siri with a suggested transaction.
    // let suggestedCategoryCode: String?
    // let suggestedTypeCode: String?
    // @State private var transactionDescription = ""

    init(appManager: AppManager, office: OfficeModel, handoff: FormHandoff? = nil) {
        self.office = office
        self.appManager = appManager
        _viewModel = StateObject(wrappedValue: ReservationFormViewModel(office: office, handoff: handoff))
    }
    // AI-FEATURE (disabled): previous init with suggestion parameters
    // init(appManager: AppManager, office: OfficeModel,
    //      suggestedCategoryCode: String? = nil, suggestedTypeCode: String? = nil) {
    //     self.office = office
    //     self.appManager = appManager
    //     self.suggestedCategoryCode = suggestedCategoryCode
    //     self.suggestedTypeCode = suggestedTypeCode
    //     _viewModel = StateObject(wrappedValue: ReservationFormViewModel(office: office))
    // }
    
    var body: some View {
        ZStack {
//            Color(Color.theme.background)
//                .edgesIgnoringSafeArea(.all)
            HomeBackground().edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading) {
                  
                OfficeSimplifiedCard(office: office, appManager: appManager)

                    if assistantStore.service != nil {
                        assistantBanner
                    }

                    // AI-FEATURE (disabled):
                    // describeTransactionSection
                    // #if DEBUG
                    // debugToolsSection
                    // #endif

                    formSection

                    alternativesSection
                    
                    // Confirmation Checkbox
                    confirmationSection
                    
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Submit".localized())
                            .font(Font.setFontSemiBold())
                    }
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.theme.themeBlue)
                    .cornerRadius(16)
                    .shadow(color: .theme.themeBlue.opacity(0.3), radius: 3, y: 3)
                    .disabled(viewModel.isLoading)
                    .asButton {
                        hideKeyboard()
                        Task {
                            let success = await viewModel.submitReservation()
                            if success {
                                // The suggestion was used: clear it.
                                assistantStore.service = nil
                                router.showScreen(.fullScreenCover){ _ in
                                    ReservationDetailsView(appManager: appManager, office: viewModel.office, reservationRequest: viewModel.reservationRequest, attendance: viewModel.attendanceResponse, shouldShowReservationTime: viewModel.shouldShowReservationTime)
                                }
                            } else {
                                showErrorAlert = true
                            }
                        }
                    }
                    
                    
                }.padding()
            }
            .task {
                await viewModel.fetchData()
                if let handoff = viewModel.handoff {
                    // From the nearby offices card: has priority over the assistant suggestion.
                    await viewModel.applyHandoff(handoff)
                } else if let service = assistantStore.service {
                    await viewModel.applyAssistantSuggestion(service)
                }
                // AI-FEATURE (disabled):
                // if suggestedCategoryCode != nil {
                //     await viewModel.applySuggestion(categoryCode: suggestedCategoryCode,
                //                                     typeCode: suggestedTypeCode)
                // }
            }
        }
        .alert("خطأ", isPresented: $showErrorAlert) {
            Button("موافق") {
                showErrorAlert = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "حدث خطأ أثناء الحجز")
        }
//        .navigationTitle("Reserve".localized())
//        .navigationBarTitleDisplayMode(.large)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
    }


  
   
       
    /// Changing a field's identity re-creates it, so it shows a value that was set from code:
    /// - national ID: after an ID scan
    /// - transaction type: cleared when the category changes
    private func fieldIdentity(_ field: FormField) -> String {
        switch field.id {
        case "customerId":
            return "customerId-\(viewModel.customerIdFieldToken)"
        case "transactionTypeCategory":
            return "transactionTypeCategory-\(viewModel.pickerRefreshToken)"
        case "transactionTypeCode":
            return "transactionTypeCode-\(viewModel.reservationRequest.transactionTypeCategory?.code ?? "none")-\(viewModel.pickerRefreshToken)"
        default:
            return field.id
        }
    }

    // MARK: - Nearby offices with free days (§4.8 B)
    @ViewBuilder
    private var alternativesSection: some View {
        switch viewModel.alternativesState {
        case .hidden:
            EmptyView()
        case .loading, .empty, .found:
            VStack(alignment: .leading, spacing: 10) {
                Label("no_available_dates".localized(), systemImage: "calendar.badge.exclamationmark")
                    .font(Font.setFontSemiBold(size: 14))
                    .foregroundColor(.red)
                alternativesContent
            }
            .padding(12)
            .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
            }
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var alternativesContent: some View {
        switch viewModel.alternativesState {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("booking_alternatives_loading".localized())
                    .font(Font.setFont(size: 13))
                    .foregroundColor(.theme.themeGray)
            }
        case .empty:
            Text("booking_alternatives_none".localized())
                .font(Font.setFont(size: 13))
                .foregroundColor(.theme.themeGray)
        case .found(let offices):
            Text("booking_alternatives_title".localized())
                .font(Font.setFontSemiBold(size: 14))
                .foregroundColor(.theme.text)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(offices) { choice in
                Button {
                    openAlternative(choice)
                } label: {
                    OfficeChoiceRow(
                        choice: choice,
                        dateText: String(format: "booking_alternatives_first_date".localized(),
                                         BookingDates.slashed(choice.firstDate))
                    )
                }
                .buttonStyle(.plain)
            }
        case .hidden:
            EmptyView()
        }
    }

    /// Opens the form for the picked office with the national ID, category and type carried over.
    private func openAlternative(_ choice: OfficeChoice) {
        let request = viewModel.reservationRequest
        let handoff = FormHandoff(
            nationalId: request.customerId,
            categoryCode: request.transactionTypeCategory?.code,
            typeCode: request.transactionType?.code
        )
        router.showScreen(.push) { _ in
            ReservationFormView(appManager: appManager, office: choice.office, handoff: handoff)
        }
    }

    // MARK: - Assistant banner
    private var assistantBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.theme.themeBlue)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text("assistant_banner_title".localized())
                    .font(Font.setFontSemiBold(size: 14))
                    .foregroundColor(.theme.text)
                if let name = assistantStore.service?.displayName, !name.isEmpty {
                    Text(name)
                        .font(Font.setFont(size: 13))
                        .foregroundColor(.theme.themeBlue)
                }
                Text("assistant_banner_hint".localized())
                    .font(Font.setFont(size: 12))
                    .foregroundColor(.theme.themeGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button {
                assistantStore.service = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.theme.themeGray)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("assistant_banner_dismiss".localized())
        }
        .padding(12)
        .background(Color.theme.themeBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.top, 12)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(viewModel.formArray, id: \.id) { field in
                DynamicFormField(field: field) { value, optionalValue in
                    viewModel.updateField(id: field.id, value: value, value2: optionalValue)
                }
                // AI-FEATURE (disabled): pickers were re-created when a suggestion set their value from code.
                // .id(field.type == .picker ? "\(field.id)-\(viewModel.formRefreshToken)" : field.id)
                .id(fieldIdentity(field))
                
                // Show validation message for customer ID
                if field.id == "customerId" {
                    ScanNationalIDButton { number in
                        viewModel.applyScannedCustomerId(number)
                    }

                    if viewModel.isValidatingCustomerId {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("validating".localized())
                                .font(Font.setFont(size: 12))
                                .foregroundColor(.gray)
                        }
                    } else if let message = viewModel.customerIdValidationMessage {
                        HStack {
                            Image(systemName: viewModel.isCustomerIdValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(viewModel.isCustomerIdValid ? .green : .red)
                            Text(message)
                                .font(Font.setFont(size: 12))
                                .foregroundColor(viewModel.isCustomerIdValid ? .green : .red)
                        }
                    }
                }
                
                // Show general validation errors
                if let error = viewModel.validationErrors[field.id] {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(Font.setFont(size: 12))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    /* AI-FEATURE (disabled): describe box, debug buttons
    // MARK: - Describe Transaction Section
    /// "اوصف معاملتك": the user writes what they want and the app picks the category + type.
    private var describeTransactionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("اوصف معاملتك وإحنا نختارلك النوع")
                .font(Font.setFontRegular(size: 14))
                .foregroundColor(.theme.text)

            TextField("مثال: توكيل لأخويا عشان يبيع العربية", text: $transactionDescription, axis: .vertical)
                .font(Font.setFontRegular(size: 14))
                .lineLimit(1...3)
                .textAlignedToReadingSide()
                .padding(12)
                .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                }

            // Full-width button with a clear label (option 1).
            Button {
                hideKeyboard()
                Task { await viewModel.suggestTransaction(from: transactionDescription) }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSuggesting {
                        ProgressView().tint(.white)
                        Text("بندوّر على المعاملة المناسبة...")
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("اختارلي نوع المعاملة")
                    }
                }
                .font(Font.setFontSemiBold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isDescribeButtonDisabled ? Color.theme.themeGray : Color.theme.themeBlue,
                            in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isDescribeButtonDisabled)

            if let message = viewModel.suggestionMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: viewModel.suggestionFound ? "sparkles" : "info.circle")
                        .foregroundColor(viewModel.suggestionFound ? .theme.themeBlue : .orange)
                    Text(message)
                        .font(Font.setFont(size: 12))
                        .foregroundColor(.theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(
                    (viewModel.suggestionFound ? Color.theme.themeBlue : Color.orange).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
        }
        .padding(.top, 12)
    }

    #if DEBUG
    /// Debug-only buttons: print the office catalog / run the test sentences to the Xcode console.
    private var debugToolsSection: some View {
        HStack(spacing: 8) {
            Button("Debug: اطبع المعاملات") {
                Task { await TransactionDebugTools.exportCatalog(office: office) }
            }
            Button("Debug: شغّل جمل التيست") {
                Task { await TransactionDebugTools.runTestSuite(office: office) }
            }
        }
        .font(Font.setFont(size: 12))
        .buttonStyle(.bordered)
        .tint(.orange)
        .padding(.top, 4)
    }
    #endif

    private var isDescribeButtonDisabled: Bool {
        viewModel.isSuggesting || transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    */

    // MARK: - Confirmation Section
    private var confirmationSection: some View {
        VStack(alignment: .leading ,spacing: 12) {
            
                Button(action: {
                    viewModel.isInputsConfirmed.toggle()
                    // Remove validation error when checked
                    if viewModel.isInputsConfirmed {
                        viewModel.validationErrors.removeValue(forKey: "confirmation")
                    }
                }) {
                    HStack(alignment: .top, spacing: 5) {
                    Image(systemName: viewModel.isInputsConfirmed ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(viewModel.isInputsConfirmed ? Color.theme.accent : .gray)
                        
                        Text("أؤكد أن جميع البيانات المدخلة صحيحة")
                            .font(Font.setFontRegular())
                            .foregroundColor(.theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
               
            
            // Show validation error for confirmation
            if let error = viewModel.validationErrors["confirmation"] {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(Font.setFont(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .frame(maxWidth: .infinity , alignment: .leading)
//        .padding(.vertical, 16)
//        .padding(.horizontal, 12)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.theme.themeBlue.opacity(0.1))
//        )
        .padding(.bottom , 20)
    }
}

// MARK: - Checklist Row Component
struct ChecklistRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color.opacity(0.7))
                .frame(width: 24)
            
            Text(text)
                .font(.setFont(size: 14))
                .foregroundColor(.theme.text.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
struct InformationRow: View {
    let icon: String
    let text: String
    let color : Color
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(Font.setFontRegular(size: 14))
                .foregroundColor(.theme.text.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#Preview {
    let appManager = AppManager()
    ReservationFormView(appManager: appManager, office: OfficeModel.preview)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
        
}
