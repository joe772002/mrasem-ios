//
//  BookingDetailsView.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 28/10/2025.
//


import SwiftUI
import SwiftfulRouting
import SwiftfulUI

struct ReservationDetailsView: View {
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    let office : OfficeModel
    let reservationRequest : ReservationRequest
    /// The server's answer to the reservation (nil fields are simply not shown).
    let attendance : AttendanceResponse?
    let shouldShowReservationTime : Bool

    /// The time the user actually picked: exact time (VIP offices) or period (regular offices).
    private var appointmentText: String {
        let picked = shouldShowReservationTime
            ? reservationRequest.reservationTime?.reserveTime
            : reservationRequest.reservationPeriod?.timePeriod
        return picked.map(TimeDisplay.twelveHour) ?? "-"
    }
    var body: some View {
        
        ZStack {
            HomeBackground()
                .edgesIgnoringSafeArea(.all)
            
            
            ScrollView{
                VStack(spacing: 20) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.green, radius: 3, x: 0, y: 3)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 16)
                    
                    // Success Message
                    VStack(spacing: 6) {
                        Text("تم تأكيد الحجز بنجاح!")
                            .font(.setFontBold(size: 22))
                            .foregroundColor(.primary)
                    }
                    
                    // Details Card
                    VStack(spacing: 0) {
                        // Row 1: Branch Name and Date
                        DetailItem(
                            label: "customerId".localized(),
                            value: reservationRequest.customerId
                        )
                        Divider()
                        DetailItem(
                            label: "إسم فرع التوثيق",
                            value: office.orgUnitName
                        )
                        Divider()
                        
                        if let attendedNo = attendance?.attendedNo {
                            DetailItem(
                                label: "عدد الحاضرين",
                                value: "\(attendedNo)"
                            )
                            Divider()
                        }
                        if let ticketNo = attendance?.ticketNo, !ticketNo.isEmpty {
                            DetailItem(
                                label: "رقم التذكرة",
                                value: ticketNo
                            )
                            Divider()
                        }
                        DetailItem(
                            label: "تاريخ الحجز",
                            value: reservationRequest.reservationDay?.dateReserved ?? ""
                        )
                        
                        Divider()
                        
                        DetailItem(
                            label: "ميعاد الحجز",
                            value: appointmentText
                        )
                        if let attendTime = attendance?.actualTimeToAttend, !attendTime.isEmpty {
                            Divider()
                            DetailItem(
                                label: "موعد الحضور",
                                value: TimeDisplay.twelveHour(attendTime)
                            )
                        }
                        
                        
                        
                        
                    }
                    .padding(16)
                    .background(Color.theme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    
                    // Terms Section
                    VStack(alignment: .leading, spacing: 10) {
                        TermsItem(text: "فى حالة عدم الحضور فى بداية الموعد المحدد يلغى الحجز")
                        TermsItem(text: "يشترط أن يكون الحاضر أحد اطراف المعاملة معاه ما يدل ذلك يلغى الحجز")
                        TermsItem(text: "يرجى العلم أن يمكنك الإستعلام عن حجوزاتك الآن")
                        TermsItem(text: "يجب العلم أن إخبار الحجز مع عدم الحضور أو الإلغاء سوف يعرضك للحجب من الحجز لفترة")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.lightBlue)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    HStack(spacing: 8) {
                        
                        Text("ok".localized())
                            .font(Font.setFontRegular())
                    }
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.theme.themeBlue)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .asButton {
                        router.dismissAllScreens()
                    }
                }
                
                
            }
            .environment(\.locale, appManager.locale)
            .environment(\.layoutDirection, appManager.layoutDirection)
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.setFontRegular(size: 13))
                .foregroundColor(.theme.secondaryText2)
                .frame(width: 100, alignment: .leading) // Fixed width for alignment
            
            Text(value)
                .font(.setFontSemiBold(size: 15))
                .foregroundColor(.theme.text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}

struct TermsItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.theme.themeBlue)
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            
            Text(text)
                .font(.setFont(size: 13))
                .foregroundColor(.theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


#Preview {
    let appManager = AppManager()
    ReservationDetailsView(appManager: appManager , office: OfficeModel.preview, reservationRequest: ReservationRequest.preview , attendance: nil, shouldShowReservationTime : true)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
}
