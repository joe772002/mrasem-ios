//
//  MrasemDemoData.swift
//  Mrasem
//
//  Mirrors Android: data/local/MrasemDemoData.kt
//
//  بيانات الديزاين منقولة حرفياً من 04-DEMO-DATA.md (قاعدتا C2 و C3).
//  أي تعديل هنا لازم يطابق الوثيقة.
//

import Foundation

nonisolated enum MrasemDemoData {

    /// مشترك بين `inbound` و`outbound` (الملف التاني).
    static let coordinatorPhone = "+974 5555 0456"

    static let inbound = Mission(
        mode: .inbound,
        guest: "معالي وزير العدل ووفده المرافق",
        country: "وفد رسمي زائر",
        dest: "الدوحة، دولة قطر",
        host: "وزارة العدل – دولة قطر",
        start: MrasemDate(iso: "2026-11-23")!,
        end: MrasemDate(iso: "2026-11-25")!,
        timeZone: "توقيت الدوحة UTC+3",
        currency: "الريال القطري (QAR)",
        weather: "٢٥–٣٠° مشمس",
        receiver: Receiver(
            name: "سعيد المري",
            title: "منسق المراسم والتشريفات",
            phone: "+974 5555 0123",
            spot: "صالة كبار الشخصيات – مطار حمد الدولي"
        ),
        car: Car(
            type: "لكزس LS – أسود",
            plate: "123456",
            driver: "أحمد",
            country: "QATAR",
            plateStyle: .qatar
        ),
        coordinator: Coordinator(name: "مريم الكعبي", phone: coordinatorPhone),
        venue: Venue(
            building: "مبنى وزارة العدل",
            area: "الدفنة، الدوحة",
            entrance: "المدخل الرئيسي (ب)",
            floor: "الطابق الرابع",
            hall: "قاعة الاجتماعات الكبرى",
            parking: "مواقف كبار الزوار أمام المدخل",
            lat: 25.3226,
            lng: 51.5262,
            mapLabel: "الوزارة"
        ),
        hotel: Hotel(
            name: "فندق الإقامة الرسمي",
            area: "الخليج الغربي",
            room: "1204",
            breakfast: "٦:٣٠ – ١٠:٣٠",
            drive: "٨ دقائق إلى الوزارة"
        ),
        emergency: [
            EmergencyContact(label: "الطوارئ (شرطة، إسعاف، إطفاء)", value: "999"),
            EmergencyContact(label: "منسق المراسم", value: coordinatorPhone),
            EmergencyContact(label: "أقرب مستشفى", value: "مستشفى حمد العام"),
        ],
        days: [
            ProgramDay(
                label: "الإثنين ٢٣",
                items: [
                    .official(.init(
                        time: "14:10",
                        title: "الوصول إلى مطار حمد الدولي",
                        place: "صالة كبار الشخصيات",
                        note: "الاستقبال: سعيد المري"
                    )),
                    .official(.init(
                        time: "15:00",
                        title: "التوجه إلى الفندق",
                        place: "الخليج الغربي"
                    )),
                    .freeTime(.init(from: "15:30", to: "19:00", hours: 3.5)),
                    .official(.init(
                        time: "19:30",
                        title: "عشاء ترحيبي",
                        place: "مطعم الفندق",
                        note: "زي رسمي"
                    )),
                ]
            ),
            ProgramDay(
                label: "الثلاثاء ٢٤",
                items: [
                    .official(.init(
                        time: "09:30",
                        title: "جلسة المباحثات الرسمية",
                        place: "وزارة العدل – قاعة الاجتماعات الكبرى",
                        note: "بحضور سعادة الوزير",
                        isKey: true
                    )),
                    .official(.init(
                        time: "11:30",
                        title: "توقيع مذكرة التفاهم وصورة تذكارية",
                        place: "القاعة ذاتها"
                    )),
                    .official(.init(
                        time: "12:30",
                        title: "غداء رسمي",
                        place: "وزارة العدل"
                    )),
                    .freeTime(.init(from: "14:00", to: "16:30", hours: 2.5)),
                    .official(.init(
                        time: "17:00",
                        title: "جولة في متحف الفن الإسلامي",
                        place: "الكورنيش"
                    )),
                ]
            ),
            ProgramDay(
                label: "الأربعاء ٢٥",
                items: [
                    .official(.init(
                        time: "10:00",
                        title: "زيارة ميدانية لمركز خدمات",
                        place: "إدارة الخدمات الخارجية"
                    )),
                    .official(.init(
                        time: "13:00",
                        title: "الوداع الرسمي والتوجه للمطار",
                        place: "مطار حمد الدولي",
                        note: "المرافق: سعيد المري"
                    )),
                ]
            ),
        ],
        services: [
            ServiceCategory(
                name: "التوصيل",
                apps: [
                    ServiceApp(
                        name: "سنونو",
                        nameEn: "Snoonu",
                        color: 0xFFE3262F,
                        description: "طعام وبقالة وصيدليات",
                        url: "https://snoonu.com"
                    ),
                    ServiceApp(
                        name: "طلبات",
                        nameEn: "Talabat",
                        color: 0xFFFF5A00,
                        description: "مطاعم وبقالة",
                        url: "https://www.talabat.com/qatar"
                    ),
                    ServiceApp(
                        name: "رفيق",
                        nameEn: "Rafeeq",
                        color: 0xFF1F8A70,
                        description: "مطاعم وخدمات توصيل",
                        url: "https://www.google.com/search?q=Rafeeq+Qatar+app"
                    ),
                ]
            ),
            ServiceCategory(
                name: "سيارات الأجرة",
                apps: [
                    ServiceApp(
                        name: "كروة",
                        nameEn: "Karwa",
                        color: 0xFF0B6E4F,
                        description: "التاكسي الرسمي بالعداد، متاح من المطار مباشرة",
                        url: "https://www.mowasalat.com"
                    ),
                    ServiceApp(
                        name: "أوبر",
                        nameEn: "Uber",
                        color: 0xFF111111,
                        description: "يتيح طلب تاكسي كروة من داخله",
                        url: "https://www.uber.com"
                    ),
                    ServiceApp(
                        name: "تطبيقات مرخّصة أخرى",
                        nameEn: "Badrgo · Aabir · Ryde",
                        color: 0xFF6F6266,
                        description: "من قائمة وزارة المواصلات",
                        url: "https://marhaba.qa/?p=358177"
                    ),
                ]
            ),
            ServiceCategory(
                name: "النقل العام",
                apps: [
                    ServiceApp(
                        name: "مترو الدوحة",
                        nameEn: "Doha Metro",
                        color: 0xFF8A1538,
                        description: "أقرب محطة للفندق: الخليج الغربي – ٧ دقائق مشياً",
                        url: "https://www.qr.com.qa"
                    ),
                ]
            ),
        ],
        quickInfo: [
            QuickInfo(label: "العملة", value: "ريال قطري"),
            QuickInfo(label: "المقابس", value: "نوع G (ثلاثي)"),
            QuickInfo(label: "الطوارئ", value: "999"),
            QuickInfo(label: "البقشيش", value: "١٠٪ اختياري"),
            QuickInfo(label: "عطلة الأسبوع", value: "الجمعة والسبت"),
            QuickInfo(label: "الماء", value: "آمن ومتوفر معبأً"),
        ],
        places: [
            Place(
                name: "متحف الفن الإسلامي",
                description: "مجموعة فنية إسلامية من ثلاث قارات، على الكورنيش",
                minutes: 10,
                durationHours: 1.5,
                tag: "ثقافة"
            ),
            Place(
                name: "كورنيش الدوحة",
                description: "ممشى بحري بإطلالة على أبراج الخليج الغربي",
                minutes: 5,
                durationHours: 1.0,
                tag: "إطلالة"
            ),
            Place(
                name: "سوق واقف",
                description: "السوق التراثي، مطاعم وصقور وحرف تقليدية",
                minutes: 12,
                durationHours: 2.0,
                tag: "تراث"
            ),
            Place(
                name: "متحف قطر الوطني",
                description: "قصة قطر في مبنى وردة الصحراء",
                minutes: 12,
                durationHours: 2.0,
                tag: "ثقافة"
            ),
            Place(
                name: "الحي الثقافي كتارا",
                description: "مدرج ومساجد ومعارض على البحر",
                minutes: 10,
                durationHours: 1.5,
                tag: "ثقافة"
            ),
            Place(
                name: "مشيرب قلب الدوحة",
                description: "حي معماري حديث ومتاحف مشيرب",
                minutes: 12,
                durationHours: 1.5,
                tag: "عمارة"
            ),
            Place(
                name: "اللؤلؤة – قطر",
                description: "مرسى ويخوت ومطاعم مطلة على البحر",
                minutes: 15,
                durationHours: 2.0,
                tag: "مساء"
            ),
            Place(
                name: "رحلة صحراوية إلى خور العديد",
                description: "البحر الداخلي والكثبان، تحتاج يوماً أو نصف يوم",
                minutes: 70,
                durationHours: 5.0,
                tag: "طبيعة"
            ),
        ],
        customs: [
            "المصافحة باليد اليمنى، والانتظار حتى تمدّ السيدة يدها أولاً",
            "تقديم القهوة العربية والتمر من مظاهر الترحيب، ويُهزّ الفنجان عند الاكتفاء",
            "تجنّب التقاط صور للأشخاص دون استئذان",
            "مراعاة أوقات الصلاة عند جدولة الزيارات",
        ],
        nextMeeting: NextMeeting(
            who: "سعادة وزير العدل – دولة قطر",
            address: "سعادة الوزير",
            seat: "رأس الطاولة، الضيف عن يمينه",
            gift: "هدية تذكارية تُقدّم بعد التوقيع",
            language: "ترجمة فورية متاحة"
        )
    )
}
