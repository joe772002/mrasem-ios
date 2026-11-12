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
| `03-PHASES.md` | خطة التنفيذ (Phase 0 → 8) |
| `04-DEMO-DATA.md` | بيانات الوضعين حرفياً — منقول من Android كما هو |
| `05-ENHANCED-DESIGN.md` | **تاريخي** — تصميم فرع `enhance` (مش المرجع) + جدول الفرق بين الفرعين |
| `06-ANDROID-REFERENCE.md` | خريطة: كل ملف Kotlin في Android ← مقابله في Swift |
| `design-reference/` | مصدر الديزاين الأصلي (CSS + JS) للمراجعة |

## المراجع

- **مصدر الديزاين: كود Android مباشرة** — `D:\private\new project\mrasem`، **branch `main`** (ريبو `joe772002/mrasem`). الألوان والمقاسات والنصوص والترتيب والسلوك بتتاخد من ملفات Kotlin و`strings.xml` زي ما هي، مش من الويب.
- ريبو iOS: https://github.com/joe772002/mrasem-ios.git
- للرجوع عند الشك فقط: الديزاين الأصلي https://claude.ai/artifact/Gg4iccc4Y1qqbwAV7d2d52 وكانفس التحسين https://claude.ai/artifact/PNNaXBfzvj6p29SZwE6dHg

## حالة المشروع الحالي (آخر تحديث 2026-11-12 — بعد Phase 2)

- SwiftUI، **٧٠ ملف Swift** (كانوا 102)، target واحد اسمه `WantProcuration` + **test target** `WantProcurationTests`.
- النمط: `View` + `ViewModel: ObservableObject` (MVVM)، و`AppManager` كـ `@StateObject` للغة والثيم.
- التنقل: مكتبة `SwiftfulRouting` (`RouterView`).
- المكتبات (SPM): `SwiftfulRouting`، `SwiftfulUI`، `IQKeyboardManager`.
- الشبكة: `Networking/APIClient.swift` (async/await فوق URLSession) — موجود بس مش مستخدم في مراسم.
- المشروع `objectVersion = 77` بـ **File System Synchronized Groups**: أي ملف يتضاف أو يتمسح من فولدر `WantProcuration/` بيظهر في Xcode لوحده، من غير تعديل `project.pbxproj`. ده اللي بيخلّي الشغل من Windows ممكن.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0`، Swift 5.
- Bundle ID: `com.informatiqueComp.reserveProcuration2` · **اسم العرض: «مراسم»** · الإصدار 1.07.
- الخطوط: Cairo (6 أوزان، قديمين) + **Reem Kufi** + **IBM Plex Sans Arabic** (4 أوزان) — كلهم مسجّلين في `UIAppFonts`.
- النصوص: `Localizable.xcstrings` — **276 مفتاح** (13 بتوع الكود القديم اللي فضل + 263 `mrasem_*` منقولة حرفياً من Android)، `sourceLanguage = ar`.
- الـ Folder **repo على GitHub**: `https://github.com/joe772002/mrasem-ios.git`.
- **CI شغال بـ ٣ jobs:** `Build` (simulator) · `Unit tests` (٤٧ اختبار) · `Launch the app` (smoke test). آخر run: كلهم أخضر.
- كود مراسم كله تحت `WantProcuration/Mrasem/` (قاعدة A9):
  `Theme/` (4) · `Icons/` (2) · `Components/` (11) · `Data/` (5) · `Domain/` (9) · `Shell/` (2) · `Screens/Gallery/` (1) · `Util/` (3) · `MrasemContainer.swift`
- الاختبارات في `WantProcurationTests/` (٩ ملفات، ٤٧ اختبار).

## قيد مهم: مفيش Mac

الكود بيتكتب من Windows، ومفيش Swift compiler هنا، فـ **أي Phase بيتسلّم من غير build**. التحقق الفعلي له طريقين:

1. **CI على GitHub Actions** (runner `macos-26` · Xcode 26.6): بيعمل `xcodebuild build` على كل push. **ده شغال فعلاً من Phase 0** — آخر build كان `BUILD SUCCEEDED` بصفر warnings في كود مراسم. الـ `test` job هيتضاف مع test target في Phase 2.
2. Mac في السحابة أو Codemagic للتشغيل على Simulator و TestFlight.

عشان كده الـ CI هو بوابة التسليم — أي Phase بيتبعت بـ CI أخضر أو مش بيتسلّم.

## القرارات المفتوحة (الافتراضي بين قوسين)

> القرار #1 اتاخد: **الـ Bundle ID سيب زي ما هو**، واسم العرض بقى «مراسم». باقي القرارات ماشي على الافتراضي.

| # | القرار | الافتراضي |
|---|---|---|
| 1 | الـ Bundle ID واسم الـ target | ✅ **اتحسم** — Bundle ID زي ما هو (`com.informatiqueComp.reserveProcuration2`)، واسم العرض «مراسم». تحذير: لو اترفع على نفس حساب Apple بنفس الـ Bundle ID هيبقى تحديث لتطبيق التوكيل، مش تطبيق جديد |
| 2 | كود التوثيق | يتحذف **الخاص بالتوثيق بس**، والأركيتكتشر تفضل (الشبكة، الـ Extensions، مكوّنات الفورم، `AppManager`، `LocationManager`، المكتبات) — نفس قرار Android النهائي |
| 3 | البيانات | محلية ورا Repository، منقولة حرفياً من `04-DEMO-DATA.md` |
| 4 | اللغة | عربي RTL فقط |
| 5 | الحد الأدنى للنظام | يفضل iOS 26.0 زي المشروع. لو عايز أجهزة أقدم قول الرقم قبل Phase 2 |
| 6 | الخطوط | ✅ Reem Kufi + IBM Plex Sans Arabic اتنقلوا من Android في Phase 1، و Cairo يفضل للمكوّنات القديمة |
| 7 | الاختبارات | منطق الأعمال Foundation فقط + test target يتضاف من Xcode/CI في Phase 2 |
| 8 | الحفظ الدائم | `UserDefaults` (الموجود): الدور والوضع، آخر تاب، الإشعارات، الثيم |

## الخطوة الجاية

Phase 0 و 1 و 2 خلصوا، والـ CI أخضر بالكامل (build + ٤٧ اختبار + تشغيل التطبيق).

1. **Phase 3 — الهيكل والتنقل:** `MrasemContainer` + `MrasemShell` + `MrasemDestination` + `MrasemSessionViewModel` + `ToastBus` + `NoticesSection` + ١٠ وجهات placeholders.
2. **قبل Phase 3:** محتاجين قرار واحد — هل هنبدأ بـ **سجل شاشة (Sheet)** للوجهة (زي ما Android بيعمل) ولا **NavigationStack**؟ الـ iOS plan بيقول إن التنقل بين التابات **حالة** مش push، بس الشاشة الكاملة subdestination ممكن تـ push.

قول «ابدا phase 3» ونمشي.
