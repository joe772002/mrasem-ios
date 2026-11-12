//
//  MrasemStrings.swift
//  Mrasem
//
//  Mirrors Android: stringResource(R.string.x, args) / context.getString(id, *args).
//

import Foundation

/// نص من `Localizable.xcstrings`. مفاتيح `mrasem_*` منقولة حرفياً من `strings.xml`،
/// والمتغيّرات بنفس الترقيم (`%1$@` بدل `%1$s`). لو المفتاح مش موجود بيرجع المفتاح نفسه
/// (والاختبارات بتمسك ده).
nonisolated func mrasemString(_ key: String, _ args: [CVarArg] = []) -> String {
    let format = NSLocalizedString(key, comment: "")
    guard !args.isEmpty else { return format }
    return String(format: format, arguments: args)
}
