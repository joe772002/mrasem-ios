# 03 — خطة التنفيذ iOS (Phases)

كل Phase يتسلّم لوحده ويتراجع قبل اللي بعده. معيار القبول العام في `02-RULES.md` قسم E.

> **مصدر التصميم: فرع `main` في مشروع Android** (`D:\private\new project\mrasem`).
> القرار اتغيّر يوم 2026-11-12 — كانت `enhance`. الفرق اللي بيلفّر الخطة:
> **مفيش** شاشة إعداد ولا أدوار الأربعة ولا تاب «المزيد» ولا السائق ولا الإعدادات.
> الهيكل النهائي: **٢ دور** (ضيف / فريق مراسم) · **٦ تابات** للضيف · **٤ تابات** للفريق.

| Phase | العنوان | الناتج |
|---|---|---|
| 0 | التنظيف والتجهيز | مشروع نظيف بيبني على CI وبيفتح على شاشة فاضية بهوية مراسم |
| 1 | Design System | الثيم + الخطوط + الأيقونات + كل المكوّنات بـ previews |
| 2 | البيانات والمنطق | Models + بيانات الوضعين + Repository + Strategies + tests |
| 3 | الهيكل والتنقل | Splash ← Shell (الهيدر، الـ bottom bar، Toast، Notices) |
| 4 | المهمة + البرنامج | شاشتين |
| 5 | استكشف + الخدمات | شاشتين |
| 6 | البروتوكول + المساعد | شاشتين |
| 7 | فريق المراسم | 4 تابات + الربط مع عرض الضيف |
| 8 | المراجعة والتنظيف | مطابقة شاشة بشاشة + Accessibility + حذف القديم + release build |

---

## قبل Phase 0 (عليك)

1. اعمل ريبو فاضي على GitHub (private) وابعت الرابط.
2. قرّر القرارات المفتوحة في `00-README.md` لو مش عايز الافتراضي — خصوصاً #1 (Bundle ID) و #5 (أقل إصدار iOS).

---

## Phase 0 — التنظيف والتجهيز

**الهدف:** إزالة التوثيق وتجهيز أرضية بتبني.

- `git init` + أول commit للحالة الحالية (قبل أي حذف) + ربط الـ remote.
- **CI:** `.github/workflows/ios.yml` — على runner macOS: `xcodebuild -scheme WantProcuration -destination 'generic/platform=iOS Simulator' build` من غير signing. ده بديل الـ Mac في التحقق.
- فحص الاعتماديات، ثم حذف الخاص بالتوثيق. القائمة المبدئية:
  - `AI/` (TransactionMatcher, TransactionDebugTools)
  - `Features/Assistant/` (الـ Gateway والصوت) · `Features/Booking/` · `Features/FAQ/`
  - `Intents/` (Siri/App Intents بتاعة الحجز والمكاتب)
  - `Models/` (Government, Office) · `Preview/PreviewData.swift`
  - `Views/Home/` · `Views/OfficeListView/` · `Views/Reservation/` · `Views/OtherServices/OtherServicesView.swift` · `Views/VersionCheck/` · `Views/Settings/`
  - `Managers/VersionManager.swift` · `Components/IDScanner/` · `_to_delete/`
  - مفاتيح `Info.plist`: `AppSigningSecret`, `AIGatewayURL`, `AIGatewayToken`, `INAlternativeAppNames` · ومتغيرات الـ Gateway في `Config/`
  - نصوص التوثيق من `Localizable.xcstrings` (الغير مستخدمة بعد الحذف)
- **يفضل:** `Networking/APIClient` · `Extensions/*` · `Components/FormComponents` · `AlertComponents` · `NavigationComponents` · `CircleButtonView` · `DataModel/*` · `AppManager` · `LocationManager` · `Logger` · `WebViewScreen` · خطوط Cairo · المكتبات.
- `WantProcurationApp`: إزالة `IntentRoutingModifier` و`HomeScreenView`، وإزالة الـ force-unwrap بتاع الخط، وفتح placeholder بهوية مراسم. RTL و`ar` ثابتين.
- اسم العرض «مراسم» (`INFOPLIST_KEY_CFBundleDisplayName`) — ده التعديل الوحيد المسموح في `project.pbxproj` (قيمة نصية واحدة في موضعين).
- `LaunchScreen`: خلفية عنّابية + «مراسم» مؤقتاً.

