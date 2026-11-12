
// MARK: - Preview Data for SwiftUI Canvas
import SwiftUI

extension OfficeModel {
    static let preview = OfficeModel(
        activeFlag: 1, QMeEnable: 0,
        address: "شارع التحرير، القاهرة",
        cnt: 25,
        empNum: 8,
        fromTime: "16:00",
        govDesc: "محافظة القاهرة",
        isopened: 1,
        latitude: "30.0444",
        longtiude: "31.2357",
        notServicedAm: 2,
        notServicedPm: 1,
        notServicedYet: 3,
        orgDesc: "مكتب شهر عقاري القاهرة الرئيسي",
        orgType: 1,
        orgTypeDesc: "فرع خدمة مميزة",
        orgUnitID: "12345",
        orgUnitName: " فرع مميز للتوثيقات الادارية القاهرة الرئيسية",
        pluscodes: "8G2H+XQ القاهرة، مصر",
        prcCntPerDay: "150",
        queuingFlag: "Y",
        ticketEnabled: "Y",
        toTime: "16:00",
        windowsNo: .null
    )
    
    static let previewList: [OfficeModel] = [
        OfficeModel(
            activeFlag: 1, QMeEnable: 0,
            address: "ميدان الجيزة، الجيزة",
            cnt: 30,
            empNum: 10,
            fromTime: "16:00",
            govDesc: "محافظة الجيزة",
            isopened: 1,
            latitude: "30.0131",
            longtiude: "31.2089",
            notServicedAm: 4,
            notServicedPm: 3,
            notServicedYet: 5,
            orgDesc: "مكتب توثيق الجيزة العام",
            orgType: 2,
            orgTypeDesc: "فرع مميكن",
            orgUnitID: "67890",
            orgUnitName: "الجيزة العام",
            pluscodes: "7G7V+F5 الجيزة، مصر",
            prcCntPerDay: "200",
            queuingFlag: "N",
            ticketEnabled: "Y",
            toTime: "16:00",
            windowsNo: .null
        ),
        OfficeModel.preview
    ]
}

extension OfficeResponse {
    static let preview = OfficeResponse(
        orgUnitStatusRes: OrgUnitStatusRes(
            orgUnitStatusData: OfficeModel.previewList,
            responseDesc: "Success",
            responseStatus: "200"
        )
    )
}
import Foundation

// MARK: - Preview Data

extension OfficeAgendaResponse {
    static let preview: OfficeAgendaResponse = OfficeAgendaResponse(
        type: "officeAgendaResponse",
        responseStatus: "200",
        responseStatusDesc: "تم العرض بنجاح",
        channelRequestId: "1",
        correlationId: "1",
        officeAgendaData: OfficeAgendaData(
            reservationDate: [
                ReservationDate(
                    dateReserved: "2025-11-20",
                    reservePeriods: [
                        ReservePeriod(timePeriod: "الفترة الاولى (9:00 الى 11:30)", timePeriodCode: "1"),
                        ReservePeriod(timePeriod: "الفترة الثانية (11:30 الى 13:30)", timePeriodCode: "2")
                    ],
                    reservationTime: nil
                ),
                ReservationDate(
                    dateReserved: "2025-11-27",
                    reservePeriods: nil,
                    reservationTime: [
                        ReservationTime(reserveTime: "03:30 PM"),
                        ReservationTime(reserveTime: "05:00 PM")
                    ]
                )
            ]
        ),
        originatingChannel: 1,
        originatingUserIdentifier: "1",
        originatingUserType: 1,
        vipFlag: "4"
    )
}

extension ReservationRequest {
    static let preview: ReservationRequest = {
        let request = ReservationRequest()
        request.customerIdType = "1"
        request.customerId = "98765432109876"
        request.orgUnitId = "15"
        request.transactionTypeCategory = TransactionCategory(code: "CAT01", desc: "معاملات")
        request.transactionType = TransactionType(code: "TRX05", desc: "تجديد بطاقة")
        request.reservationDay = ReservationDate(
            dateReserved: "2025-11-23",
            reservePeriods: [
                ReservePeriod(timePeriod: "الفترة الاولى (9:00 الى 11:30)", timePeriodCode: "1")
            ],
            reservationTime: nil
        )
        request.reservationPeriod = ReservePeriod(timePeriod: "الفترة الاولى (9:00 الى 11:30)", timePeriodCode: "1")
        request.reservationTime = ReservationTime(reserveTime: "09:30 AM")
        request.requestQueVIPId = "4"
        request.mobileNum = "01012345678"
        request.reservationSlot = "23-11-2025 09:30 AM"
        request.period = 1
        return request
    }()
}

extension TransactionCategory {
    static let preview = TransactionCategory(code: "CAT01", desc: "معاملات")
}

extension TransactionType {
    static let preview = TransactionType(code: "TRX05", desc: "تجديد بطاقة")
}

extension ReservationDate {
    static let preview = ReservationDate(
        dateReserved: "2025-11-23",
        reservePeriods: [
            ReservePeriod(timePeriod: "الفترة الاولى (9:00 الى 11:30)", timePeriodCode: "1"),
            ReservePeriod(timePeriod: "الفترة الثانية (11:30 الى 13:30)", timePeriodCode: "2")
        ],
        reservationTime: nil
    )
}

extension ReservePeriod {
    static let preview = ReservePeriod(timePeriod: "الفترة الاولى (9:00 الى 11:30)", timePeriodCode: "1")
}

extension ReservationTime {
    static let preview = ReservationTime(reserveTime: "09:30 AM")
}
extension AttendanceResponse {
    static let preview: AttendanceResponse = AttendanceResponse(
        actualTimeToAttend: "10:36:49",
        attendedNo: 1,
        statusCode: "200",
        statusDesc: "Process done successfully",
        ticketNo: "1"
    )
}

// MARK: - Preview Data
extension ServiceCategory {
    static let previewData: [ServiceCategory] = [
        ServiceCategory(
            categoryName: .capacity,
            subtitle: "Check available appointment capacity",
            icon: "gauge",
            accentColor: .blue,
            gradient: [Color.blue.opacity(0.8), Color.cyan]
        ),
        ServiceCategory(
            categoryName: .reserve,
            subtitle: "Book or manage reservations",
            icon: "calendar.badge.plus",
            accentColor: .green,
            gradient: [Color.green.opacity(0.8), Color.teal]
        ),
        ServiceCategory(
            categoryName: .templates,
            subtitle: "Access saved templates",
            icon: "doc.on.doc",
            accentColor: .purple,
            gradient: [Color.purple.opacity(0.8), Color.indigo]
        ),
        ServiceCategory(
            categoryName: .inquire,
            subtitle: "Track your reservations",
            icon: "magnifyingglass.circle.fill",
            accentColor: .orange,
            gradient: [Color.orange.opacity(0.8), Color.yellow]
        ),
        ServiceCategory(
            categoryName: .electronicTawseek,
            subtitle: "Electronic Tawseek services",
            icon: "network",
            accentColor: .pink,
            gradient: [Color.pink.opacity(0.8), Color.red]
        ),
        ServiceCategory(
            categoryName: .others,
            subtitle: "Other available services",
            icon: "ellipsis.circle",
            accentColor: .gray,
            gradient: [Color.gray.opacity(0.8), Color.black.opacity(0.6)]
        )
    ]
}
