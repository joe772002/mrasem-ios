//
//  MrasemNotices.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/components/mrasem/MrasemNotices.kt
//

import SwiftUI

/// اسم الزي كما في اختيار نموذج الفريق: «بدلة رسمية» / «الزي الوطني مع البشت».
nonisolated func mrasemDressOptionLabel(_ dress: DressCode) -> String {
    mrasemString(dress == .bisht ? "mrasem_dress_option_bisht" : "mrasem_dress_option_formal")
}

/// نص التنبيه النهائي من الـ strings (قاعدة C1).
nonisolated func mrasemNoticeText(_ content: NoticeContent) -> String {
    switch content {
    case let .dressApproved(dress):
        return mrasemString("mrasem_notice_dress_approved", [mrasemDressOptionLabel(dress)])
    case .visitDataUpdated:
        return mrasemString("mrasem_notice_visit_updated")
    case let .postponed(title, newTime):
        return mrasemString("mrasem_notice_postponed", [title, newTime])
    case let .broadcast(text):
        return text
    case let .requestResolved(place):
        return mrasemString("mrasem_notice_request_resolved", [place ?? mrasemString("mrasem_notice_question_answered")])
    }
}

/// التنبيهات أعلى شاشة المهمة والبرنامج: «تحديث من فريق المراسم» + النص.
struct MrasemNoticesSection: View {
    @Environment(\.mrasem) private var theme

    let notices: [Notice]

    init(notices: [Notice]) {
        self.notices = notices
    }

    var body: some View {
        if !notices.isEmpty {
            let title = mrasemString("mrasem_notice_title")
            VStack(alignment: .leading, spacing: theme.dimens.screenGap) {
                ForEach(notices) { notice in
                    MrasemNoticeBanner(title: title, body: mrasemNoticeText(notice.content))
                }
            }
        }
    }
}

#Preview("Notices - Light") {
    MrasemPreview(.light) { MrasemNoticesSection(notices: MrasemNoticesSample.notices) }
}

#Preview("Notices - Dark") {
    MrasemPreview(.dark) { MrasemNoticesSection(notices: MrasemNoticesSample.notices) }
}

private enum MrasemNoticesSample {
    static let notices: [Notice] = [
        Notice(id: 2, mode: .inbound, content: .postponed(title: "جلسة المباحثات الرسمية", newTime: "10:00")),
        Notice(id: 1, mode: .inbound, content: .dressApproved(.bisht)),
    ]
}
