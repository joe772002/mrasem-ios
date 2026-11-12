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

enum MrasemDemoData {

    private static let coordinatorPhone = "+974 5555 0456"

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

    static let missions: [MissionMode: Mission] = [
        .inbound: inbound,
        .outbound: outbound,
    ]

    /// أطقم الزي (مشتركة للوضعين).
    static let dressSets: [DressCode: DressSet] = [
        .formal: DressSet(
            title: "بدلة رسمية داكنة",
            men: [
                "بدلة كحلية أو سوداء أو رمادية، مغلقة",
                "ربطة العنق تنتهي عند مستوى الحزام",
                "البنطال يغطي سطح الحذاء",
                "حذاء جلد أسود أو بني",
            ],
            women: [
                "فستان رسمي طويل أو بدلة نسائية داكنة",
                "كعب لا يتجاوز ٤ سم ولا يصدر صوتاً",
                "حذاء أسود أو بني أو عنابي",
                "مكياج وإكسسوارات هادئة",
            ]
        ),
        .bisht: DressSet(
            title: "الزي الوطني مع البشت",
            men: [
                "الثوب والغترة مع البشت القطري",
                "البشت للمناسبات البروتوكولية الرفيعة",
                "التنسيق مع بقية أعضاء الوفد لضمان الاتساق",
            ],
            women: [
                "عباءة رسمية محتشمة بلون هادئ",
                "حذاء بكعب منخفض",
                "إكسسوارات محدودة",
            ]
        ),
    ]

    /// قبل الخروج من الفندق.
    static let checklist: [String] = [
        "البطاقات التعريفية",
        "الهدية الرسمية",
        "الملف التعريفي للضيف",
        "الزي المعتمد لليوم",
        "تأكيد موعد السيارة",
    ]

    /// الدليل الإرشادي.
    static let guides: [String] = [
        "الزيارات الداخلية",
        "الزيارات الخارجية",
        "الجلوس",
        "الإعلام",
        "الضيافة",
        "الزي واللباس",
        "تقديم الهدايا",
        "الصور التذكارية",
    ]

    /// أسئلة المساعد الجاهزة.
    static let quickQuestions: [String] = [
        "ماذا ألبس اليوم؟",
        "متى موعدي القادم؟",
        "أين السيارة؟",
        "أريد طلب طعام",
        "تاكسي",
        "أماكن قريبة",
    ]
}
