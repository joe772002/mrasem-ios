# 02 — قواعد iOS (Rules)

قواعد ملزمة في كل Phase. أي استثناء يتسجل في «سجل القرارات» آخر الملف. الترقيم مطابق لقواعد Android قدر الإمكان عشان المقارنة.

## A. الأركيتكتشر (نمشي على الموجود)

المسار الثابت لأي feature:

```
View (SwiftUI) → ViewModel (ObservableObject, @MainActor) → Strategy (Domain) → Repository (protocol + Impl) → DataSource
```

- **A1.** الـ View ما يعرفش غير الـ ViewModel بتاعه. ممنوع استدعاء Repository من View.
- **A2.** كل ViewModel `final class … : ObservableObject` عليه `@MainActor`، وبيعرض `@Published private(set) var state` واحد (struct). الشاشة = `XScreen` (بيملك الـ ViewModel) + `XContent(state:, actions)` من غير حالة، عشان الـ Preview.
- **A3.** منطق الأعمال في `Mrasem/Domain` — **Foundation (+ Combine للـ `statePublisher` بس)**، ممنوع `import SwiftUI`/`UIKit` عشان يتختبر ويتطابق مع Kotlin.
- **A4.** `MissionRepository` protocol + `InMemoryMissionRepository`. الحقن بالـ initializer، والتجميع في مكان واحد: `MrasemContainer`.
- **A5.** مصدر الحالة واحد لكل الأدوار: الـ Repository بيعرض `CurrentValueSubject<MrasemState, Never>`. ممنوع نسخ الحالة في ViewModel.
- **A6.** الدوال اللي ممكن تفشل `throws` أو `Result`، زي `APIClient` الحالي.
- **A7.** التنقل: `RouterView` (SwiftfulRouting) واحد في `WantProcurationApp`. جوّه الـ Shell الوجهات **حالة** (`MrasemDestination`) مش push — زي Android.
- **A8.** ممنوع مكتبة جديدة من غير موافقة. المتاح: SwiftUI، Combine، SwiftfulRouting، SwiftfulUI، IQKeyboardManager.
- **A9.** كل كود مراسم تحت `WantProcuration/Mrasem/`:

```
Mrasem/
  Theme/        MrasemColors · MrasemType · MrasemShapes · MrasemTheme
  Components/   المكوّنات المشتركة (ملف لكل مجموعة)
  Icons/        MrasemIcons (مسارات SVG الأصلية)
  Data/         Models · MrasemState · MrasemDemoData · MissionRepository · MrasemPreferences
  Domain/       الـ Strategies + Selectors
  Shell/        MrasemShell · MrasemDestination · MrasemSessionViewModel · MrasemToastBus · UiText
  Screens/      Mission · Plan · Services · Explore · Protocol · Assistant · Team (+ Gallery)
  Util/         ArabicDigits · ContactLinks · ExternalLinks · MrasemStrings
```

- **A10.** ممنوع تعديل `project.pbxproj` باليد. المشروع synchronized groups: إضافة/حذف الملفات من الفولدر كفاية. أي حاجة محتاجة Xcode (test target، capabilities، signing) تتكتب كخطوة للمستخدم.

## B. الـ UI ومطابقة الديزاين

- **B1.** مصدر الديزاين هو **كود Android (branch `main`) مباشرة**: كل شاشة ومكوّن بيتنقل من ملف Kotlin المقابل (`06-ANDROID-REFERENCE.md`) بنفس القيم والترتيب والنصوص. `01-DESIGN-SPEC.md` ملخص مساعدة؛ عند التعارض كود Android يكسب. ممنوع تغيير لون أو مقاس أو نص أو إضافة عنصر مش موجود في Android.
  - **`main` مش `enhance`:** فرع `enhance` فيه تصميم تاني (هيدر بالزخرفة، bottom bar عائم، شاشة إعداد، السائق، الإعدادات) — **مش** المرجع بتاعنا. قرار صاحب المشروع.
