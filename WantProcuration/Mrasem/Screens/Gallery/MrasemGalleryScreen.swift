//
//  MrasemGalleryScreen.swift
//  Mrasem
//
//  شاشة معرض المكوّنات (Debug) — بتعرض كل مكوّنات مراسم في مكان واحد.
//  Mirrors the Android Phase 1 component gallery.
//

import SwiftUI

struct MrasemGalleryScreen: View {
    @Environment(\.mrasem) private var theme

    @State private var roleIndex = 0
    @State private var modeIndex = 0
    @State private var dayIndex = 1
    @State private var segmentIndex = 0
    @State private var chipSelected = true
    @State private var checklistChecked = true
    @State private var text = ""
    @State private var selectIndex = 0
    @State private var toastState = MrasemToastState()

    var body: some View {
        MrasemScreenContent {
            gallerySection("الألوان") {
                HStack(spacing: 8) {
                    ForEach(colorSwatches, id: \.0) { swatch in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(swatch.1)
                                .frame(height: 40)
                            Text(swatch.0)
                                .mrasemText(theme.type.caption)
                                .foregroundColor(theme.colors.muted)
                        }
                    }
                }
            }

            gallerySection("الخطوط") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("مراسم — Reem Kufi 700").mrasemText(theme.type.heroDest).foregroundColor(theme.colors.ink)
                    Text("عنوان كارت — IBM Plex 700").mrasemText(theme.type.cardTitle).foregroundColor(theme.colors.ink)
                    Text("نص أساسي — IBM Plex 400").mrasemText(theme.type.body).foregroundColor(theme.colors.ink)
                    Text("نص صغير — IBM Plex 400").mrasemText(theme.type.label).foregroundColor(theme.colors.muted)
                    Text("الأرقام: ١٢٣٤٥٦٧٨٩٠").mrasemText(theme.type.statNumber, tabular: true).foregroundColor(theme.colors.maroonInk)
                }
            }

            gallerySection("الأزرار") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        MrasemButton("اتصال", variant: .primary) {}
                        MrasemButton("واتساب") {}
                        MrasemButton("إلغاء", variant: .ghost) {}
                    }
                    MrasemButton("الخطوة التالية", variant: .primary, block: true) {}
                    MrasemButton("معطّل", variant: .primary, block: true, enabled: false) {}
                    MrasemButton("محدَّد", variant: .outline) {}
                }
            }

            gallerySection("Chips و Segmented") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        MrasemChip("الكل", selected: chipSelected) { chipSelected.toggle() }
                        MrasemChip("مطاعم") {}
                    }
                    MrasemSegmented(
                        options: ["الضيف", "فريق المراسم"],
                        selectedIndex: $segmentIndex
                    )
                }
            }

            gallerySection("الكروت") {
                MrasemHeroCard {
                    MrasemPill("وفد رسمي زائر")
                    Text("الدوحة، دولة قطر")
                        .mrasemText(theme.type.heroDest)
                        .foregroundColor(theme.colors.ink)
                    HStack(spacing: 8) {
                        MrasemStatTile(value: "١٢", label: "يوم")
                        MrasemStatTile(value: "٣", label: "أيام")
                    }
                    MrasemKeyValueList([
                        KeyValue("التوقيت", "UTC+3"),
                        KeyValue("الهاتف", "+974 5555 0123", ltr: true),
                    ])
                }

                MrasemCard(title: "عنوان", headerEnd: AnyView(MrasemPill("اكتمل", kind: .ok))) {
                    Text("نص داخل الكارت")
                        .mrasemText(theme.type.body)
                        .foregroundColor(theme.colors.ink)
                    MrasemPill("محدَّث", kind: .warn)
                }

                MrasemKpiTile(value: "٢٤", label: "طلب جديد")
            }

            gallerySection("القوائم") {
                VStack(alignment: .leading, spacing: 8) {
                    MrasemStatusSteps(
                        steps: ["هبوط الطائرة", "المستقبِل بانتظارك", "التوجه إلى الفندق"],
                        current: 1
                    )

                    MrasemTimelineItem(
                        time: "09:30",
                        title: "جلسة المباحثات",
                        place: "قاعة الاجتماعات",
                        note: "بحضور الوزير",
                        keyCardLabel: "بطاقة الـ ٣٠ ثانية"
                    )
                    MrasemTimelineItem(
                        time: "11:30",
                        title: "توقيع مذكرة",
                        place: "القاعة ذاتها",
                        changed: true,
                        changedLabel: "تغيّر الموعد"
                    )
                    MrasemFreeTimeItem(
                        from: "15:30",
                        title: "وقت حر حتى 19:00",
                        description: "٣.٥ ساعات متاحة. اقتراحات قريبة من موقعك:",
                        suggestions: ["متحف", "سوق"]
                    )
                    MrasemTimelineItem(
                        time: "19:30",
                        title: "عشاء ترحيبي",
                        place: "مطعم الفندق",
                        showDivider: false
                    )
                }
            }

            gallerySection("الخدمات والأماكن") {
                VStack(alignment: .leading, spacing: 8) {
                    MrasemServiceRow(
                        name: "تاكسي",
                        nameEn: "Taxi",
                        description: "طلب سيارة",
                        logoText: "T",
                        logoColor: theme.colors.ok,
                        actionLabel: "فتح"
                    ) {}
                    MrasemPlaceCard(
                        name: "متحف الفن الإسلامي",
                        tag: "ثقافة",
                        description: "وصف مختصر للمكان.",
                        meta: ["١٠ دقائق · مشي"],
                        actionLabel: "أرغب في الزيارة"
                    ) {}
                }
            }

            gallerySection("التنبيهات والقوائم") {
                VStack(alignment: .leading, spacing: 8) {
                    MrasemNoticeBanner(title: "تغيّر موعد", body: "تم تقديم الجلسة ساعة واحدة.")
                    MrasemChecklistRow(text: "جواز السفر", checked: checklistChecked) { checklistChecked.toggle() }
                    MrasemChecklistRow(text: "بطاقة الدعوة", checked: false) {}
                    MrasemChatBubble(text: "ماذا ألبس اليوم؟", fromMe: true)
                    MrasemChatBubble(text: "زي اليوم بدلة رسمية داكنة.", fromMe: false)
                }
            }

            gallerySection("الحقول") {
                VStack(alignment: .leading, spacing: 8) {
                    MrasemTextField(value: $text, label: "الاسم", placeholder: "اكتب هنا…")
                    MrasemSelect(options: ["الكل", "مطاعم", "ثقافة"], selectedIndex: $selectIndex, label: "التصنيف")
                    MrasemAskBar(value: $text, placeholder: "اكتب سؤالك…", sendLabel: "إرسال") {}
                }
            }

            gallerySection("الأيقونات") {
                HStack(spacing: 16) {
                    MrasemIcons.mission.foregroundStyle(theme.colors.maroon)
                    MrasemIcons.plan.foregroundStyle(theme.colors.maroon)
                    MrasemIcons.services.foregroundStyle(theme.colors.maroon)
                    MrasemIcons.explore.foregroundStyle(theme.colors.maroon)
                    MrasemIcons.`protocol`.foregroundStyle(theme.colors.maroon)
                    MrasemIcons.assistant.foregroundStyle(theme.colors.maroon)
                }
            }

            gallerySection("الهيدر والـ bottom bar") {
                MrasemHeader(
                    title: "مراسم",
                    subtitle: "MRASEM · وزارة العدل",
                    roleOptions: ["الضيف", "فريق المراسم"],
                    roleIndex: $roleIndex,
                    modeOptions: ["أهلاً بكم في قطر", "مهمة رسمية بالخارج"],
                    modeIndex: $modeIndex
                )

                MrasemDayTabs(
                    labels: ["الإثنين ٢٣", "الثلاثاء ٢٤", "الأربعاء ٢٥"],
                    selectedIndex: $dayIndex
                )

                MrasemBottomBar(
                    items: [
                        MrasemBottomBarItem(label: "المهمة", icon: MrasemIcons.mission),
                        MrasemBottomBarItem(label: "البرنامج", icon: MrasemIcons.plan),
                        MrasemBottomBarItem(label: "الخدمات", icon: MrasemIcons.services),
                        MrasemBottomBarItem(label: "استكشف", icon: MrasemIcons.explore),
                        MrasemBottomBarItem(label: "البروتوكول", icon: MrasemIcons.`protocol`),
                        MrasemBottomBarItem(label: "المساعد", icon: MrasemIcons.assistant),
                    ],
                    selectedIndex: $segmentIndex
                )
            }

            gallerySection("الرسومات") {
                VStack(alignment: .leading, spacing: 12) {
                    MrasemMapPreview(venueLabel: "الوزارة", hotelLabel: "الفندق")

                    HStack(spacing: 16) {
                        MrasemQrPlaceholder()
                        MrasemDressIllustration(kind: .formal, width: 64, height: 80)
                        MrasemDressIllustration(kind: .bisht)
                    }
                }
            }

            gallerySection("التوست") {
                VStack(alignment: .leading, spacing: 8) {
                    MrasemButton("اظهر التوست", variant: .primary) {
                        toastState.show(strong: "تم إبلاغ المستقبِل والسائق.", rest: "سعيد بانتظارك.")
                    }
                    MrasemToastHost(state: toastState)
                }
            }
        }
    }

    private func gallerySection<Section: View>(
        _ title: String,
        @ViewBuilder content: @escaping () -> Section
    ) -> some View {
        MrasemCard(title: title, content: content)
    }

    private var colorSwatches: [(String, Color)] {
        let c = theme.colors
        return [
            ("maroon", c.maroon),
            ("gold", c.gold),
            ("bg", c.bg),
            ("surface", c.surface),
            ("ink", c.ink),
            ("muted", c.muted),
            ("line", c.line),
            ("tint", c.tint),
            ("ok", c.ok),
            ("warn", c.warn),
        ]
    }
}

#Preview("Gallery - Light") {
    MrasemGalleryScreen()
        .mrasemTheme(.light)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Gallery - Dark") {
    MrasemGalleryScreen()
        .mrasemTheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}