**القبول:** CI أخضر، التطبيق يفتح على placeholder، صفر references للكود المحذوف (`grep`).

**الحالة (2026-11-12): خلص، والـ CI أخضر.**
- **الـ CI اشتغل فعليًا:** `macos-26` · Xcode 26.6 · `** BUILD SUCCEEDED **` · صفر errors. أول build وقع بسبب `%s` في الـ catalog (شوف Decision log) واتصلّح في commit تاني.
- **اتحذف (٦٨ ملف Swift):** `AI/` · `Features/` (Assistant + Booking + FAQ) · `Intents/` · `Models/` · `Preview/` · `Views/Home/` · `Views/OfficeListView/` · `Views/Reservation/` · `Views/OtherServices/OtherServicesView.swift` · `Views/VersionCheck/` · `Views/Settings/` · `Managers/VersionManager.swift` · `Components/IDScanner/` · `_to_delete/`.
- **اتحفظ (زي ما هو):** `Networking/APIClient` · `Extensions/*` · `Components/FormComponents` · `AlertComponents` · `NavigationComponents` · `CircleButtonView` · `DataModel/*` · `AppManager` · `LocationManager` · `Logger` · `WebViewScreen` · خطوط Cairo · المكتبات الثلاث.
- **نقل (مش حذف):** أنواع الـ pickers (`TransactionCategory` · `TransactionType` · `ReservationDate` · `ReservePeriod` · `ReservationTime`) اتنقلت لـ `Components/FormComponents/ReservationPickerModels.swift` — لأن `DynamicFormField` لسه بيحتاجها، وبكده ما بقى فيه مجلد `Views/Reservation/` خالص.
- **اتكتب جديد:** `WantProcuration/Mrasem/Theme/MrasemBrand.swift` (مؤقت، يتشال في Phase 1) · `Mrasem/Shell/MrasemSplash.swift` · `Mrasem/Shell/MrasemPlaceholderScreen.swift`.
- **`WantProcurationApp.swift` اتكتب من جديد:** اتشال `IntentRoutingModifier` و`HomeScreenView`، والـ force-unwrap للخط بقى `if let`، والاتجاه واللغة ثابتين (`ar` + RTL)، والـ splash بيعرض ١.٥ ثانية وبعدها الـ placeholder.
- **`Info.plist`:** اتشال `AppSigningSecret` · `AIGatewayURL` · `AIGatewayToken` · `INAlternativeAppNames`.
- **`project.pbxproj`:** `INFOPLIST_KEY_CFBundleDisplayName` بقى «مراسم» (موضعين)، واتشال `NSCameraUsageDescription` · `NSMicrophoneUsageDescription` · `NSSpeechRecognitionUsageDescription` · `NSPhotoLibraryUsageDescription` (ميزاتها اتحذفت). مكان `INFOPLIST_FILE` والباقي ما اتغيّرش.
- **`Config/`:** `App.xcconfig` اتمسح منه الـ secret، و`Secrets.example.xcconfig` اتحذف (مفيش أسرار دلوقتي).
- **`Localizable.xcstrings`:** اتقص من ٢٥٩ لـ ٢٧٦ مفتاح — ١٣ مفتاح لسه مستخدم في الكود اللي فضل + ٢٦٣ مفتاح `mrasem_*` منقولة حرفياً من Android. `sourceLanguage` بقى `ar` (أندرويد بيحط العربي في `values/` و`values-ar/` مع بعض).
- **CI:** `.github/workflows/ios.yml` — runner `macos-26`، `xcodebuild build` على simulator من غير signing. مفيش test job لسه (Phase 2).

---

## Phase 1 — Design System