- **B2.** ممنوع `Color(red:…)` أو hex في الشاشات. كله من `MrasemColors` عبر `@Environment(\.mrasem)`. الاستثناءات: لوحة السيارة، شعارات الخدمات (من البيانات)، الرسومات.
- **B3.** ممنوع `.font(.system(size:))` أو اسم خط مباشر في الشاشات. كله من `MrasemType`.
- **B4.** ألوان مراسم Light/Dark **في الكود** (struct بقيمتين) مش Asset Catalog، عشان تتطابق مع Android وتتراجع من Windows.
- **B5.** Light و Dark مطلوبين من Phase 1، وكل مكوّن له `#Preview` للوضعين.
- **B6.** RTL أولاً: `leading/trailing` فقط، ممنوع `left/right`. القيم اللاتينية (هواتف، لوحات، أوقات) `.environment(\.layoutDirection, .leftToRight)` على العنصر نفسه.
- **B7.** أي عنصر متكرر في شاشتين يبقى مكوّن في `Mrasem/Components`.
- **B8.** الملف ≤ ~300 سطر.
- **B9.** الهيدر العنّابي بيمتد تحت الـ status bar (`ignoresSafeArea(edges: .top)`) والنص أبيض؛ صفحة الإعدادات فاتحة. الـ bottom bar فوق الـ home indicator.
- **B10.** الأيقونات من مسارات الـ SVG الأصلية (`Shape`)، مش SF Symbols.
- **B11.** مساحة اللمس ≥ 44pt. `accessibilityLabel` لكل عنصر تفاعلي من غير نص، و`.accessibilityAddTraits(.isHeader)` للعناوين، و`.isSelected` للتاب/الاختيار.
- **B12.** Dynamic Type: الخطوط بتكبر مع النظام. الاستثناء المسجّل: بنطبّق **مقياس موحّد** (`DynamicTypeSize.mrasemScale`) على كل خطوط مراسم بدل `relativeTo:` — لأن Reem Kufi خط متغيّر و SwiftUI مش بيقدر يجمع بين محور `wght` والـ Dynamic Type. ممنوع ارتفاعات ثابتة تقص النص.
- **B13.** الـ `Layout` المخصص (قائمة المفتاح/القيمة، الـ flow) لازم يقيس العناصر زي ما Compose بيعمل — مش تخمين بأرقام ثابتة.
- **B14.** نصوص الـ accessibility بتتبني من الـ catalog زي أي نص (قاعدة C1)؛ ممنوع عربي حرفي في الكود.
- **B15.** الأيقونات من `MrasemIcons` بس — ممنوع SF Symbols في كود مراسم.

## C. النصوص والبيانات

- **C1.** نصوص الواجهة في `Localizable.xcstrings` بمفاتيح `mrasem_*` (نفس مفاتيح Android بالحرف). ممنوع نص عربي حرفي في View أو ViewModel. الاستثناء: `#Preview`.
- **C2.** بيانات المهمة في `MrasemDemoData.swift` منقولة حرفياً من `04-DEMO-DATA.md` — مش في الـ strings.
- **C3.** النقل حرفي: نفس الكلمات والتشكيل والترقيم والأرقام.
- **C4.** الأرقام المحسوبة تتحول لعربية هندية بدالة واحدة: `toArabicDigits()`. ممنوع الاعتماد على `Locale` في تنسيق الأرقام أو الأوقات (الأوقات `HH:mm` لاتيني بـ padding يدوي).
- **C5.** الـ Models `struct` بـ `let`، والتعديل بنسخة جديدة جوّه الـ Repository فقط.
- **C6.** التواريخ: `DateComponents`/`Calendar(identifier: .gregorian)` صريح. «أيام على الوصول» من تاريخ الجهاز عبر `now` بيتحقن (للاختبار).
- **C7.** الحفظ الدائم (`UserDefaults` بمفاتيح `mrasem_*`): الدور والوضع، آخر تاب للضيف، مفاتيح الإشعارات، الثيم. باقي الحالة في الذاكرة.
- **C8.** النوتيسات وردود المساعد `enum` بـ associated values (مش نصوص)، والـ View يبني النص من الـ strings — زي `NoticeContent`/`AssistantReply` في Android.

