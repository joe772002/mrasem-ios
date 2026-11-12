//
//  BookingInquiryView.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 28/10/2025.
//


import SwiftUI
import SwiftfulUI
import SwiftfulRouting
struct ReservationInquiryView: View {
    @Environment(\.router) private var router
    @State private var showResults = false
    @ObservedObject var appManager: AppManager
    @StateObject private var viewModel = ReservationInquiryViewModel()
    
    var body: some View {
        ZStack {
            
           
            
            HomeBackground()
                .ignoresSafeArea()
            
            
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading ,spacing: 24) {
                    headerSection
                    headerCard
                    searchSection
                    
                    if showResults {
                        resultsSection
                    }
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .environment(\.locale, appManager.locale)
            .environment(\.layoutDirection, appManager.layoutDirection)
        }
       
       
    }
    
    
    // MARK: - Sections
    private var headerSection: some View {
        
        VStack(alignment: .leading, spacing: 16) {
          
            Text("إستعلام عن الحجز")
                .font(.setFontBold(size: 26))
                .foregroundColor(.theme.text)
            
        }
        
    }
    
    private var headerCard : some View {
        HStack(spacing : 12){
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.theme.text)
            VStack(alignment: .leading) {
                
                Text("استعلام سريع")
                    .font(.setFontBold(size: 17))
                    .foregroundColor(.theme.text)
                
                Text("أدخل رقمك القومي لعرض جميع حجوزاتك")
                    .font(.setFont(size: 14))
                    .foregroundColor(.theme.themeGray)
                    .multilineTextAlignment(.trailing)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.white1.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.themeBlue.opacity(0.3), lineWidth: 1)
                )
        )
        
        .padding(.top, 8)
        
        
        
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 16) {
            Text("customerId".localized())
                .font(.setFontSemiBold())
                .foregroundColor(.theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            textField
            
            inquireButton
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.white1.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.themeBlue.opacity(0.3), lineWidth: 1)
                )
        )
        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var textField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("enterCustomerId".localized(), text: $viewModel.customerId)
                .font(.setFont())
                .multilineTextAlignment(.center)
                .padding(10)
                .background(Color.theme.white1)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
                .keyboardType(.numberPad)
                .onChange(of: viewModel.customerId) { newValue in
                    // Limit to 14 digits
                    if newValue.count > 14 {
                        viewModel.customerId = String(newValue.prefix(14))
                    }
                }

            ScanNationalIDButton { number in
                viewModel.customerId = number
            }
            
            // Validation feedback
            if viewModel.customerId.count == 14 {
                if viewModel.isValidCustomerId == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("validCustomerId".localized())
                            .font(.setFontRegular(size: 12))
                            .foregroundColor(.green)
                    }
                } else if viewModel.isValidCustomerId == false {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(viewModel.errorMessage ?? "invalidCustomerId".localized())
                            .font(.setFontRegular(size: 12))
                            .foregroundColor(.red)
                    }
                } else {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("validating".localized())
                            .font(.setFontRegular(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private var borderColor: Color {
//        if viewModel.customerId.count == 14 {
//            if viewModel.isValidCustomerId == true {
//                return .green
//            } else if viewModel.isValidCustomerId == false {
//                return .red
//            }
//        }
        return Color.theme.themeGray.opacity(0.2)
    }

    private var inquireButton: some View {
        HStack(spacing: 8) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.theme.white1))
            }
            Text("inquire".localized())
                .font(Font.setFontRegular())
        }
        .foregroundColor(Color.theme.white1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(buttonBackgroundColor)
        .cornerRadius(12)
        .disabled(isButtonDisabled)
        .asButton {
            hideKeyboard()
            Task {
                showResults = await viewModel.fetchInquireData()
            }
        }
    }

    private var isButtonDisabled: Bool {
        viewModel.isLoading || viewModel.customerId.count != 14 || viewModel.isValidCustomerId != true
    }

    private var buttonBackgroundColor: Color {
        if isButtonDisabled {
            return Color.theme.themeGray
        }
        return Color.theme.themeBlue
    }
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(spacing: 16) {
            Text("لديك \(viewModel.inquireReserves.count) حجوزات")
                .font(.setFontSemiBold(size: 20))
                .foregroundColor(.theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            // Bookings List
            VStack(spacing: 16) {
                // Your booking cards here
                
                ForEach(viewModel.inquireReserves, id: \.id) { booking in
                    BookingCard(
                        title: booking.orgName,
                        details: [
                            (booking.transactionTypeDesc, ""),
                            (booking.transactionDesc, ""),
                            (booking.timeRangePreview, booking.datePreview)
                        ],
                        isVIP: false
                    )
                }
            }
        }
    }
}
struct BookingCard: View {
    let title: String
    let details: [(String, String)]
    let isVIP: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(.setFontBold(size: 16))
                    .foregroundColor(Color.theme.themeBlue)
                Spacer()
                if isVIP {
                    ZStack {
                        Circle()
                            .fill(Color.theme.themeBlue)
                            .frame(width: 32, height: 32)
                        
                        Text("premuim".localized())
                            .font(.setFont(size: 14))
                            .foregroundColor(Color.theme.white1)
                    }
                }
                
                
                
                
            }
            
            // Details
            VStack(spacing: 8) {
                ForEach(details.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 13))
                                .foregroundColor(Color.theme.themeBlue)
                            Text(details[index].0)
                                .font(.setFontRegular(size: 14))
                                .foregroundColor(.theme.secondaryText)
                            
                            
                        }
                        Spacer()
                        if !details[index].1.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.theme.themeBlue)
                                Text(details[index].1)
                                    .font(.setFontRegular(size: 14))
                                    .foregroundColor(.theme.secondaryText)
                                
                                
                            }
                        }
                        
                        
                        
                        
                    }
                }
            }
        }
        .padding(20)
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}


#Preview {
    let appManager = AppManager()
    ReservationInquiryView(appManager: appManager)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
}
