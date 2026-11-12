//
//  MrasemSelectors.swift
//  Mrasem
//
//  Mirrors Android: domain/strategy/mrasem/MrasemSelectors.kt
//

import Foundation

extension Mission {
    /// عدد الفقرات الرسمية (كل العناصر غير الوقت الحر).
    var officialCount: Int {
        days.reduce(0) { total, day in
            total + day.items.filter { $0.official != nil }.count
        }
    }
}

extension MrasemState {
    /// آخر تنبيهين للوضع الحالي، الأحدث أولاً.
    func recentNotices(limit: Int = 2) -> [Notice] {
        Array(notices(for: mode).suffix(limit).reversed())
    }
}