## D. التنظيف والكود القديم

- **D1.** يتحذف في Phase 0 **الخاص بالتوثيق بس** (القائمة المبدئية في `03-PHASES.md`، وتتأكد بفحص الاعتماديات قبل الحذف).
- **D2.** يفضل ويتعاد استخدامه: `APIClient`، `Extensions/*`، مكوّنات الفورم والـ Alert، `DataModel/*`، `AppManager`، `LocationManager`، `Logger`، خطوط Cairo، المكتبات الثلاث.
- **D3.** الحذف من الفولدر محتاج إذن حذف على الجهاز؛ لو اترفض، الملفات تتنقل لـ `_to_delete/`.
- **D4.** ممنوع كود معلّق (commented-out) أو `print` في كود مراسم.
- **D5.** ممنوع أسرار في الريبو: `Config/Secrets.xcconfig` برّه git. مفاتيح الـ Gateway بتاعة التوثيق تتشال من `Info.plist` و`App.xcconfig`.

## E. الجودة ومعيار «خلص»

أي Phase يعتبر خلص لما:

- **E1.** الـ CI أخضر: `xcodebuild build` (و`test` من Phase 2). لحد ما الـ CI يشتغل، الـ Phase بيتسلّم «كود مكتمل — بانتظار build».
- **E2.** الشاشات مطابقة Light + Dark على iPhone صغير (375pt) وكبير (430pt).
- **E3.** كل تفاعل في الـ spec شغال بنفس النصوص.
- **E4.** كل Strategy عليها unit tests بنفس حالات اختبارات Kotlin.
- **E5.** مفيش مخالفة لـ B2 / B3 / C1 (تتراجع بـ grep).
- **E6.** ملخص بالملفات، وأي قرار جديد اتسجل هنا.

## F. ملاحظات على المشروع الحالي

> آخر تحديث: 2026-11-12 — بعد Phase 3 (مكتوب، بانتظار CI).

- **اتحل في Phase 0:** مفيش git → بقى repo على `joe772002/mrasem-ios`. الـ force-unwrap للخط → بقى `if let`. مفاتيح الـ AI Gateway واسم Siri البديل → اتشالت.
- `AppManager.isDarkMode` افتراضيه `true` وبيتقرا من `UserDefaults` — هيتوصّل بخيار الثيم (فاتح/داكن/النظام).
- `DEVELOPMENT_TEAM = 25N3SF9UHQ` ثابت في المشروع — للمراجعة لو الحساب هيتغير.
- رؤوس الملفات فيها أسماء مشاريع قديمة (MTCIT, mojEgypt) — تجميلي.
- **الـ Bundle ID** لسه `com.informatiqueComp.reserveProcuration2` (بتاع تطبيق التوكيل). لو اترفع بنفس الحساب، هيبقى **تحديث** للتطبيق القديم مش تطبيق جديد.

## سجل القرارات

