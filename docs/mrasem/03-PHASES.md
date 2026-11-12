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

**الحالة (2026-11-12): خلص، والـ CI أخضر — ٥٠ اختبار ناجح** (مطابقة ١:١ لاختبارات Android الحقيقية؛ الـ ٥١ هناك بتشمل اختبار القالب الفاضي `addition_isCorrect`).
- **الـ Data:** `MissionModels` (مع `MrasemDate` بدل `LocalDate`) · `MrasemState` (دورين + ٦/٤ تابات) · `MrasemDemoData` (الوضعين حرفياً) · `MissionRepository` + `InMemoryMissionRepository` (فوق `CurrentValueSubject`) · `MrasemPreferences` (UserDefaults).
- **الـ Domain:** ٨ Strategies + Selectors، كلها Foundation بس. `MrasemContainer` بيجمّع الاعتماديات (بديل Hilt).
- **الـ Tests:** ٩ ملفات منقولة من Android بنفس الأسماء والحالات — ٤٧ اختبار.
- **test target** اتضاف للـ project والـ scheme، والـ CI بقى فيه ٣ jobs: `Build` · `Unit tests` · `Launch the app` (smoke test بيشغّل التطبيق في الـ simulator ويشوف إنه ما كرش).
- **عطل مهم اتحل:** التطبيق بيستخدم `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`، فطبقة الـ Domain اتسمّت `nonisolated` — تفكيك class من غير الـ main thread كان بيعمل hop للـ main actor والـ hop ده كان بيكرش الـ test host. التفاصيل في سجل القرارات.

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

**الحالة (2026-11-12): الكود اتكتب ومحتاج CI أخضر (متحقق منه بالقراءة بس — مفيش compiler عندنا).**
- **`Shell/`:** `MrasemDestination` (١٠ وجهات + `ShellUiState`، كله `nonisolated` وبدون SwiftUI عشان يتختبر) · `MrasemSessionViewModel` (Combine فوق `statePublisher`؛ بيرجّع آخر تاب الأول وبعدين يسمع ويحفظ، زي `restore` ثم `drop(1)` في Android) · `MrasemToastBus` + `UiText`/`ToastMessage` · `MrasemShell` · `MrasemPlaceholderScreen` (بقى بياخد مفتاح العنوان).
- **`MrasemAppContext`:** بديل Hilt للـ UI — بيمسك الـ container والـ toast bus والـ shell VM، والـ Shell بيمرّره لكل وجهة (كل شاشة هتبني الـ ViewModel بتاعها منه في Phases 4–7).
- **`Components/MrasemNotices.swift`:** `MrasemNoticesSection` + `mrasemNoticeText` + `mrasemDressOptionLabel`.
- **`Util/MrasemStrings.swift`:** `mrasemString(key, args)` بديل `stringResource` (ترقيم `%1$@`).
- **السبلاش ← الـ Shell** في `WantProcurationApp`؛ الـ container بيتبني جوه `@StateObject` فمش بيتبني في الـ unit-test host.
- **إصلاحات في أساس Phase 0/1 اتلقت وقت المراجعة:** مفتاح `mrasem_role_guest` كان ناقص من الـ catalog · `mrasem_notice_postponed` كان فيه `\"` حرفية بتظهر في النص · اتشال ٧٣ مفتاح من فرع `enhance` (إعدادات/سائق/إعداد/المزيد) مش مستخدمين · الهيدر والـ bottom bar بقوا بيمدّوا خلفيتهم تحت الـ safe area.
- **`ShellStateTests`:** ٨ اختبارات (وجهات، حالة الـ Shell، كل مفاتيح الـ strings بتتحل، `UiText` بمتغيّرات، نصوص كل التنبيهات، الـ toast bus).

---

## Phase 4 — المهمة + البرنامج

- `MissionScreen`: Notices، Hero، حالة الوصول (4 خطوات و4 toasts)، المستقبِل (اتصال/واتساب)، السيارة (لوحة)، الموقع (خريطة + فتح في الخرائط)، الإقامة، بطاقة المرور (QR)، الطوارئ. pill «محدَّث».
- `PlanScreen`: DayTabs، الـ timeline بأنواعه الثلاثة، chip البروتوكول، chips الوقت الحر ← استكشف.
- `ContactLinks` + `ExternalLinks` (`tel:`, `wa.me`, خرائط Google؛ `UIApplication.open` مع تجاهل الفشل).

**القبول:** مطابقة الوضعين؛ دورة الوصول كاملة؛ الروابط بتفتح.

