//
//  MissionModels.swift
//  Mrasem
//
//  Mirrors Android: data/model/mrasem/MissionModels.kt
//

import Foundation

/// نوع المهمة: أهلاً بكم في قطر / مهمة رسمية بالخارج.
enum MissionMode: String, CaseIterable, Hashable {
    case inbound
    case outbound
}

/// نوع لوحة السيارة (يحدد ألوانها).
enum PlateStyle: String, CaseIterable, Hashable {
    case qatar
    case unitedKingdom
}

/// تاريخ بدون وقت — زي `LocalDate` في Kotlin (قاعدة C6).
nonisolated struct MrasemDate: Equatable, Hashable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// يقرأ تاريخ بصيغة `yyyy-MM-dd`.
    init?(iso: String) {
        let parts = iso.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// تاريخ الجهاز الحالي (بيتحقن في الـ strategies للاختبار).
    static func today(now: Date = Date()) -> MrasemDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        return MrasemDate(
            year: parts.year ?? 1970,
            month: parts.month ?? 1,
            day: parts.day ?? 1
        )
    }

    var iso: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// عدد الأيام بين `other` و `self` — موجب يعني `self` بعد `other`.
    func days(since other: MrasemDate) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!

        guard let from = calendar.date(from: DateComponents(year: other.year, month: other.month, day: other.day)),
              let to = calendar.date(from: DateComponents(year: year, month: month, day: day))
        else { return 0 }

        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    static func < (lhs: MrasemDate, rhs: MrasemDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

struct Receiver: Equatable, Hashable {
    let name: String
    let title: String
    let phone: String
    let spot: String
}

struct Car: Equatable, Hashable {
    let type: String
    let plate: String
    let driver: String
    let country: String
    let plateStyle: PlateStyle
}

struct Coordinator: Equatable, Hashable {
    let name: String
    let phone: String
}

struct Venue: Equatable, Hashable {
    let building: String
    let area: String
    let entrance: String
    let floor: String
    let hall: String
    let parking: String
    let lat: Double
    let lng: Double
    /// النص المكتوب على مبنى الملتقى في الخريطة.
    let mapLabel: String
}

struct Hotel: Equatable, Hashable {
    let name: String
    let area: String
    let room: String
    let breakfast: String
    let drive: String
}

struct EmergencyContact: Equatable, Hashable {
    let label: String
    let value: String
}

/// فقرة في البرنامج اليومي.
enum ProgramItem: Equatable, Hashable {
    /// فقرة رسمية. `time` بصيغة HH:mm. `isKey` = الفقرة الرئيسية (عليها بطاقة الـ ٣٠ ثانية).
    case official(Official)
    /// وقت حر من `from` إلى `to` مدته `hours` ساعة.
    case freeTime(FreeTime)

    struct Official: Equatable, Hashable {
        let time: String
        let title: String
        /// مكان الفقرة (في Android اسمه `where` — كلمة محجوزة في Swift).
        let place: String
        let note: String?
        let isKey: Bool

        init(time: String, title: String, place: String, note: String? = nil, isKey: Bool = false) {
            self.time = time
            self.title = title
            self.place = place
            self.note = note
            self.isKey = isKey
        }
    }

    struct FreeTime: Equatable, Hashable {
        let from: String
        let to: String
        let hours: Double
    }

    var official: Official? {
        if case let .official(item) = self { return item }
        return nil
    }

    var freeTime: FreeTime? {
        if case let .freeTime(item) = self { return item }
        return nil
    }
}

struct ProgramDay: Equatable, Hashable {
    let label: String
    let items: [ProgramItem]
}

struct ServiceApp: Equatable, Hashable {
    let name: String
    let nameEn: String
    /// لون الشعار ARGB (من البيانات).
    let color: UInt32
    let description: String
    let url: String
}

struct ServiceCategory: Equatable, Hashable {
    let name: String
    let apps: [ServiceApp]
}

struct QuickInfo: Equatable, Hashable {
    let label: String
    let value: String
}

struct Place: Equatable, Hashable {
    let name: String
    let description: String
    /// زمن الوصول بالسيارة من الفندق بالدقائق.
    let minutes: Int
    /// مدة الزيارة بالساعات.
    let durationHours: Double
    let tag: String
}

/// بيانات بطاقة الـ ٣٠ ثانية.
struct NextMeeting: Equatable, Hashable {
    let who: String
    let address: String
    let seat: String
    let gift: String
    let language: String
}

/// كل بيانات مهمة واحدة (وضع واحد).
struct Mission: Equatable, Hashable {
    let mode: MissionMode
    let guest: String
    let country: String
    let dest: String
    let host: String
    let start: MrasemDate
    let end: MrasemDate
    let timeZone: String
    let currency: String
    let weather: String
    let receiver: Receiver
    let car: Car
    let coordinator: Coordinator
    let venue: Venue
    let hotel: Hotel
    let emergency: [EmergencyContact]
    let days: [ProgramDay]
    let services: [ServiceCategory]
    let quickInfo: [QuickInfo]
    let places: [Place]
    let customs: [String]
    let nextMeeting: NextMeeting
}