| التاريخ | القرار | السبب |
|---|---|---|
| 2026-11-12 | إنشاء وثائق iOS واعتماد التقسيم إلى 10 Phases (0–9) | بداية المشروع |
| 2026-11-12 | الهدف هو التصميم المحسَّن مباشرة (مش الأصلي ثم التحسين) | Android وصل له بعد إعادة شغل؛ iOS يبنيه مرة واحدة |
| 2026-11-12 | ألوان مراسم في الكود مش في Asset Catalog (B4) | مطابقة Android، ومراجعة من غير Xcode |
| 2026-11-12 | مصدر الديزاين كود Android (`enhance`) مباشرة، مش الويب (B1) | طلب صاحب المشروع |
| 2026-11-12 | الريبو: `joe772002/mrasem-ios`؛ أول commit هو حالة مشروع التوثيق قبل أي حذف | نقطة رجوع |
| 2026-11-12 | **Bundle ID سيب زي ما هو**، واسم العرض «مراسم» بس | قرار صاحب المشروع. التحذير: نفس الـ ID على نفس حساب Apple = تحديث للتطبيق القديم |
| 2026-11-12 | `Views/Reservation/Model/` اتشال، وأنواع الـ pickers اتنقلت لـ `Components/FormComponents/ReservationPickerModels.swift` | `DynamicFormField` لسه بيحتاجها (D2: مكوّنات الفورم تفضل)، بس شاشات الحجز بتاعت التوثيق اتحذفت |
| 2026-11-12 | `DeviceIdentity` اتحذف مع `Features/Assistant/`، ومعاه `ReservationRequest` | `DeviceIdentity` كان مربوط بالـ Gateway secret اللي اتشال؛ `ReservationRequest` كان بيستخدمه ومكانش هيتحتاج |
| 2026-11-12 | `Localizable.xcstrings`: `sourceLanguage` = `ar` | Android-xml بيحط العربي في `values/` و`values-ar/` مع بعض، والتطبيق عربي بس (قرار #4) |
| 2026-11-12 | ** صيغ الـ format بتاعت Android اتحوّلت `%1$s` ← `%1$@`** | مُجمّع نصوص Swift ما بيقبلش `%s` — بيرمي error وقت البناء. `%@` للـ String، `%lld` للـ Int. مثال: `Text("mrasem_notice_dress_approved \(name)")` |
| 2026-11-12 | `NSCameraUsageDescription` · `NSMicrophoneUsageDescription` · `NSSpeechRecognitionUsageDescription` · `NSPhotoLibraryUsageDescription` اتشالت | ميزاتها (ID Scanner + Voice Input) اتحذفت مع كود التوثيق؛ مفاتيح الموقع اتفضلت لأن `LocationManager` محفوظ (D2) |
| 2026-11-12 | `Config/Secrets.example.xcconfig` اتحذف و`App.xcconfig` اتمسح منه الـ secret | مراسم مش بيبعت لـ Backend في أي phase؛ القاعدة D5 بتفضل: أي سر جاي يبقى في `Secrets.xcconfig` المتجاهَل |
| 2026-11-12 | الـ CI على runner `macos-26` | `IPHONEOS_DEPLOYMENT_TARGET = 26.0` محتاج Xcode 26 |
| 2026-11-12 | الـ splash جوه التطبيق (مش System Launch Screen) | نفس Android: splash عنّابي ١.٥ ثانية جوّه `MrasemRootView`. الـ launch screen بتاع النظام يفضل لحد Phase 9 |
| 2026-11-12 | **مصدر التصميم بقى فرع `main`** بدل `enhance` | قرار صاحب المشروع. معناه: مفيش شاشة إعداد ولا أدوار ولا screen «المزيد» ولا سائق ولا إعدادات — والـ header والـ bottom bar هما نسخة `main` (segmented، شريط ثابت) |
| 2026-11-12 | Phase 1: `MrasemRGB` بيحتفظ بـ RGB عشان نعمل `compositeOver` زي Compose | SwiftUI مالهاش `compositeOver`، والألوان محتاجين مزج (زي `noticeBg`) |
| 2026-11-12 | Phase 1: خط Reem Kufi المتغيّر بنستخدمه عن طريق CoreText (`kCTFontVariationAttribute`) | SwiftUI مالهاش API لمحاور الخطوط المتغيّرة. الـ PostScript name هو `ReemKufi` ومحور `wght` من 400 لـ 700 |
| 2026-11-12 | Phase 1: Dynamic Type بمقياس موحّد بدل `relativeTo:` | Reem Kufi خط متغيّر، و `Font.custom(..., relativeTo:)` مش بيقبل variation في نفس الوقت. مسجّل كاستثناء لقاعدة B12 |
| 2026-11-12 | Phase 1: أيقونة `protocol` باسم backticks (`` `protocol` ``) | `protocol` كلمة محجوزة في Swift |
| 2026-11-12 | Phase 2: تاب `GuestTab.protocol` كمان بـ backticks | نفس السبب — `protocol` محجوزة |
| 2026-11-12 | Phase 2: `ProgramItem.Official.where` اتسمّى `place` | `where` كلمة محجوزة في Swift |
| 2026-11-12 | Phase 2: `MrasemDate` بدل `LocalDate` | Swift مالهاش تاريخ بدون وقت. `MrasemDate` Foundation فقط، وبيدعم `days(since:)` والفرق بين يومين |
| 2026-11-12 | Phase 2: **الـ Domain والـ Data طبقة `nonisolated`** | التطبيق بيستخدم `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`، فأي class بيتبان main-actor-isolated. تفكيك class من غير الـ main thread بيعمل hop للـ main actor — والـ hop ده كان بيكرش الـ test host (`swift_task_deinitOnExecutorImpl` → `TaskLocal::StopLookupScope`). الـ domain منطق نقي، فمش المفروض يكون tied بـ actor |
| 2026-11-12 | Phase 2: الـ **test target** بـ Swift عادي (من غير default MainActor) | XCTest بينادي الـ test methods من غير الـ main thread. لو الـ target كان MainActor-isolated، كل deinit بيعمل hop. الـ app target فضل زي ما هو |
| 2026-11-12 | Phase 2: الـ **test target** اتضاف للـ `project.pbxproj` بإيد (استثناء لقاعدة A10) | محتاجين `xcodebuild test` على الـ CI. الـ تعديل اتعمل بسكربت وكل استبدال بفحص عدد تكرارات — لو مش مطابق بيكسر الملف. لو Xcode رفض المشروع: `git checkout WantProcuration.xcodeproj/project.pbxproj` |
| 2026-11-12 | Phase 2: `ContactLinks` + `ExternalLinks` اتنقلوا هنا | اختبارات Android (`UtilTest`) بتغطيهم، فنقلناهم مع الـ tests |
| 2026-11-12 | Phase 2: `MrasemFonts.display` بقت `Font.custom(...).weight(...)` بدل CoreText | بناء نسخة من الخط المتغيّر عبر `kCTFontVariationAttribute` كان بيفضّل الذاكرة. `Font.weight` بتاخد محور `wght` على iOS 16+ |
| 2026-11-12 | Phase 3: **A3 اتعدّلت — Combine مسموح في Domain/Data** | `statePublisher` هو مقابل `StateFlow` في Android، ومن غير Combine مفيش طريقة نعرض الحالة. الممنوع فعلاً هو SwiftUI/UIKit |
| 2026-11-12 | Phase 3: **`MrasemAppContext`** بيمرّر الـ container والـ toast bus للشاشات | بديل `hiltViewModel()`. الـ container بيتبني في `@StateObject` جوه الـ root فمش بيتبني في الـ unit-test host |
| 2026-11-12 | Phase 3: مفاتيح `mrasem_*` اللي مش في Android `main` اتشالت من الـ catalog (٧٣ مفتاح) | كانت جاية من فرع `enhance`؛ مصدر التصميم بقى `main` |
| 2026-11-12 | Phase 3: **الاختبارات تغطي الأجزاء الصافية للـ Shell بس** (وجهات، `ShellUiState`، `UiText`، نصوص التنبيهات، toast bus) | الـ ViewModel نفسه `MainActor` — تفكيكه من الـ test thread هو نفس سبب كراش الـ test host. المنطق اللي جواه رفيع (ربط بين `statePublisher` والـ strategy) |
