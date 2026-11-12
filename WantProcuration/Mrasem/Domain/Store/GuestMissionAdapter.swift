//
//  GuestMissionAdapter.swift
//  Mrasem
//
//  Phase 12 — يبني `Mission` (موديل شاشات الضيف الحالية، Phases 4–6) من القاعدة لعضو معيّن،
//  عشان الشاشات تشتغل على البيانات الحقيقية في Phase 13 من غير ما تتكتب من الأول.
//  أي بيانات ناقصة بتطلع نص فاضي (قاعدة G5) — مفيش crash.
//

import Foundation

/// كل اللي شاشات الضيف محتاجاه لعضو.
struct GuestContext: Equatable {
    let member: MemberRecord
    let delegation: DelegationRecord
    let mission: Mission
    let dress: DressCode
    let dressSet: DressSet
    let checklist: [String]
    let checked: Set<Int>
    let guides: [String]
    /// ٠…٤ من حالة رحلة أول فقرة (الوصول).
    let arrivalStage: Int
    /// معرّف الفقرة المقابلة لكل (يوم، ترتيب) في `mission.days` — للتأجيل و«محدَّث».
    let itemIds: [[String]]
}

nonisolated enum GuestMissionAdapter {

    static func context(_ db: MrasemDatabase, memberId: String) -> GuestContext? {
        guard let member = db.member(memberId), let delegation = db.delegation(member.delegationId) else { return nil }
        let destination = db.destination(delegation.destinationId)
        let (days, itemIds) = programDays(db, delegation: delegation)
        let set = destination?.dressSets.first { $0.code == delegation.dress }

        return GuestContext(
            member: member,
            delegation: delegation,
            mission: mission(db, delegation: delegation, member: member, days: days),
            dress: delegation.dress,
            dressSet: DressSet(title: set?.title ?? "", men: set?.men ?? [], women: set?.women ?? []),
            checklist: destination?.checklist ?? [],
            checked: Set(db.checklists.first { $0.id == memberId }?.checked ?? []),
            guides: destination?.guides ?? [],
            arrivalStage: arrivalStage(db, delegationId: delegation.id),
            itemIds: itemIds
        )
    }

    static func mission(_ db: MrasemDatabase, delegation: DelegationRecord, member: MemberRecord?, days: [ProgramDay]? = nil) -> Mission {
        let destination = db.destination(delegation.destinationId)
        let head = DelegationService.head(of: delegation.id, in: db)
        let anchor = member ?? head
        let escort = db.escort(anchor?.escortId ?? head?.escortId)
        let car = db.car(anchor?.carId ?? head?.carId)
        let coordinator = delegation.coordinatorIds.lazy.compactMap { db.teamUser($0) }.first
        let venue = db.place(delegation.venueId)
        let hotel = db.place(delegation.hotelId)
        let meeting = delegation.nextMeeting

        return Mission(
            mode: delegation.mode,
            guest: delegation.name,
            country: delegation.countryLabel,
            dest: destination?.name ?? "",
            host: delegation.host,
            start: MrasemDate(iso: delegation.start) ?? MrasemDate(year: 1970, month: 1, day: 1),
            end: MrasemDate(iso: delegation.end) ?? MrasemDate(year: 1970, month: 1, day: 1),
            timeZone: destination?.timeZone ?? "",
            currency: destination?.currency ?? "",
            weather: destination?.weather ?? "",
            receiver: Receiver(name: escort?.name ?? "", title: escort?.title ?? "", phone: escort?.phone ?? "",
                               spot: escort?.meetingSpot ?? ""),
            car: Car(type: car?.type ?? "", plate: car?.plate ?? "", driver: db.driver(car?.driverId)?.name ?? "",
                     country: car.map { $0.plateStyle == .qatar ? "QATAR" : "UK" } ?? "",
                     plateStyle: car?.plateStyle ?? .qatar),
            coordinator: Coordinator(name: coordinator?.name ?? "", phone: coordinator?.phone ?? ""),
            venue: Venue(building: venue?.building ?? "", area: venue?.area ?? "", entrance: venue?.entrance ?? "",
                         floor: venue?.floor ?? "", hall: venue?.hall ?? "", parking: venue?.parking ?? "",
                         lat: venue?.latitude ?? 0, lng: venue?.longitude ?? 0, mapLabel: venue?.mapLabel ?? ""),
            hotel: Hotel(name: hotel?.name ?? "", area: hotel?.area ?? "", room: anchor?.room ?? "",
                         breakfast: hotel?.breakfast ?? "", drive: driveText(hotel: hotel, venue: venue)),
            emergency: (destination?.emergency ?? []).map { EmergencyContact(label: $0.label, value: $0.value) },
            days: days ?? programDays(db, delegation: delegation).0,
            services: (destination?.services ?? []).map { category in
                ServiceCategory(name: category.name, apps: category.apps.map {
                    ServiceApp(name: $0.name, nameEn: $0.nameEn, color: $0.color, description: $0.description, url: $0.url)
                })
            },
            quickInfo: (destination?.quickInfo ?? []).map { QuickInfo(label: $0.label, value: $0.value) },
            places: db.places
                .filter { $0.kind == .attraction && $0.mode == delegation.mode }
                .map { Place(name: $0.name, description: $0.description, minutes: $0.minutes, durationHours: $0.durationHours, tag: $0.tag) },
            customs: destination?.customs ?? [],
            nextMeeting: NextMeeting(who: meeting?.who ?? "", address: meeting?.address ?? "", seat: meeting?.seat ?? "",
                                     gift: meeting?.gift ?? "", language: meeting?.language ?? "")
        )
    }

    /// يوم لكل تاريخ في فترة الوفد (حتى اللي من غير فقرات) + معرّفات الفقرات بنفس الترتيب.
    static func programDays(_ db: MrasemDatabase, delegation: DelegationRecord) -> ([ProgramDay], [[String]]) {
        var days: [ProgramDay] = []
        var ids: [[String]] = []

        for date in StoreTime.days(from: delegation.start, to: delegation.end) {
            let items = ProgramService.items(db, delegationId: delegation.id, on: date)
            days.append(ProgramDay(label: StoreTime.dayLabel(date), items: items.map { programItem($0, db) }))
            ids.append(items.map(\.id))
        }
        return (days, ids)
    }

    static func programItem(_ item: ProgramItemRecord, _ db: MrasemDatabase) -> ProgramItem {
        if item.kind == .free, let end = item.endTime,
           let from = StoreTime.minutes(item.time), let to = StoreTime.minutes(end) {
            return .freeTime(ProgramItem.FreeTime(from: item.time, to: end, hours: Double(to - from) / 60))
        }
        let place = db.place(item.placeId)?.name ?? ""
        return .official(ProgramItem.Official(
            time: item.time,
            title: item.title,
            place: place.isEmpty ? item.note : place,
            note: place.isEmpty || item.note.isEmpty ? nil : item.note,
            isKey: item.isKey
        ))
    }

    /// مرحلة الوصول من حالة رحلة أول فقرة في البرنامج.
    static func arrivalStage(_ db: MrasemDatabase, delegationId: String) -> Int {
        guard let first = ProgramService.items(db, delegationId: delegationId).first else { return 0 }
        switch DriverTripService.status(of: first.id, in: db) {
        case .scheduled: return 0
        case .onTheWay: return 1
        case .arrived: return 2
        case .pickedUp: return 3
        case .completed: return 4
        }
    }

    /// «٨ دقائق إلى الوزارة».
    static func driveText(hotel: PlaceRecord?, venue: PlaceRecord?) -> String {
        guard let hotel, hotel.minutes > 0 else { return "" }
        let target = venue.map { $0.mapLabel.isEmpty ? $0.name : $0.mapLabel } ?? ""
        let key = (3...10).contains(hotel.minutes) ? "mrasem_hotel_drive_few" : "mrasem_hotel_drive_many"
        return mrasemString(key, [hotel.minutes.toArabicDigits(), target])
    }
}