**الحالة: ✅ مكتوب (بانتظار CI أخضر).** `Screens/Mission/{MissionViewModel,MissionScreen,MissionCards}.swift` و`Screens/Plan/{PlanViewModel,PlanScreen}.swift`، متوصلين بالـ Shell. الاختبارات: `MissionPlanStateTests` (toasts الوصول الأربعة، `MissionUiState`/`PlanUiState` مع الـ repository، توجيه chips البرنامج، وجود كل مفاتيح النصوص). `ContactLinks`/`ExternalLinks` اتنقلوا في Phase 2 وبيتنادوا من الشاشات.

---

## Phase 5 — استكشف + الخدمات

- `ExploreScreen`: كارت «حول {الفندق}» + الفلاتر الخمسة، كروت الأماكن، دورة الطلب + toast.
- `ServicesScreen`: الفئات، صف الخدمة بزر «فتح»، «معلومات سريعة»، سطر الغرفة.

**القبول:** نتائج الفلاتر مطابقة (8 الدوحة / 4 لندن)؛ الطلب بيظهر في الحالة.

**الحالة: ✅ مكتوب (بانتظار CI أخضر).** `Screens/Explore/{ExploreViewModel,ExploreScreen}.swift` و`Screens/Services/{ServicesViewModel,ServicesScreen}.swift`، متوصلين بالـ Shell. `ExploreScreen`: كارت «حول الفندق» + شريط الفلاتر الأفقي، كروت الأماكن بالميتا (دقائق/مدة/VIP) وزر بثلاث حالات، toast الطلب. `ServicesScreen`: كارت لكل فئة، `MrasemServiceRow` بزر «فتح» (`ExternalLinks.open`)، «معلومات سريعة»، سطر الغرفة. الاختبارات: `ExploreServicesStateTests` (٥).

---

## Phase 6 — البروتوكول + المساعد

- `ProtocolScreen`: بطاقة الـ ٣٠ ثانية، زي اليوم (الرسمتين والعمودين)، قائمة الفحص بالعدّاد، الأعراف، chips الدليل + toast.
- `AssistantScreen`: الترحيب، المحادثة مع scroll لآخر رسالة (`ScrollViewReader`)، الأسئلة الجاهزة، الإدخال مع الكيبورد، التحويل للمنسق.

**القبول:** القواعد الـ 8 + التحويل بنفس نصوص المصدر في الوضعين؛ الـ checks لكل وضع.

**الحالة: ✅ مكتوب (بانتظار CI أخضر).** `Screens/Protocol/{ProtocolViewModel,ProtocolScreen}.swift` و`Screens/Assistant/{AssistantViewModel,AssistantScreen}.swift` + `Components/MrasemAssistantText.swift` (`mrasemAssistantReplyText`)، متوصلين بالـ Shell. `ProtocolScreen`: بطاقة الـ ٣٠ ثانية، الزي بالرسمة والعمودين، قائمة الفحص بالعدّاد، الأعراف، chips الدليل + toast. `AssistantScreen`: المحادثة والأسئلة الجاهزة (`MrasemFlowLayout`) وحقل الإدخال، وتمرير لآخر المحادثة عن طريق `MrasemScreenContent(scrollToEndTrigger:)`. الاختبارات: `ProtocolAssistantStateTests` (٧).

---

## Phase 7 — فريق المراسم

- `TeamHeader`: 3 KPIs + chips الأقسام.
- `TeamVisitScreen` (8 حقول، LTR للهاتف واللوحة)، `TeamChangesScreen` (تأجيل 30 دقيقة + تنبيه عام)، `TeamRequestsScreen`، `TeamArchiveScreen`.
- اختبار الربط: الخمس سيناريوهات في الوضعين (`TeamGuestLinkingTests`).

**القبول:** السيناريوهات الخمسة ناجحة؛ النصوص مطابقة.

**الحالة: ✅ مكتوب (بانتظار CI أخضر).** `Screens/Team/`: `TeamHeader` (+ `TeamHeaderUi`) و`TeamVisit`/`TeamChanges`/`TeamRequests`/`TeamArchive` (ViewModel + Screen لكل واحدة) و`TeamPreviewData`، متوصلين بالـ Shell. نموذج الزيارة: 7 حقول + زي اليوم في عمودين، الهاتف واللوحة LTR، والمسودة بتتصفّر لما حالة المصدر تتغير. التأجيل والتنبيه العام والترتيب بنفس توستات Android. سيناريوهات الربط الخمسة كانت موجودة في `TeamGuestLinkingTests` (الوضعين) وبقى معاها `TeamStateTests` (٥).

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