- **الخطوط:** نسخ `reem_kufi.ttf` و IBM Plex Sans Arabic (4 أوزان) من مشروع Android لـ `Fonts/`، وتسجيلها في `UIAppFonts`. التحقق من أسماء الـ PostScript الفعلية.
- **الثيم:** `MrasemColors` (Light/Dark بكل الـ tokens بتاع `main`)، `MrasemType` (نفس أسماء Android)، `MrasemShapes`/`MrasemDimens`، و`EnvironmentKey` واحد `\.mrasem`.
- **الأيقونات:** `MrasemIcons` — محوّل صغير لمسارات SVG (M/L/H/V/A/Z وصغيرها) لـ `Path`، والأيقونات الـ 9 بنفس المسارات.
- **المكوّنات:** Card, HeroCard, Pill, StatTile, KpiTile, KeyValueList, Button (Primary/Secondary/Ghost/Outline + block), Chip, Segmented, AvatarInitial, PlateBadge, StatusSteps, DayTabs, TimelineItem (عادي/changed/وقت حر), FreeTimeItem, ServiceRow, ActionRow, PlaceCard, NoticeBanner, Toast, ChecklistRow, ChatBubble, AskBar, TextField (+LTR), Select.
- **الرسومات:** MapPreview, QrPlaceholder (نفس خوارزمية المصدر), DressIllustration.
- **الـ Chrome:** `MrasemHeader` (عنّابي + مفتاح الدور + مفتاح نوع المهمة) و`MrasemBottomBar` (شريط ثابت).
- `toArabicDigits()` و`toArabicNumber()`.

**القبول:** كل مكوّن له Preview Light/Dark؛ CI أخضر؛ مفيش لون أو خط خارج الثيم.

**الحالة (2026-11-12): خلص، والـ CI أخضر (BUILD SUCCEEDED، صفر warnings في كود مراسم).**
- **الثيم:** `MrasemColors` (Light/Dark + القيم المحسوبة) · `MrasemType` (٢٢ نمط) · `MrasemShapes` + `MrasemDimens` · `MrasemTheme` + `\.mrasem`.
- **الخطوط:** `ReemKufi` (خط متغيّر — بنستخدمه عن طريق CoreText ومحور `wght`) + `IBMPlexSansArabic-{Regular,Medium,SemiBold,Bold}`.
- **الأيقونات:** `SVGPath.swift` (محوّل SVG كامل مع تحويل الأقواس لـ bezier) + ٩ أيقونات.
- **المكوّنات:** ١٠ ملفات + `MrasemFlowLayout` + `MrasemKeyValueLayout` (قياس حقيقي زي Compose).
- **الرسومات:** MapPreview و QrPlaceholder و DressIllustration — كلهم بـ `Canvas` زي Android.
- **Gallery:** `Screens/Gallery/MrasemGalleryScreen.swift` بيعرض كل مكوّن (نسخة فاتح وداكن).
- **Previews:** `Components/MrasemPreviews.swift` — Light/Dark لكل مجموعة مكوّنات.
- `MrasemBrand.swift` اتحذف — السبلاش والـ placeholder بقوا على الثيم الحقيقي.

---

## Phase 2 — البيانات والمنطق

- **Models:** نفس `MissionModels.kt` و`MrasemState.kt` (structs/enums): `UserRole` بـ **قيمةتين** (Guest / Team)، `GuestTab` بـ ٦ تابات، `TeamTab` بـ ٤ تابات.
- **البيانات:** `MrasemDemoData.swift` — الوضعين حرفياً + الثوابت (الزي، قائمة الفحص، الدليل، أسئلة المساعد).
- **Repository:** `MissionRepository` protocol + `InMemoryMissionRepository`.
- **Preferences:** `MrasemPreferences` protocol + تنفيذ `UserDefaults` (lastGuestTab, lastTeamTab, mode).
- **Strategies:** Session, MissionSummary, Program, Explore, Assistant, VisitUpdate, Team, Protocol + Selectors (`recentNotices`, `displayName`, `officialCount`).
- **Tests:** test target `WantProcurationTests` (**خطوة عليك في Xcode، أو على الـ cloud Mac**: File › New › Target › Unit Testing Bundle) + نقل الـ 57 اختبار من Kotlin بنفس الأسماء والحالات. الـ CI يشغّل `xcodebuild test`.

**القبول:** كل الاختبارات ناجحة على CI؛ مطابقة البيانات بند بند مع `04-DEMO-DATA.md`.

---

## Phase 3 — الهيكل والتنقل

