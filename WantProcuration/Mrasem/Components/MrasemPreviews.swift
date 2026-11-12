//
//  MrasemPreviews.swift
//  Mrasem
//
//  Previews لكل مكوّن — نسخة فاتح وداكن (قاعدة B5).
//  الـ Gallery (Screens/Gallery) بتعرض كل المكوّنات مع بعض.
//

import SwiftUI

// MARK: - Cards

private struct MrasemCardsSample: View {
    @Environment(\.mrasem) private var theme

    var body: some View {
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
}

#Preview("Cards - Light") {
    MrasemPreview(.light) { MrasemCardsSample() }
}

#Preview("Cards - Dark") {
    MrasemPreview(.dark) { MrasemCardsSample() }
}

// MARK: - Controls

private struct MrasemControlsSample: View {
    @Environment(\.mrasem) private var theme

    var body: some View {
        HStack(spacing: 8) {
            MrasemButton("اتصال", variant: .primary) {}
            MrasemButton("واتساب") {}
            MrasemButton("إلغاء", variant: .ghost) {}
        }
        MrasemButton("الخطوة التالية", variant: .primary, block: true) {}
        MrasemButton("معطّل", variant: .primary, block: true, enabled: false) {}

        HStack(spacing: 8) {
            MrasemChip("الكل", selected: true) {}
            MrasemChip("مطاعم") {}
        }

        HStack(spacing: 8) {
            MrasemAvatarInitial("سعيد المري")
            MrasemPlateBadge(plate: "123456", country: "QATAR", style: .qatar)
            MrasemPlateBadge(plate: "AB12 CDE", country: "UK", style: .unitedKingdom)
        }

        MrasemDayTabs(labels: ["الإثنين ٢٣", "الثلاثاء ٢٤", "الأربعاء ٢٥"], selectedIndex: .constant(1))

        HStack(spacing: 8) {
            MrasemSegmented(options: ["الضيف", "فريق المراسم"], selectedIndex: .constant(0))
        }
        .padding(8)
        .background(theme.colors.headerBg)
    }
}

#Preview("Controls - Light") {
    MrasemPreview(.light) { MrasemControlsSample() }
}

#Preview("Controls - Dark") {
    MrasemPreview(.dark) { MrasemControlsSample() }
}

// MARK: - Inputs

private struct MrasemInputsSample: View {
    @State private var text = ""
    @State private var selection = 0

    var body: some View {
        MrasemTextField(value: $text, label: "الاسم", placeholder: "اكتب هنا…")
        MrasemTextField(value: .constant("قيمة مكتوبة"), label: "حقل")
        MrasemSelect(options: ["الكل", "مطاعم", "ثقافة"], selectedIndex: $selection, label: "التصنيف")
        MrasemAskBar(value: $text, placeholder: "اكتب سؤالك…", sendLabel: "إرسال") {}
    }
}

#Preview("Inputs - Light") {
    MrasemPreview(.light) { MrasemInputsSample() }
}

#Preview("Inputs - Dark") {
    MrasemPreview(.dark) { MrasemInputsSample() }
}

// MARK: - List items

private struct MrasemListItemsSample: View {
    @State private var checked = true

    var body: some View {
        MrasemNoticeBanner(title: "تغيّر موعد", body: "تم تقديم الجلسة ساعة واحدة.")

        MrasemCard {
            MrasemStatusSteps(
                steps: ["هبوط الطائرة", "المستقبِل بانتظارك", "التوجه إلى الفندق"],
                current: 1
            )
        }

        MrasemCard {
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

        MrasemCard {
            MrasemServiceRow(
                name: "تاكسي",
                nameEn: "Taxi",
                description: "طلب سيارة",
                logoText: "T",
                logoColor: Color(.sRGB, red: 0x2F / 255, green: 0x7D / 255, blue: 0x4F / 255),
                actionLabel: "فتح"
            ) {}
            MrasemChecklistRow(text: "جواز السفر", checked: checked) { checked.toggle() }
            MrasemChecklistRow(text: "بطاقة الدعوة", checked: false) {}
        }

        MrasemPlaceCard(
            name: "متحف الفن الإسلامي",
            tag: "ثقافة",
            description: "وصف مختصر للمكان.",
            meta: ["١٠ دقائق · مشي"],
            actionLabel: "أرغب في الزيارة"
        ) {}

        MrasemChatBubble(text: "ماذا ألبس اليوم؟", fromMe: true)
        MrasemChatBubble(text: "زي اليوم بدلة رسمية داكنة.", fromMe: false)

        MrasemActionRow(title: "طلب زيارة: متحف الفن الإسلامي", subtitle: "بانتظار الرد") {
            MrasemButton("تم الترتيب", variant: .primary) {}
        }
    }
}

#Preview("List items - Light") {
    MrasemPreview(.light) { MrasemListItemsSample() }
}

#Preview("List items - Dark") {
    MrasemPreview(.dark) { MrasemListItemsSample() }
}
