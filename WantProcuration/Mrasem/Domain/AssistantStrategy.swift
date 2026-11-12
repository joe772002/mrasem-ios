//
//  AssistantStrategy.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/AssistantStrategy.kt
//

import Foundation

/// المساعد التوضيحي: قواعد كلمات مفتاحية بالترتيب، أول تطابق يكسب (01-DESIGN-SPEC §7.6).
nonisolated final class AssistantStrategy {
    private let repository: MissionRepository

    init(repository: MissionRepository) {
        self.repository = repository
    }

    /// رسالة الترحيب ثم المحادثة.
    func conversation(state: MrasemState? = nil) -> [ChatMessage] {
        let state = state ?? repository.state
        return [.bot(Self.welcome(state.mission))] + state.chat
    }

    /// يسأل المساعد. السؤال الفاضي يتجاهل. لو مفيش إجابة، يتعمل طلب «سؤال» للمنسق.
    func ask(_ question: String) -> AssistantReply? {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let state = repository.state
        let reply = Self.reply(trimmed, mission: state.mission, dress: state.dress)

        if case .forwarded = reply {
            repository.addRequest(mode: state.mode, kind: .question, place: nil, text: trimmed)
        }

        repository.appendChat([.user(trimmed), .bot(reply)])
        return reply
    }

    /// ترتيب الفقرة الرسمية اللي بيرد بيها سؤال «موعد» في الترتيب العام (كما في المصدر).
    private static let nextItemIndex = 4
    private static let nearbyCount = 3

    private static let dressPattern = "لبس|ألبس|زي|بشت|بدلة"
    private static let schedulePattern = "موعد|اجتماع|لقاء|برنامج"
    private static let carPattern = "سيار|سائق"
    private static let hotelPattern = "فندق|غرفة"
    private static let foodPattern = "طعام|أكل|توصيل|جوع"
    private static let taxiPattern = "تاكسي|أجرة|مواصلات"
    private static let placesPattern = "سياح|أماكن|زيارة|قريب"
    private static let emergencyPattern = "طوارئ|إسعاف|مستشفى"

    static func welcome(_ mission: Mission) -> AssistantReply {
        let city = mission.dest
            .components(separatedBy: "،")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? mission.dest
        return .welcome(city: city)
    }

    static func reply(_ question: String, mission: Mission, dress: DressCode) -> AssistantReply {
        if matches(question, dressPattern) {
            return .dress(dress)
        }
        if matches(question, schedulePattern) {
            return nextItem(mission)
        }
        if matches(question, carPattern) {
            return .carInfo(type: mission.car.type, plate: mission.car.plate, driver: mission.car.driver)
        }
        if matches(question, hotelPattern) {
            return .hotelInfo(
                name: mission.hotel.name,
                area: mission.hotel.area,
                room: mission.hotel.room,
                drive: mission.hotel.drive
            )
        }
        if matches(question, foodPattern) {
            let apps = mission.services.indices.contains(0) ? mission.services[0].apps.map(\.name) : []
            return .food(apps)
        }
        if matches(question, taxiPattern) {
            let apps = mission.services.indices.contains(1) ? mission.services[1].apps.map(\.name) : []
            return .taxi(apps)
        }
        if matches(question, placesPattern) {
            let nearby = mission.places
                .sorted { $0.minutes < $1.minutes }
                .prefix(nearbyCount)
                .map(\.name)
            return .nearbyPlaces(nearby)
        }
        if matches(question, emergencyPattern) {
            return .emergency(
                number: mission.emergency.first?.value ?? "",
                coordinatorName: mission.coordinator.name,
                coordinatorPhone: mission.coordinator.phone
            )
        }
        return .forwarded
    }

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func nextItem(_ mission: Mission) -> AssistantReply {
        let officials = mission.days.flatMap { day -> [(String, ProgramItem.Official)] in
            day.items.compactMap { item in
                item.official.map { (day.label, $0) }
            }
        }

        let picked: (String, ProgramItem.Official)
        if officials.indices.contains(nextItemIndex) {
            picked = officials[nextItemIndex]
        } else if let first = officials.first {
            picked = first
        } else {
            return .forwarded
        }

        return .nextItem(
            title: picked.1.title,
            dayLabel: picked.0,
            time: picked.1.time,
            place: picked.1.place
        )
    }
}
