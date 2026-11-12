//
//  MrasemDemoData+Outbound.swift
//  Mrasem
//
//  Phase 18 — تكملة MrasemDemoData (B8): مهمة الصادر.
//  منقولة حرفياً من 04-DEMO-DATA.md (قاعدتا C2 و C3).
//

import Foundation

extension MrasemDemoData {

    static let outbound = Mission(
        mode: .outbound,
        guest: "وفد وزارة العدل – دولة قطر",
        country: "مهمة رسمية",
        dest: "لندن، المملكة المتحدة",
        host: "مؤتمر قانوني دولي (مثال)",
        start: MrasemDate(iso: "2026-12-07")!,
        end: MrasemDate(iso: "2026-12-10")!,
        timeZone: "لندن UTC+0 (الدوحة أبكر ٣ ساعات)",
        currency: "الجنيه الإسترليني (GBP)",
        weather: "٤–٩° غائم، احتمال مطر",
        receiver: Receiver(
            name: "ممثل سفارة دولة قطر",
            title: "الملحق الإداري (مثال)",
            phone: "يُضاف من فريق المراسم",
            spot: "صالة الوصول – مطار هيثرو"
        ),
        car: Car(
            type: "مرسيدس V-Class – أسود",
            plate: "AB12 CDE",
            driver: "جيمس",
            country: "UK",
            plateStyle: .unitedKingdom
        ),
        coordinator: Coordinator(name: "مريم الكعبي", phone: coordinatorPhone),
        venue: Venue(
            building: "مركز المؤتمرات (مثال)",
            area: "وستمنستر، لندن",
            entrance: "مدخل الوفود الرسمية",
            floor: "الطابق الأول",
            hall: "القاعة الرئيسية",
            parking: "منطقة إنزال الوفود",
            lat: 51.5007,
            lng: -0.1246,
            mapLabel: "المؤتمر"
        ),
        hotel: Hotel(
            name: "فندق إقامة الوفد",
            area: "وسط لندن",
            room: "512",
            breakfast: "٧:٠٠ – ١٠:٣٠",
            drive: "١٥ دقيقة إلى المؤتمر"
        ),
        emergency: [
            EmergencyContact(label: "الطوارئ في المملكة المتحدة", value: "999"),
            EmergencyContact(label: "منسق المراسم", value: coordinatorPhone),
            EmergencyContact(label: "سفارة دولة قطر", value: "يُضاف من فريق المراسم"),
        ],
        days: [
            ProgramDay(
                label: "الإثنين ٧",
                items: [
                    .official(.init(
                        time: "13:40",
                        title: "الوصول إلى مطار هيثرو",
                        place: "صالة الوصول",
                        note: "الاستقبال: ممثل السفارة"
                    )),
                    .official(.init(
                        time: "15:00",
                        title: "التوجه إلى الفندق",
                        place: "وسط لندن"
                    )),
                    .freeTime(.init(from: "15:30", to: "18:30", hours: 3.0)),
                    .official(.init(
                        time: "19:00",
                        title: "عشاء عمل مع السفارة",
                        place: "مقر السفارة",
                        note: "زي رسمي"
                    )),
                ]
            ),
            ProgramDay(
                label: "الثلاثاء ٨",
                items: [
                    .official(.init(
                        time: "09:00",
                        title: "الجلسة الافتتاحية للمؤتمر",
                        place: "القاعة الرئيسية",
                        isKey: true
                    )),
                    .official(.init(
                        time: "11:00",
                        title: "كلمة وفد دولة قطر",
                        place: "القاعة الرئيسية",
                        note: "الملف التعريفي مرفق"
                    )),
                    .freeTime(.init(from: "13:00", to: "15:00", hours: 2.0)),
                    .official(.init(
                        time: "15:30",
                        title: "لقاء ثنائي مع وفد شريك",
                        place: "قاعة الاجتماعات ٣"
                    )),
                ]
            ),
            ProgramDay(
                label: "الأربعاء ٩",
                items: [
                    .official(.init(
                        time: "10:00",
                        title: "ورش العمل المتخصصة",
                        place: "الطابق الأول"
                    )),
                    .official(.init(
                        time: "16:00",
                        title: "حفل الختام",
                        place: "القاعة الرئيسية"
                    )),
                ]
            ),
            ProgramDay(
                label: "الخميس ١٠",
                items: [
                    .official(.init(
                        time: "11:00",
                        title: "المغادرة إلى المطار",
                        place: "مطار هيثرو"
                    )),
                ]
            ),
        ],
        services: [
            ServiceCategory(
                name: "التوصيل",
                apps: [
                    ServiceApp(
                        name: "Deliveroo",
                        nameEn: "Deliveroo",
                        color: 0xFF00CCBC,
                        description: "مطاعم وبقالة",
                        url: "https://deliveroo.co.uk"
                    ),
                    ServiceApp(
                        name: "Uber Eats",
                        nameEn: "Uber Eats",
                        color: 0xFF06C167,
                        description: "مطاعم",
                        url: "https://www.ubereats.com/gb"
                    ),
                    ServiceApp(
                        name: "Just Eat",
                        nameEn: "Just Eat",
                        color: 0xFFFF8000,
                        description: "مطاعم",
                        url: "https://www.just-eat.co.uk"
                    ),
                ]
            ),
            ServiceCategory(
                name: "سيارات الأجرة",
                apps: [
                    ServiceApp(
                        name: "Uber",
                        nameEn: "Uber",
                        color: 0xFF111111,
                        description: "الأكثر انتشاراً",
                        url: "https://www.uber.com/gb"
                    ),
                    ServiceApp(
                        name: "Bolt",
                        nameEn: "Bolt",
                        color: 0xFF34D186,
                        description: "بديل بأسعار منافسة",
                        url: "https://bolt.eu"
                    ),
                    ServiceApp(
                        name: "التاكسي الأسود",
                        nameEn: "Black Cab",
                        color: 0xFF333333,
                        description: "من الشارع أو عبر FREENOW",
                        url: "https://www.free-now.com/uk/"
                    ),
                ]
            ),
            ServiceCategory(
                name: "النقل العام",
                apps: [
                    ServiceApp(
                        name: "مترو لندن",
                        nameEn: "TfL Underground",
                        color: 0xFFDC241F,
                        description: "الدفع بالبطاقة اللاتلامسية مباشرة",
                        url: "https://tfl.gov.uk"
                    ),
                ]
            ),
        ],
        quickInfo: [
            QuickInfo(label: "العملة", value: "جنيه إسترليني"),
            QuickInfo(label: "المقابس", value: "نوع G (ثلاثي)"),
            QuickInfo(label: "الطوارئ", value: "999"),
            QuickInfo(label: "البقشيش", value: "١٠–١٢٫٥٪ في المطاعم"),
            QuickInfo(label: "القيادة", value: "على اليسار"),
            QuickInfo(label: "الطقس", value: "اصطحب معطفاً ومظلة"),
        ],
        places: [
            Place(
                name: "المتحف البريطاني",
                description: "من أكبر متاحف العالم، الدخول مجاني",
                minutes: 12,
                durationHours: 2.0,
                tag: "ثقافة"
            ),
            Place(
                name: "نهر التايمز ووستمنستر",
                description: "ممشى يطل على البرلمان وساعة بيغ بن",
                minutes: 10,
                durationHours: 1.0,
                tag: "إطلالة"
            ),
            Place(
                name: "المعرض الوطني",
                description: "لوحات أوروبية كلاسيكية في ميدان ترافلغار",
                minutes: 10,
                durationHours: 1.5,
                tag: "فن"
            ),
            Place(
                name: "حدائق هايد بارك",
                description: "نزهة هادئة بين الجلسات",
                minutes: 8,
                durationHours: 1.0,
                tag: "طبيعة"
            ),
        ],
        customs: [
            "الالتزام الدقيق بالمواعيد",
            "المصافحة باختصار مع تواصل بصري",
            "تجنّب الأسئلة الشخصية في اللقاء الأول",
            "يُفضّل عدم مقاطعة المتحدث في الجلسات",
        ],
        nextMeeting: NextMeeting(
            who: "رئيس اللجنة المنظمة للمؤتمر",
            address: "Your Excellency / Mr. Chairman",
            seat: "المقعد المخصص لوفد دولة قطر في الصف الأول",
            gift: "هدية تذكارية من الوزارة",
            language: "الإنجليزية"
        )
    )
}
