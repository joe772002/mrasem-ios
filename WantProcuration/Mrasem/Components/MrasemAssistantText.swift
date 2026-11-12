//
//  MrasemAssistantText.swift
//  Mrasem
//
//  Mirrors Android: ui/screens/assistant/AssistantScreen.kt (assistantReplyText)
//

import Foundation

/// نص رد المساعد النهائي من الـ catalog (قاعدة C1).
nonisolated func mrasemAssistantReplyText(_ reply: AssistantReply) -> String {
    switch reply {
    case let .welcome(city):
        return mrasemString("mrasem_assistant_welcome", [city])
    case let .dress(dress):
        let key = dress == .bisht ? "mrasem_assistant_reply_dress_bisht" : "mrasem_assistant_reply_dress_formal"
        return mrasemString("mrasem_assistant_reply_dress", [mrasemString(key)])
    case let .nextItem(title, dayLabel, time, place):
        return mrasemString("mrasem_assistant_reply_next_item", [title, dayLabel, time, place])
    case let .carInfo(type, plate, driver):
        return mrasemString("mrasem_assistant_reply_car", [type, plate, driver])
    case let .hotelInfo(name, area, room, drive):
        return mrasemString("mrasem_assistant_reply_hotel", [name, area, room, drive])
    case let .food(apps):
        return mrasemString("mrasem_assistant_reply_food", [apps.joined(separator: "، ")])
    case let .taxi(apps):
        return mrasemString("mrasem_assistant_reply_taxi", [apps.joined(separator: "، ")])
    case let .nearbyPlaces(places):
        return mrasemString("mrasem_assistant_reply_places", [places.joined(separator: "، ")])
    case let .emergency(number, name, phone):
        return mrasemString("mrasem_assistant_reply_emergency", [number, name, phone])
    case .forwarded:
        return mrasemString("mrasem_assistant_reply_forwarded")
    }
}
