# مراسم iOS — وثائق التحويل

تحويل مشروع «أرغب في عمل توكيل» (WantProcuration، SwiftUI) إلى تطبيق **مراسم**، بنفس اللي اتعمل في نسخة Android: نمسح الخاص بالتوثيق، ونحافظ على الأركيتكتشر، ونبني مراسم فوقها.

الهدف النهائي هو **التصميم المحسَّن** المعتمد في Android (branch `enhance`)، مش الديزاين الأصلي: هيدر عنّابي بزخرفة قطرية، شاشة اختيار بعد الـ Splash، ٤ أدوار، bottom bar عائم، «المزيد»، والإعدادات.

## الملفات

| الملف | المحتوى |
|---|---|
| `00-README.md` | الملف ده: الصورة العامة، حالة المشروع، القرارات المفتوحة |
| `01-DESIGN-SPEC.md` | مواصفات الديزاين الأصلي (ألوان، خطوط، مكوّنات، شاشات) — منقول من Android كما هو |
| `02-RULES.md` | قواعد iOS الملزمة + سجل القرارات |
| `03-PHASES.md` | خطة التنفيذ (Phase 0 → 9) |
| `04-DEMO-DATA.md` | بيانات الوضعين حرفياً — منقول من Android كما هو |
| `05-ENHANCED-DESIGN.md` | التصميم المحسَّن: الهيدر، الإعداد، الأدوار، الـ bottom bar، المزيد، الإعدادات، السائق |
| `06-ANDROID-REFERENCE.md` | خريطة: كل ملف Kotlin في Android ← مقابله في Swift |
| `design-reference/` | مصدر الديزاين الأصلي (CSS + JS) للمراجعة |

## المراجع

- **مصدر الديزاين: كود Android مباشرة** — `D:\private\new project\mrasem`، branch `enhance` (ريبو `joe772002/mrasem`). الألوان والمقاسات والنصوص والترتيب والسلوك بتتاخد من ملفات Kotlin و`strings.xml` زي ما هي، مش من الويب.
- ريبو iOS: https://github.com/joe772002/mrasem-ios.git
- للرجوع عند الشك فقط: الديزاين الأصلي https://claude.ai/artifact/Gg4iccc4Y1qqbwAV7d2d52 وكانفس التحسين https://claude.ai/artifact/PNNaXBfzvj6p29SZwE6dHg

## حالة المشروع الحالي (آخر تحديث 2026-11-12 — بعد Phase 0)

- SwiftUI، **36 ملف Swift** (كانوا 102)، target واحد اسمه `WantProcuration`، **من غير test target** (بيتضاف في Phase 2).
- النمط: `View` + `ViewModel: ObservableObject` (MVVM)، و`AppManager` كـ `@StateObject` للغة والثيم.
- التنقل: مكتبة `SwiftfulRouting` (`RouterView`).
- المكتبات (SPM): `SwiftfulRouting`، `SwiftfulUI`، `IQKeyboardManager`.
- الشبكة: `Networking/APIClient.swift` (async/await فوق URLSession) — موجود بس مش مستخدم في مراسم.
- المشروع `objectVersion = 77` بـ **File System Synchronized Groups**: أي ملف يتضاف أو يتمسح من فولدر `WantProcuration/` بيظهر في Xcode لوحده، من غير تعديل `project.pbxproj`. ده اللي بيخلّي الشغل من Windows ممكن.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0`، Swift 5.
- Bundle ID: `com.informatiqueComp.reserveProcuration2` · **اسم العرض: «مراسم»** · الإصدار 1.07.
- الخطوط: Cairo (6 أوزان) — Reem Kufi و IBM Plex Sans Arabic هيتبعتوا في Phase 1.
- النصوص: `Localizable.xcstrings` — **276 مفتاح** (13 بتوع الكود القديم اللي فضل + 263 `mrasem_*` منقولة حرفياً من Android)، `sourceLanguage = ar`.
- الـ Folder **repo على GitHub**: `https://github.com/joe772002/mrasem-ios.git`.
- **CI شغال**: `.github/workflows/ios.yml` بيبني على runner `macos-26`.
- كود مراسم كله تحت `WantProcuration/Mrasem/` (قاعدة A9) — دلوقتي فيه `Theme/MrasemBrand.swift` (مؤقت) و`Shell/MrasemSplash.swift` و`Shell/MrasemPlaceholderScreen.swift`.

## قيد مهم: مفيش Mac

الكود بيتكتب من Windows، ومفيش Swift compiler هنا، فـ **أي Phase بيتسلّم من غير build**. التحقق الفعلي له طريقين:

1. **CI على GitHub Actions** (runner macOS): بيعمل `xcodebuild build` و`test` على كل push. ده بيتظبط في Phase 0 أول ما الريبو يتعمل.
2. Mac في السحابة أو Codemagic للتشغيل على Simulator و TestFlight.

لحد ما واحد منهم يشتغل، أخطاء الـ compile هتتراكم ومش هتبان. عشان كده الريبو والـ CI لازم يكونوا قبل Phase 1.

## القرارات المفتوحة (الافتراضي بين قوسين)

> القرار #1 اتاخد: **الـ Bundle ID سيب زي ما هو**، واسم العرض بقى «مراسم». باقي القرارات ماشي على الافتراضي.

| # | القرار | الافتراضي |
|---|---|---|
| 1 | الـ Bundle ID واسم الـ target | ✅ **اتحسم** — Bundle ID زي ما هو (`com.informatiqueComp.reserveProcuration2`)، واسم العرض «مراسم». تحذير: لو اترفع على نفس حساب Apple بنفس الـ Bundle ID هيبقى تحديث لتطبيق التوكيل، مش تطبيق جديد |
| 2 | كود التوثيق | يتحذف **الخاص بالتوثيق بس**، والأركيتكتشر تفضل (الشبكة، الـ Extensions، مكوّنات الفورم، `AppManager`، `LocationManager`، المكتبات) — نفس قرار Android النهائي |
| 3 | البيانات | محلية ورا Repository، منقولة حرفياً من `04-DEMO-DATA.md` |
| 4 | اللغة | عربي RTL فقط |
| 5 | الحد الأدنى للنظام | يفضل iOS 26.0 زي المشروع. لو عايز أجهزة أقدم قول الرقم قبل Phase 1 |
| 6 | الخطوط | Reem Kufi + IBM Plex Sans Arabic (نفس ملفات Android)، و Cairo يفضل للمكوّنات القديمة |
| 7 | الاختبارات | منطق الأعمال Foundation فقط + test target يتضاف من Xcode/CI في Phase 2 |
| 8 | الحفظ الدائم | `UserDefaults` (الموجود): الدور والوضع، آخر تاب، الإشعارات، الثيم |

## الخطوة الجاية

Phase 0 خلص. الخطوة الجاية:

1. **شوف نتيجة الـ CI** على الـ push — أول build على `macos-26`. لو أخطاء، ابعتهالي وأنا أصلّحها.
2. **قول «ابدا phase 1»** — الـ Design System: الثيم (`MrasemColors` Light/Dark) · الخطوط · الأيقونات · كل المكوّنات المشتركة، مع `#Preview` للوضعين.
