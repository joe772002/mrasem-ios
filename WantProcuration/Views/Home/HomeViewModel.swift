//
//  HomeViewModel.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import Combine
import SwiftUI


class HomeViewModel : ObservableObject {
    let categories: [ServiceCategory] = [
        ServiceCategory(
            categoryName: .capacity,
            subtitle: "إجراء معاملتك اليوم",
            icon: "building.columns",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeBlue, Color.theme.themeBlue.opacity(0.7)]
        ),
        ServiceCategory(
            categoryName: .reserve,
            subtitle: "إتمام معاملتك في أيام تالية",
            icon: "calendar.badge.clock",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeGreen, Color.theme.themeBlue.opacity(0.7)]
        ),
        ServiceCategory(
            categoryName: .templates,
            subtitle: "تصفح وتحميل النماذج",
            icon: "doc.text",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeGreen, Color.theme.themeBlue.opacity(0.7)]
        ),
        ServiceCategory(
            categoryName: .electronicTawseek,
            subtitle: "بوابة مصر الرقمية",
            icon: "signature",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeBlue.opacity(0.5), Color(red: 72/255, green: 187/255, blue: 120/255)]
        ),
        ServiceCategory(
            categoryName: .inquire,
            subtitle: "تتبع حجوزاتك",
            icon: "magnifyingglass",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeBlue.opacity(0.5), Color(red: 59/255, green: 130/255, blue: 246/255)]
        ),
        ServiceCategory(
            categoryName: .faq,
            subtitle: "service_faq_desc".localized(),
            icon: "questionmark.circle",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeBlue.opacity(0.5), Color.theme.themeBlue.opacity(0.7)]
        ),
        ServiceCategory(
            categoryName: .others,
            subtitle: "المزيد من الخدمات",
            icon: "square.grid.2x2",
            accentColor: .theme.themeBlue,
            gradient: [Color.theme.themeBlue.opacity(0.5), Color(red: 168/255, green: 85/255, blue: 247/255)]
        )
    ]
    
    
        
}


// MARK: - Service Category Model
struct ServiceCategory: Identifiable {
    let id = UUID()
    let categoryName: ServiceCategoryName
    var title: String {
        return categoryName.title
    }
    let subtitle: String
    let icon: String
    let accentColor: Color
    let gradient: [Color]
}

enum ServiceCategoryName: String, Codable, CaseIterable {
    case capacity
    case reserve
    case templates
    case inquire
    case electronicTawseek
    case others
    case assistant
    case faq
    
    var title: String {
        switch self {
        case .capacity: return "Capacity".localized()
        case .reserve: return "Reserve".localized()
        case .templates: return "Templates".localized()
        case .electronicTawseek: return "electronicTawseek".localized()
        case .inquire: return "InquireReserve".localized()
        case .others: return "Others".localized()
        case .assistant: return "service_assistant".localized()
        case .faq: return "service_faq".localized()
        }
    }
}