- `MrasemContainer` (تجميع الاعتماديات) + ربطه في `WantProcurationApp`.
- **البداية:** Splash ← الـ Shell مباشرة (مفيش شاشة إعداد — تبديل الدور والوضع في الهيدر).
- `MrasemShell`: الهيدر (عنّابي: العلامة + مفتاح الدور + مفتاح نوع المهمة) + محتوى الوجهة + الـ bottom bar الثابت + Toast host.
- `MrasemDestination` + `MrasemNav` (٦ تابات للضيف، ٤ للفريق) + `MrasemSessionViewModel` (الدور، الوضع، التبويب، إعادة الضبط).
- `ToastBus` (PassthroughSubject) + `UiText`. Toast: 3.8 ثانية، الجديد يلغي القديم.
- `NoticesSection` (آخر تنبيهين). سطر «بيانات توضيحية لنموذج أولي.» آخر كل شاشة.
- الوجهات placeholders لحد Phases 4–7.

**القبول:** التنقل بين تابات كل دور شغال؛ الهيدر والـ bar مطابقين Light/Dark؛ تبديل الدور بيبدّل الـ bar (٦ ↔ ٤).

---

## Phase 4 — المهمة + البرنامج

- `MissionScreen`: Notices، Hero، حالة الوصول (4 خطوات و4 toasts)، المستقبِل (اتصال/واتساب)، السيارة (لوحة)، الموقع (خريطة + فتح في الخرائط)، الإقامة، بطاقة المرور (QR)، الطوارئ. pill «محدَّث».
- `PlanScreen`: DayTabs، الـ timeline بأنواعه الثلاثة، chip البروتوكول، chips الوقت الحر ← استكشف.
- `ContactLinks` + `ExternalLinks` (`tel:`, `wa.me`, خرائط Google؛ `UIApplication.open` مع تجاهل الفشل).

**القبول:** مطابقة الوضعين؛ دورة الوصول كاملة؛ الروابط بتفتح.

---

## Phase 5 — استكشف + الخدمات

- `ExploreScreen`: كارت «حول {الفندق}» + الفلاتر الخمسة، كروت الأماكن، دورة الطلب + toast.
- `ServicesScreen`: الفئات، صف الخدمة بزر «فتح»، «معلومات سريعة»، سطر الغرفة.

**القبول:** نتائج الفلاتر مطابقة (8 الدوحة / 4 لندن)؛ الطلب بيظهر في الحالة.

---

## Phase 6 — البروتوكول + المساعد

- `ProtocolScreen`: بطاقة الـ ٣٠ ثانية، زي اليوم (الرسمتين والعمودين)، قائمة الفحص بالعدّاد، الأعراف، chips الدليل + toast.
- `AssistantScreen`: الترحيب، المحادثة مع scroll لآخر رسالة (`ScrollViewReader`)، الأسئلة الجاهزة، الإدخال مع الكيبورد، التحويل للمنسق.

**القبول:** القواعد الـ 8 + التحويل بنفس نصوص المصدر في الوضعين؛ الـ checks لكل وضع.

---

## Phase 7 — فريق المراسم

- `TeamHeader`: 3 KPIs + chips الأقسام.
- `TeamVisitScreen` (8 حقول، LTR للهاتف واللوحة)، `TeamChangesScreen` (تأجيل 30 دقيقة + تنبيه عام)، `TeamRequestsScreen`، `TeamArchiveScreen`.
- اختبار الربط: الخمس سيناريوهات في الوضعين (`TeamGuestLinkingTests`).

**القبول:** السيناريوهات الخمسة ناجحة؛ النصوص مطابقة.

---

## Phase 8 — المراجعة والتنظيف

- مراجعة شاشة بشاشة مع Android (Light/Dark، 375 و 430pt، Dynamic Type كبير).
- Accessibility: VoiceOver، مساحات اللمس، التباين.
- **الأيقونة:** نفس أيقونة Android (1024px في `AppIcon.appiconset`) + Launch Screen نهائي.
- تنظيف: `Localizable.xcstrings`، ألوان Asset القديمة الغير مستخدمة، رؤوس الملفات، كود التوثيق المتبقي.
- الإصدار: signing (حساب Apple Developer)، Archive، TestFlight — عبر Codemagic أو Mac في السحابة.
- تحديث الوثائق وسجل القرارات.

**القبول:** release build شغال؛ صفر references للتوثيق؛ checklist المطابقة كاملة.

---

## الاعتماديات

```
ريبو + CI → 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
               (1 و 2 ممكن يتبدلوا؛ 4–7 ترتيبهم مرن بعد 3؛ 7 قبل اختبار الربط)
```
