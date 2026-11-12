//
//  MrasemStrings.swift
//  Mrasem
//
//  Mirrors Android: stringResource(R.string.x, args) / context.getString(id, *args).
//

import Foundation

/// نصوص التطبيق — كلها عربي (قرار #4).
///
/// الـ catalog شايل مفاتيح دلالية (`mrasem_*`)، فمفتاح الترجمة نفسه هو اسم المفتاح
/// في اللغة المصدر. عشان كده البحث بيتثبّت على `ar.lproj` بدل ما يتبع لغة الجهاز
/// (اللي كانت بترجّع اسم المفتاح نفسه).
nonisolated enum MrasemStrings {
    /// جدول النصوص العربي من الـ bundle.
    static let table: [String: String] = {
        guard let lproj = Bundle.main.path(forResource: "ar", ofType: "lproj") else { return [:] }
        let url = URL(fileURLWithPath: lproj).appendingPathComponent("Localizable.strings")
        return (NSDictionary(contentsOf: url) as? [String: String]) ?? [:]
    }()

    /// المفتاح لو موجود في الجدول، وإلا المفتاح نفسه.
    static func lookup(_ key: String) -> String {
        if let value = table[key] { return value }
        // احتياطي: لو الجدول مالوش (bundle مختلف) نرجع لبحث الـ bundle العادي.
        let fallback = Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
        return fallback == key ? key : fallback
    }
}

/// نص من `Localizable.xcstrings`. مفاتيح `mrasem_*` منقولة حرفياً من `strings.xml`،
/// والمتغيّرات بنفس الترقيم (`%1$@` بدل `%1$s`). لو المفتاح مش موجود بيرجع المفتاح نفسه
/// (والاختبارات بتمسك ده).
nonisolated func mrasemString(_ key: String, _ args: [CVarArg] = []) -> String {
    let format = MrasemStrings.lookup(key)
    guard !args.isEmpty else { return format }
    return String(format: format, arguments: args)
}
