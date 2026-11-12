//
//  Fonts.swift
//  mojEgypt
//
//  Created by Ebtahal on 06/06/2024.
//

import SwiftUI
@objc enum FontSizeWeight : Int {
    case small
    case meduim
    case large
    case extraLarge
}
extension Font {

    /// Large phones (Pro Max / Plus, screen width ≥ 428 pt) get slightly bigger text; every other iPhone keeps
    /// the sizes it has today. Change `largePhoneScale` to tune it.
    static let largePhoneScale: CGFloat = 1.12
    private static var cachedDeviceScale: CGFloat?

    static var deviceScale: CGFloat {
        if let cachedDeviceScale { return cachedDeviceScale }
        let screen = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen }
            .first
        guard let bounds = screen?.bounds else { return 1 }   // no scene yet: try again next time
        let scale: CGFloat = min(bounds.width, bounds.height) >= 428 ? largePhoneScale : 1
        cachedDeviceScale = scale
        return scale
    }

    static func getUserPreferredFontSize(size : CGFloat) -> CGFloat{
        let defaults = UserDefaults.standard
        let fontSize = FontSizeWeight(rawValue: defaults.integer(forKey: "fontSize")) ?? .meduim
        var userFontSize = size * deviceScale
        switch (fontSize){
        case .small:
            userFontSize -= 2
            return userFontSize
        case .meduim:
            return userFontSize
        case .large:
            userFontSize += 4
            return userFontSize
        case .extraLarge:
            userFontSize += 6
            return userFontSize
        }
    }
   
    static func setFont (size : CGFloat? = nil) -> Font{
        return .custom("Cairo", size: (size ?? 16) * deviceScale)
    }
   
    static func setFontRegular (size : CGFloat? = nil) -> Font{
        return .custom("Cairo-Regular", size: Font.getUserPreferredFontSize(size: size ?? 16) )
    }
    
    static func setFontBold (size : CGFloat? = nil) -> Font{
        return .custom("Cairo-Bold", size: Font.getUserPreferredFontSize(size: size ?? 16))
    }
    
    static func setFontSemiBold (size : CGFloat? = nil) -> Font{
        return .custom("Cairo-SemiBold", size: Font.getUserPreferredFontSize(size: size ?? 16))
    }
    static func setFontLight (size : CGFloat? = nil) -> Font{
        return .custom("Cairo-Light", size: Font.getUserPreferredFontSize(size: size ?? 16))
    }
    
    
}
