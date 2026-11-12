//
//  OfficeCard.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI

// MARK: - Office Card
/// Same layout idea as the Home service cards: small tinted icon tile, name + status, one-line
/// details, compact distance and a chevron, on a plain card with a light border.
struct OfficeCard: View {
    let office: OfficeModel
    @ObservedObject var appManager: AppManager

    private var tint: Color { office.isSpecial ? .theme.gold : .theme.themeBlue }

    /// "2.4", "38", "1,250": one decimal only for short distances.
    private var distanceText: String {
        let km = office.distance
        if km < 10 { return String(format: "%.1f", km) }
        return Int(km.rounded()).formatted()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon tile
            Image(systemName: office.isSpecial ? "star.fill" : "building.columns")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(office.orgUnitName)
                    .font(Font.setFontBold(size: 16))
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let isOpen = office.isOpenNow {
                        OfficeOpenBadge(isOpen: isOpen)
                    }
                    Text(office.orgTypeDesc)
                        .font(Font.setFontRegular(size: 13))
                        .foregroundColor(tint)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.theme.themeGray)
                    Text(office.address)
                        .font(Font.setFontRegular(size: 13))
                        .foregroundColor(.theme.themeGray)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Distance + chevron
            // Pill at the top (with the name), arrow at the bottom (with the address line).
            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(distanceText)
                        .font(Font.setFontBold(size: 15))
                        .foregroundColor(.theme.themeBlue)
                    Text("km_unit".localized())
                        .font(Font.setFontRegular(size: 12))
                        .foregroundColor(.theme.themeGray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.theme.themeBlue.opacity(0.07), in: Capsule())

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.theme.themeGray.opacity(0.6))
                    .padding(.bottom, 2)
            }
            .frame(maxHeight: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Open / closed badge
/// Small pill: green "مفتوح الآن" or gray "مغلق الآن", from the office working hours.
struct OfficeOpenBadge: View {
    let isOpen: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isOpen ? Color.green : Color.theme.themeGray)
                .frame(width: 7, height: 7)
            Text((isOpen ? "office_open_now" : "office_closed_now").localized())
                .font(.setFontRegular(size: 12))
                .foregroundColor(isOpen ? Color.green : Color.theme.themeGray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((isOpen ? Color.green : Color.theme.themeGray).opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Office Card (Top Premium Style)
struct OfficeSimplifiedCard: View {
    let office: OfficeModel
    @ObservedObject var appManager: AppManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section with Gradient
            VStack(spacing: 0) {
             
                // Office Name
                Text(office.orgUnitName)
                    .font(.setFontSemiBold(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Office Type
                Text(office.orgTypeDesc)
                    .font(.setFont(size: 14))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .background(
                Color.theme.darkBlue
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        .theme.darkBlue,
//                        .theme.darkBlue.opacity(0.8)
//                    ]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
            )
            .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
//        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        informationCard.offset(x: 0,y: -8)
            .frame(maxWidth: .infinity)
        
        
    }
    
    // MARK: - Information Card (Bottom Checklist Style)
    private var informationCard: some View {
        VStack(spacing: 0) {
            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.theme.themeBlue)
                    
                    Text("معلومات هامة")
                        .font(Font.setFontBold())
                        .foregroundColor(.theme.text)
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    ChecklistRow(
                        icon: "checkmark.circle",
                        text: "الرقم القومي يجب أن يكون 14 رقماً",
                        color: .theme.themeBlue
                    )
                    
                    ChecklistRow(
                        icon: "checkmark.circle",
                        text: "لن تتمكن من تعديل الحجز بعد الإرسال",
                        color: .theme.themeBlue
                    )
                }
            }
            .padding(20)
        }
        .background(
            Color.theme.cardBackground
                .clipShape(RoundedCorner(radius: 16, corners: [.bottomLeft, .bottomRight]))
        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(office.officeColor.opacity(0.2), lineWidth: 1.5)
//                .clipShape(RoundedCorner(radius: 16, corners: [.bottomLeft, .bottomRight]))
//        )
//        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}
#Preview {
    let appManager = AppManager()
    OfficeCard(office: OfficeModel.preview, appManager: appManager)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
    
}


