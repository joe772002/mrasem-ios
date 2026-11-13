//
//  MrasemSeed.swift
//  Mrasem
//
//  Phase 11 — «بيانات العرض» الاختيارية (قاعدة F2): بيانات بوابة الإدارة (الوفود الثلاثة،
//  الأعضاء، السائقين، السيارات، المرافقين، البرنامج، الطلبات) + محتوى مراسم من `MrasemDemoData`
//  (الملتقى، الفندق، الخدمات، الأماكن، الأعراف، الزي). بيتحمّل بس لما المستخدم يختاره.
//

import Foundation

nonisolated enum MrasemSeed {

    /// الأدمن اللي بيتعمل في القاعدة الفاضية عشان تقدر تدخل (08 §3).
    static let defaultAdmin = TeamUserRecord(id: "admin", name: "مدير النظام", role: .admin, phone: "", email: "")

    /// لحظة ثابتة للبيانات (عشان المقارنة في الاختبارات).
    private static let seedDate = Date(timeIntervalSince1970: 1_794_000_000)

    static func demo() -> MrasemDatabase {
        var db = MrasemDatabase()
        db.didChooseStart = true
        db.destinations = [destination(id: "dest_doha", MrasemDemoData.inbound), destination(id: "dest_london", MrasemDemoData.outbound)]
        db.places = places()
        db.team = [
            TeamUserRecord(id: "u1", name: "مريم الكعبي", role: .admin, phone: "+974 5555 0456", email: ""),
            TeamUserRecord(id: "u2", name: "سعيد المري", role: .coordinator, phone: "+974 5555 0123", email: ""),
        ]
        db.escorts = [
            EscortRecord(id: "e1", name: "سعيد المري", title: "منسق المراسم والتشريفات", phone: "+974 5555 0123",
                         meetingSpot: MrasemDemoData.inbound.receiver.spot),
            EscortRecord(id: "e2", name: "ممثل سفارة دولة قطر", title: "الملحق الإداري (مثال)", phone: "يُضاف من فريق المراسم",
                         meetingSpot: MrasemDemoData.outbound.receiver.spot),
            EscortRecord(id: "e3", name: "مريم الكعبي", title: "منسقة المراسم", phone: "+974 5555 0456", meetingSpot: ""),
        ]
        db.drivers = [
            DriverRecord(id: "r1", name: "أحمد", phone: "+974 5555 0789", status: .available),
            DriverRecord(id: "r2", name: "جيمس", phone: "+44 20 0000 0000", status: .available),
            DriverRecord(id: "r3", name: "سائق احتياطي ١", phone: "", status: .available),
            DriverRecord(id: "r4", name: "سائق احتياطي ٢", phone: "", status: .onLeave),
        ]
        db.cars = [
            CarRecord(id: "c1", type: "لكزس LS – أسود", plate: "123456", plateStyle: .qatar, driverId: "r1"),
            CarRecord(id: "c2", type: "مرسيدس V-Class – أسود", plate: "AB12 CDE", plateStyle: .unitedKingdom, driverId: "r2"),
            CarRecord(id: "c3", type: "سيارة احتياطية", plate: "", plateStyle: .qatar, driverId: "r3"),
        ]
        db.delegations = delegations()
        db.members = [
            member("m1", "d1", "معالي وزير العدل", "رئيس الوفد", escort: "e1", car: "c1", room: "1204", head: true),
            member("m2", "d1", "عضو الوفد ٢", "مدير المكتب", escort: "e1", car: "c1", room: "1206"),
            member("m3", "d1", "عضو الوفد ٣", "مستشار قانوني", escort: nil, car: nil, room: "", app: .invited),
            member("m4", "d2", "رئيس الوفد", "رئيس الوفد", escort: "e2", car: "c2", room: "512", head: true),
            member("m5", "d2", "عضو الوفد ٢", "باحث قانوني", escort: "e2", car: "c2", room: "", app: .invited),
            member("m6", "d3", "رئيس الوفد", "رئيس الوفد", escort: nil, car: "c1", room: "", app: .invited, head: true),
        ]
        db.program = program()
        db.requests = [
            request("rq1", "d1", "m1", .visit, "سوق واقف", place: attractionId("سوق واقف")),
            request("rq2", "d1", "m2", .question, "هل يمكن تأجيل جولة المتحف ساعة؟"),
            request("rq3", "d1", "m1", .visit, "متحف قطر الوطني", place: attractionId("متحف قطر الوطني"), done: "تم الترتيب"),
            request("rq4", "d2", "m4", .question, "ما الزي المعتمد لحفل الختام؟"),
        ]
        db.notices = [
            NoticeRecord(id: "n1", delegationId: "d1", audience: .all,
                         recipients: [.member("m1"), .member("m2"), .member("m3")], readBy: [],
                         body: .broadcast("تم اعتماد زي اليوم: بدلة رسمية، وتحديث بيانات الزيارة."), createdAt: seedDate),
        ]
        db.preferences = PreferencesRecord(theme: .light)
        db.currentUser = .team("u1")
        return db
    }

    // MARK: - الوجهات والأماكن (من بيانات مراسم)

    private static func destination(id: String, _ m: Mission) -> DestinationRecord {
        DestinationRecord(
            id: id,
            name: m.dest,
            mode: m.mode,
            timeZone: m.timeZone,
            currency: m.currency,
            weather: m.weather,
            emergency: m.emergency.map { LabelValueRecord(label: $0.label, value: $0.value) },
            services: m.services.map { category in
                ServiceCategoryRecord(name: category.name, apps: category.apps.map {
                    ServiceAppRecord(name: $0.name, nameEn: $0.nameEn, color: $0.color, description: $0.description, url: $0.url)
                })
            },
            quickInfo: m.quickInfo.map { LabelValueRecord(label: $0.label, value: $0.value) },
            customs: m.customs,
            checklist: MrasemDemoData.checklist,
            guides: MrasemDemoData.guides,
            dressSets: DressCode.allCases.compactMap { code in
                MrasemDemoData.dressSets[code].map { DressSetRecord(code: code, title: $0.title, men: $0.men, women: $0.women) }
            }
        )
    }

    private static func places() -> [PlaceRecord] {
        let inbound = MrasemDemoData.inbound
        let outbound = MrasemDemoData.outbound
        var list: [PlaceRecord] = [
            place("h1", .hotel, .inbound, inbound.hotel.name, "الخليج الغربي · الفطور ٦:٣٠ – ١٠:٣٠", minutes: 8,
                  area: inbound.hotel.area, breakfast: inbound.hotel.breakfast),
            place("h2", .hotel, .outbound, outbound.hotel.name, "وسط لندن · الفطور ٧:٠٠ – ١٠:٣٠", minutes: 15,
                  area: outbound.hotel.area, breakfast: outbound.hotel.breakfast),
            place("f1", .restaurant, .inbound, "مطعم الفندق", "العشاء الترحيبي · زي رسمي", durationHours: 2),
            venue("g1", .inbound, "وزارة العدل – قاعة الاجتماعات الكبرى", "الدفنة · المدخل (ب) · الطابق الرابع",
                  minutes: 8, official: "سعادة وزير العدل – دولة قطر", inbound.venue),
            venue("g2", .outbound, "مركز المؤتمرات (مثال)", "وستمنستر · مدخل الوفود الرسمية",
                  minutes: 15, official: "رئيس اللجنة المنظمة للمؤتمر", outbound.venue),
            place("g3", .entity, .outbound, "مقر سفارة دولة قطر", "لندن", minutes: 20, official: "سفير دولة قطر"),
        ]
        for mission in [inbound, outbound] {
            for (index, p) in mission.places.enumerated() {
                list.append(place("a_\(mission.mode.rawValue)_\(index)", .attraction, mission.mode, p.name, p.description,
                                  minutes: p.minutes, durationHours: p.durationHours, tag: p.tag))
            }
        }
        return list
    }

    private static func attractionId(_ name: String) -> String? {
        for mission in [MrasemDemoData.inbound, MrasemDemoData.outbound] {
            if let index = mission.places.firstIndex(where: { $0.name == name }) {
                return "a_\(mission.mode.rawValue)_\(index)"
            }
        }
        return nil
    }

    // MARK: - الوفود والبرنامج (من بوابة الإدارة)

    private static func delegations() -> [DelegationRecord] {
        let inbound = MrasemDemoData.inbound
        let outbound = MrasemDemoData.outbound
        func meeting(_ m: Mission) -> NextMeetingRecord {
            NextMeetingRecord(who: m.nextMeeting.who, address: m.nextMeeting.address, seat: m.nextMeeting.seat,
                              gift: m.nextMeeting.gift, language: m.nextMeeting.language)
        }
        return [
            DelegationRecord(id: "d1", name: inbound.guest, mode: .inbound, host: inbound.host, countryLabel: inbound.country,
                             destinationId: "dest_doha", start: "2026-11-23", end: "2026-11-25", hotelId: "h1", venueId: "g1",
                             coordinatorIds: ["u2"], status: .active, dress: .formal, nextMeeting: meeting(inbound)),
            DelegationRecord(id: "d2", name: "وفد وزارة العدل – دولة قطر (لندن)", mode: .outbound, host: outbound.host,
                             countryLabel: outbound.country, destinationId: "dest_london", start: "2026-12-07", end: "2026-12-10",
                             hotelId: "h2", venueId: "g2", coordinatorIds: ["u2"], status: .active, dress: .formal,
                             nextMeeting: meeting(outbound)),
            DelegationRecord(id: "d3", name: "وفد زائر [اسم الجهة]", mode: .inbound, host: inbound.host, countryLabel: inbound.country,
                             destinationId: "dest_doha", start: "2026-11-24", end: "2026-11-26", hotelId: nil, venueId: nil,
                             coordinatorIds: [], status: .draft, dress: .formal, nextMeeting: nil),
        ]
    }

    private static func program() -> [ProgramItemRecord] {
        let museum = attractionId("متحف الفن الإسلامي")
        return [
            item("p1", "d1", "2026-11-23", "14:10", "الوصول إلى مطار حمد الدولي", .move, note: "صالة كبار الشخصيات · الاستقبال: سعيد المري", car: "c1"),
            item("p2", "d1", "2026-11-23", "15:00", "التوجه إلى الفندق", .move, place: "h1", car: "c1"),
            item("p3", "d1", "2026-11-23", "19:30", "عشاء ترحيبي", .meal, place: "f1", dress: "زي رسمي"),
            item("p4", "d1", "2026-11-24", "09:30", "جلسة المباحثات الرسمية", .official, place: "g1", note: "بحضور سعادة الوزير", car: "c1", key: true),
            item("p5", "d1", "2026-11-24", "11:30", "توقيع مذكرة التفاهم وصورة تذكارية", .official, place: "g1", note: "القاعة ذاتها"),
            item("p6", "d1", "2026-11-24", "12:30", "غداء رسمي", .meal, place: "g1", car: "c1"),
            item("p7", "d1", "2026-11-24", "17:00", "جولة في متحف الفن الإسلامي", .visit, place: museum, note: "الكورنيش", car: "c1"),
            item("p8", "d1", "2026-11-25", "10:00", "زيارة ميدانية لمركز خدمات", .visit, note: "إدارة الخدمات الخارجية", car: "c1"),
            item("p9", "d1", "2026-11-25", "13:00", "الوداع الرسمي والتوجه للمطار", .move, note: "المرافق: سعيد المري", car: "c1"),
            item("q1", "d2", "2026-12-07", "13:40", "الوصول إلى مطار هيثرو", .move, note: "الاستقبال: ممثل السفارة", car: "c2"),
            item("q2", "d2", "2026-12-07", "19:00", "عشاء عمل مع السفارة", .meal, place: "g3", car: "c2", dress: "زي رسمي"),
            item("q3", "d2", "2026-12-08", "09:00", "الجلسة الافتتاحية للمؤتمر", .official, place: "g2", note: "القاعة الرئيسية", car: "c2", key: true),
            item("q4", "d2", "2026-12-08", "11:00", "كلمة وفد دولة قطر", .official, place: "g2", note: "الملف التعريفي مرفق"),
            item("q5", "d2", "2026-12-09", "16:00", "حفل الختام", .official, place: "g2", car: "c2"),
            item("q6", "d2", "2026-12-10", "11:00", "المغادرة إلى المطار", .move, note: "مطار هيثرو", car: "c2"),
            item("s1", "d3", "2026-11-24", "12:45", "الاستقبال في مطار حمد الدولي", .move, note: "صالة كبار الشخصيات", car: "c1"),
        ]
    }

    // MARK: - مساعدات البناء

    private static func member(_ id: String, _ delegation: String, _ name: String, _ title: String,
                               escort: String?, car: String?, room: String,
                               app: MemberAppStatus = .active, head: Bool = false) -> MemberRecord {
        MemberRecord(id: id, delegationId: delegation, name: name, title: title, escortId: escort, carId: car,
                     room: room, appStatus: app, isHead: head)
    }

    private static func item(_ id: String, _ delegation: String, _ date: String, _ time: String, _ title: String,
                             _ kind: ProgramItemKind, place: String? = nil, note: String = "", car: String? = nil,
                             key: Bool = false, dress: String? = nil) -> ProgramItemRecord {
        ProgramItemRecord(id: id, delegationId: delegation, date: date, time: time, endTime: nil, title: title, kind: kind,
                          placeId: place, note: note, carId: car, isKey: key, isChanged: false, dressCode: dress)
    }

    private static func request(_ id: String, _ delegation: String, _ member: String, _ kind: RequestKind, _ text: String,
                                place: String? = nil, done reply: String? = nil) -> RequestRecord {
        RequestRecord(id: id, delegationId: delegation, memberId: member, kind: kind, text: text, placeId: place,
                      status: reply == nil ? .new : .done, reply: reply ?? "", createdAt: seedDate)
    }

    private static func place(_ id: String, _ kind: PlaceKind, _ mode: MissionMode, _ name: String, _ description: String,
                              minutes: Int = 0, durationHours: Double = 0, tag: String = "", official: String = "",
                              area: String = "", breakfast: String = "") -> PlaceRecord {
        PlaceRecord(id: id, kind: kind, mode: mode, name: name, description: description, minutes: minutes,
                    durationHours: durationHours, tag: tag, official: official, building: "", area: area, entrance: "",
                    floor: "", hall: "", parking: "", latitude: nil, longitude: nil, mapLabel: "", breakfast: breakfast, phone: "")
    }

    private static func venue(_ id: String, _ mode: MissionMode, _ name: String, _ description: String,
                              minutes: Int, official: String, _ v: Venue) -> PlaceRecord {
        PlaceRecord(id: id, kind: .entity, mode: mode, name: name, description: description, minutes: minutes,
                    durationHours: 0, tag: "", official: official, building: v.building, area: v.area, entrance: v.entrance,
                    floor: v.floor, hall: v.hall, parking: v.parking, latitude: v.lat, longitude: v.lng,
                    mapLabel: v.mapLabel, breakfast: "", phone: "")
    }
}
