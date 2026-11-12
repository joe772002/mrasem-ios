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

## حالة المشروع الحالي (اتفحص 2026-11-12)

- SwiftUI، 102 ملف Swift، target واحد اسمه `WantProcuration`، **من غير test target**.
- النمط: `View` + `ViewModel: ObservableObject` (MVVM)، و`AppManager` كـ `@StateObject` للغة والثيم.
- التنقل: مكتبة `SwiftfulRouting` (`RouterView`).
- المكتبات (SPM): `SwiftfulRouting`، `SwiftfulUI`، `IQKeyboardManager`.
- الشبكة: `Networking/APIClient.swift` (async/await فوق URLSession).
- المشروع `objectVersion = 77` بـ **File System Synchronized Groups**: أي ملف يتضاف أو يتمسح من فولدر `WantProcuration/` بيظهر في Xcode لوحده، من غير تعديل `project.pbxproj`. ده اللي بيخلّي الشغل من Windows ممكن.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0`، Swift 5.
- Bundle ID: `com.informatiqueComp.reserveProcuration2` · الاسم: «أرغب في عمل توكيل» · الإصدار 1.07.
- الخطوط: Cairo (6 أوزان). الألوان: Asset Catalog + `Color.theme`.
- النصوص: `Localizable.xcstrings` (اللغة المصدر `en`).
- الفولدر **مش git repo** لسه.

## قيد مهم: مفيش Mac

الكود بيتكتب من Windows، ومفيش Swift compiler هنا، فـ **أي Phase بيتسلّم من غير build**. التحقق الفعلي له طريقين:

1. **CI على GitHub Actions** (runner macOS): بيعمل `xcodebuild build` و`test` على كل push. ده بيتظبط في Phase 0 أول ما الريبو يتعمل.
2. Mac في السحابة أو Codemagic للتشغيل على Simulator و TestFlight.

لحد ما واحد منهم يشتغل، أخطاء الـ compile هتتراكم ومش هتبان. عشان كده الريبو والـ CI لازم يكونوا قبل Phase 1.

## القرارات المفتوحة (الافتراضي بين قوسين)

| # | القرار | الافتراضي |
|---|---|---|
| 1 | الـ Bundle ID واسم الـ target | **يفضلوا زي ما هم** (زي ما الـ package فضل في Android)، واسم العرض يبقى «مراسم». تحذير: لو اترفع على نفس حساب Apple بنفس الـ Bundle ID هيبقى تحديث لتطبيق التوكيل، مش تطبيق جديد |
| 2 | كود التوثيق | يتحذف **الخاص بالتوثيق بس**، والأركيتكتشر تفضل (الشبكة، الـ Extensions، مكوّنات الفورم، `AppManager`، `LocationManager`، المكتبات) — نفس قرار Android النهائي |
| 3 | البيانات | محلية ورا Repository، منقولة حرفياً من `04-DEMO-DATA.md` |
| 4 | اللغة | عربي RTL فقط |
| 5 | الحد الأدنى للنظام | يفضل iOS 26.0 زي المشروع. لو عايز أجهزة أقدم قول الرقم قبل Phase 1 |
| 6 | الخطوط | Reem Kufi + IBM Plex Sans Arabic (نفس ملفات Android)، و Cairo يفضل للمكوّنات القديمة |
| 7 | الاختبارات | منطق الأعمال Foundation فقط + test target يتضاف من Xcode/CI في Phase 2 |
| 8 | الحفظ الدائم | `UserDefaults` (الموجود): الدور والوضع، آخر تاب، الإشعارات، الثيم |

## الخطوة الجاية

اعمل الريبو على GitHub وابعتلي الرابط، وبعدها «ابدا phase 0».
