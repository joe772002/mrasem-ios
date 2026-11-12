# مراسم iOS — وثائق التحويل

تحويل مشروع «أرغب في عمل توكيل» (WantProcuration، SwiftUI) إلى تطبيق **مراسم**، بنفس اللي اتعمل في نسخة Android: نمسح الخاص بالتوثيق، ونحافظ على الأركيتكتشر، ونبني مراسم فوقها.

الهدف النهائي هو **نفس تصميم Android على فرع `main`**: مهمة · برنامج · خدمات · استكشف · بروتوكول · مساعد (٦ تابات للضيف) + فريق المراسم (٤ تابات). تبديل الدور والوضع في الهيدر.

> **تغيير 2026-11-12:** كان المصدر فرع `enhance` (تصميم محسّن: شاشة إعداد، ٤ أدوار، «المزيد»، السائق، الإعدادات). **دلوقتي المرجع هو `main`** — يعني التصميم الأصلي. شوف `05-ENHANCED-DESIGN.md` للفروق.

## الملفات

| الملف | المحتوى |
|---|---|
| `00-README.md` | الملف ده: الصورة العامة، حالة المشروع، القرارات المفتوحة |
| `01-DESIGN-SPEC.md` | مواصفات الديزاين (ألوان، خطوط، مكوّنات، شاشات) — منقول من Android كما هو |
| `02-RULES.md` | قواعد iOS الملزمة + سجل القرارات |
| `03-PHASES.md` | خطة التنفيذ (Phase 0 → 18) |
| `04-DEMO-DATA.md` | بيانات الوضعين حرفياً — منقول من Android كما هو |
| `05-ENHANCED-DESIGN.md` | **تاريخي** — تصميم فرع `enhance` (مش المرجع) + جدول الفرق بين الفرعين |
| `06-ANDROID-REFERENCE.md` | خريطة: كل ملف Kotlin في Android ← مقابله في Swift |
| `07-RELEASE.md` | الإصدار (TestFlight) و checklist المراجعة اليدوية |
| `08-ALL-ROLES-PLAN.md` | خطة التطبيق الواحد لكل الأدوار (البوابة + تبديل المستخدم + بيانات محلية) — Phases 10–18 |
| `09-DATA-MODEL.md` | نموذج البيانات، الحذف المتسلسل، مين يشوف إيه، خريطة الشاشات |
| `design-reference/` | مصدر الديزاين الأصلي (CSS + JS) للمراجعة |

## المراجع

- **مصدر الديزاين: كود Android مباشرة** — `D:\private\new project\mrasem`، **branch `main`** (ريبو `joe772002/mrasem`). الألوان والمقاسات والنصوص والترتيب والسلوك بتتاخد من ملفات Kotlin و`strings.xml` زي ما هي، مش من الويب.
- ريبو iOS: https://github.com/joe772002/mrasem-ios.git
- للرجوع عند الشك فقط: الديزاين الأصلي https://claude.ai/artifact/Gg4iccc4Y1qqbwAV7d2d52 وكانفس التحسين https://claude.ai/artifact/PNNaXBfzvj6p29SZwE6dHg

## حالة المشروع الحالي (آخر تحديث 2026-11-12 — Phase 0–9 CI أخضر ✅؛ Phase 10–12 مكتوبين ومتعملهم push، بانتظار نتيجة الـ CI)

- SwiftUI، **٧٩ ملف Swift** (كانوا 102)، target واحد اسمه `WantProcuration` + **test target** `WantProcurationTests`.
- النمط: `View` + `ViewModel: ObservableObject` (MVVM)، و`AppManager` كـ `@StateObject` للغة والثيم.
- التنقل: مكتبة `SwiftfulRouting` (`RouterView`).
- المكتبات (SPM): `SwiftfulRouting`، `SwiftfulUI`، `IQKeyboardManager`.
- الشبكة: `Networking/APIClient.swift` (async/await فوق URLSession) — موجود بس مش مستخدم في مراسم.
- المشروع `objectVersion = 77` بـ **File System Synchronized Groups**: أي ملف يتضاف أو يتمسح من فولدر `WantProcuration/` بيظهر في Xcode لوحده، من غير تعديل `project.pbxproj`. ده اللي بيخلّي الشغل من Windows ممكن.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0`، Swift 5.
- Bundle ID: `com.informatiqueComp.mrasem` (اتغيّر في Phase 9 — كان بتاع التوكيل) · **اسم العرض: «مراسم»** · الإصدار 1.07.
- الخطوط: Cairo (6 أوزان، قديمين) + **Reem Kufi** + **IBM Plex Sans Arabic** (4 أوزان) — كلهم مسجّلين في `UIAppFonts`.
- النصوص: `Localizable.xcstrings` — **204 مفتاح** (13 بتوع الكود القديم اللي فضل + 190 `mrasem_*` منقولة حرفياً من Android `main` + `mrasem_placeholder_message` المؤقت)، `sourceLanguage = ar`.
- الـ Folder **repo على GitHub**: `https://github.com/joe772002/mrasem-ios.git`.
- **CI شغال بـ ٣ jobs:** `Build` (simulator) · `Unit tests` (٥٠ اختبار + ٨ بتوع الـ Shell + ٥ بتوع Mission/Plan + ٥ بتوع Explore/Services + ٧ بتوع Protocol/Assistant + ٥ بتوع الفريق + ٥ سيناريوهات الربط) · `Launch the app` (smoke test). آخر run أخضر: بعد Phase 9 + تغيير الـ Bundle ID (commit `7ee3ad7`).
- كود مراسم كله تحت `WantProcuration/Mrasem/` (قاعدة A9):
  `Theme/` (4) · `Icons/` (2) · `Components/` (12) · `Data/` (5) · `Domain/` (9) · `Shell/` (7) · `Screens/Gallery/` (1) · `Screens/Mission/` (3) · `Screens/Plan/` (2) · `Screens/Explore/` (2) · `Screens/Services/` (2) · `Screens/Protocol/` (2) · `Screens/Assistant/` (2) · `Screens/Team/` (10) · `Util/` (4) · `MrasemContainer.swift` · `MrasemAppContext.swift`
