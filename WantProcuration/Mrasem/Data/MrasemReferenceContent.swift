//
//  MrasemReferenceContent.swift
//  Mrasem
//
//  Phase 13 — المحتوى المرجعي اللي شاشات الضيف بتعرضه (قائمة الفحص، أطقم الزي، أدلة البروتوكول).
//  في التطبيق الحقيقي بيجي من محتوى الوجهة في القاعدة (08 §3)، والافتراضي `demo` للـ Previews والاختبارات القديمة بس.
//

import Foundation

struct ReferenceContent: Equatable {
    /// «قبل الخروج من الفندق».
    var checklist: [String]
    var dressSets: [DressCode: DressSet]
    var guides: [String]

    /// من غير أي محتوى (وجهة مش متحددة أو اتمسحت).
    static let empty = ReferenceContent(checklist: [], dressSets: [:], guides: [])

    /// بيانات العرض الأصلية (Phases 4–7).
    static let demo = ReferenceContent(
        checklist: MrasemDemoData.checklist,
        dressSets: MrasemDemoData.dressSets,
        guides: MrasemDemoData.guides
    )

    /// طقم الزي، أو طقم فاضي لو الوجهة ملهاش بيانات للزي ده.
    func dressSet(_ code: DressCode) -> DressSet {
        dressSets[code] ?? DressSet(title: "", men: [], women: [])
    }
}