- الاختبارات في `WantProcurationTests/` (١٥ ملف: ٥٠ اختبار منقولة من Android + ٨ للـ Shell + ٥ لـ Mission/Plan + ٥ لـ Explore/Services + ٧ لـ Protocol/Assistant + ٥ لـ Team).

## قيد مهم: مفيش Mac

الكود بيتكتب من Windows، ومفيش Swift compiler هنا، فـ **أي Phase بيتسلّم من غير build**. التحقق الفعلي له طريقين:

1. **CI على GitHub Actions** (runner `macos-26` · Xcode 26.6): بيعمل `xcodebuild build` على كل push. **ده شغال فعلاً من Phase 0** — آخر build كان `BUILD SUCCEEDED` بصفر warnings في كود مراسم. والـ `test` job اتضاف في Phase 2.
2. Mac في السحابة أو Codemagic للتشغيل على Simulator و TestFlight.

عشان كده الـ CI هو بوابة التسليم — أي Phase بيتبعت بـ CI أخضر أو مش بيتسلّم.

## القرارات المفتوحة (الافتراضي بين قوسين)

> القرار #1 اتاخد: **Bundle ID جديد `com.informatiqueComp.mrasem`** (Phase 9)، واسم العرض «مراسم». باقي القرارات ماشي على الافتراضي.

| # | القرار | الافتراضي |
|---|---|---|
| 1 | الـ Bundle ID واسم الـ target | ✅ **اتحسم** — Bundle ID جديد `com.informatiqueComp.mrasem` (تطبيق مستقل عن التوكيل، Tests: `com.informatiqueComp.mrasemTests`)، واسم العرض «مراسم». اسم الـ target `WantProcuration` زي ما هو |
| 2 | كود التوثيق | يتحذف **الخاص بالتوثيق بس**، والأركيتكتشر تفضل (الشبكة، الـ Extensions، مكوّنات الفورم، `AppManager`، `LocationManager`، المكتبات) — نفس قرار Android النهائي |
| 3 | البيانات | محلية ورا Repository، منقولة حرفياً من `04-DEMO-DATA.md` |
| 4 | اللغة | عربي RTL فقط |
| 5 | الحد الأدنى للنظام | يفضل iOS 26.0 زي المشروع. لو عايز أجهزة أقدم قول الرقم قبل Phase 2 |
| 6 | الخطوط | ✅ Reem Kufi + IBM Plex Sans Arabic اتنقلوا من Android في Phase 1، و Cairo يفضل للمكوّنات القديمة |
| 7 | الاختبارات | منطق الأعمال Foundation فقط + test target يتضاف من Xcode/CI في Phase 2 |
| 8 | الحفظ الدائم | `UserDefaults` (الموجود): الدور والوضع، آخر تاب، الإشعارات، الثيم |

## الخطوة الجاية

Phase 0–9 خلصوا بـ CI أخضر. Phase 10–18 مكتوبين (نتيجة الـ CI مش متأكدة، ومفيش compiler عندنا). **Phase 13** ربط التطبيق بالقاعدة المحلية: شاشة البداية (حمّل بيانات العرض / ابدأ فارغاً) ← «اختر المستخدم» ← Shell بتابات حسب الدور.

1. شوف الـ CI. لو فيه `error:` ابعته.
2. المراحل كلها اتكتبت. الباقي: CI أخضر، والمراجعة اليدوية من `07-RELEASE.md`، وTestFlight (حساب Apple Developer + الـ Secrets).
