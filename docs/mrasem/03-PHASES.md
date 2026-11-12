# 03 — خطة التنفيذ iOS (Phases)

كل Phase يتسلّم لوحده ويتراجع قبل اللي بعده. معيار القبول العام في `02-RULES.md` قسم E. الترتيب بيبني **التصميم المحسَّن** مباشرة.

| Phase | العنوان | الناتج |
|---|---|---|
| 0 | التنظيف والتجهيز | مشروع نظيف بيبني على CI وبيفتح على شاشة فاضية بهوية مراسم |
| 1 | Design System | الثيم + الخطوط + الأيقونات + كل المكوّنات بـ previews |
| 2 | البيانات والمنطق | Models + بيانات الوضعين + Repository + Strategies + tests |
| 3 | الهيكل والتنقل | Splash ← الإعداد ← Shell (الهيدر، الـ bottom bar العائم، Toast، Notices) |
| 4 | المهمة + البرنامج | شاشتين |
| 5 | استكشف + الخدمات + المزيد | 3 شاشات |
| 6 | البروتوكول + المساعد | شاشتين |
| 7 | فريق المراسم | 4 تابات + الربط مع عرض الضيف |
| 8 | السائق + المرافق + الإعدادات | الأدوار الجديدة وصفحة الإعدادات |
| 9 | المراجعة والإصدار | مطابقة، Accessibility، الأيقونة، TestFlight |

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

---

## Phase 1 — Design System

- **الخطوط:** نسخ `reem_kufi.ttf` و IBM Plex Sans Arabic (4 أوزان) من مشروع Android لـ `Fonts/`، وتسجيلها في `UIAppFonts`. التحقق من أسماء الـ PostScript الفعلية.
- **الثيم:** `MrasemColors` (Light/Dark بكل الـ tokens + tokens التحسين: `headerAccent`, `headerSoft`, `headerGlass`, `headerPattern`, `navBg`, `navActive`, `navInactive`, `danger`)، `MrasemType` (نفس أسماء Android)، `MrasemShapes`/`MrasemDimens`، و`EnvironmentKey` واحد `\.mrasem`.
- **الأيقونات:** `MrasemIcons` — محوّل صغير لمسارات SVG (M/L/H/V/A/Z وصغيرها) لـ `Path`، والأيقونات الـ 20 بنفس المسارات.
- **المكوّنات:** Card, HeroCard, Pill, StatTile, KpiTile, KeyValueList, Button (Primary/Secondary/Ghost/Outline + block), Chip, Segmented (هيدر) و SegmentedLight, AvatarInitial, PlateBadge, StatusSteps, DayTabs, TimelineItem (عادي/changed/وقت حر), ServiceRow, ActionRow, PlaceCard, NoticeBanner, Toast, ChecklistRow, ChatBubble, AskBar, TextField (+LTR), Select, SettingsGroup/Row/SwitchRow, Switch.
- **الرسومات:** MapPreview, QrPlaceholder (نفس خوارزمية المصدر), DressIllustration, و`QatariPattern` (نجمة ثمانية).
- **الـ Chrome:** `MrasemHeader` (كامل/مضغوط) و`MrasemBottomBar` العائم.
- `toArabicDigits()` و`toArabicNumber()`.

**القبول:** كل مكوّن له Preview Light/Dark؛ CI أخضر؛ مفيش لون أو خط خارج الثيم.

---

## Phase 2 — البيانات والمنطق

- **Models:** نفس `MissionModels.kt` و`MrasemState.kt` (structs/enums)، بما فيها `UserRole` بـ 4 قيم، `GuestTab.more`, `DriverTab`, `settingsOpen`, `guestShort`.
- **البيانات:** `MrasemDemoData.swift` — الوضعين حرفياً + الثوابت (الزي، قائمة الفحص، الدليل، أسئلة المساعد).
- **Repository:** `MissionRepository` protocol + `InMemoryMissionRepository`.
- **Preferences:** `MrasemPreferences` protocol + تنفيذ `UserDefaults` (setup, lastGuestTab, notifications).
- **Strategies:** Session, MissionSummary, Program, Explore, Assistant, VisitUpdate, Team, Protocol, Driver + Selectors (`recentNotices`, `displayName`, `officialCount`).
- **Tests:** test target `WantProcurationTests` (**خطوة عليك في Xcode، أو على الـ cloud Mac**: File › New › Target › Unit Testing Bundle) + نقل الـ 57 اختبار من Kotlin بنفس الأسماء والحالات. الـ CI يشغّل `xcodebuild test`.

**القبول:** كل الاختبارات ناجحة على CI؛ مطابقة البيانات بند بند مع `04-DEMO-DATA.md`.

---

## Phase 3 — الهيكل والتنقل

- `MrasemContainer` (تجميع الاعتماديات) + ربطه في `WantProcurationApp`.
- **البداية:** Splash ← لو مفيش اختيار محفوظ `SetupScreen`، غير كده الـ Shell.
- `SetupScreen`: هيدر عنّابي بالزخرفة، 4 كروت أدوار (2×2)، كارتين لنوع المهمة، «متابعة» بتحفظ.
- `MrasemShell`: الهيدر (كامل في تاب البداية، مضغوط في الباقي) + محتوى الوجهة + الـ bottom bar العائم + Toast host.
- `MrasemDestination` + `MrasemNav` (تابات كل دور) + `MrasemSessionViewModel` (التحية، الاسم، نطاق التاريخ، الطقس، الرجوع).
- `ToastBus` (PassthroughSubject) + `UiText`. Toast: 3.8 ثانية، الجديد يلغي القديم.
- `NoticesSection` (آخر تنبيهين). سطر «بيانات توضيحية لنموذج أولي.» آخر كل شاشة.
- الوجهات placeholders لحد Phases 4–8.

**القبول:** الإعداد بيتحفظ وما بيظهرش تاني؛ التنقل بين تابات كل دور شغال؛ الهيدر والـ bar مطابقين Light/Dark.

---

## Phase 4 — المهمة + البرنامج

- `MissionScreen`: Notices، Hero، حالة الوصول (4 خطوات و4 toasts)، المستقبِل (اتصال/واتساب)، السيارة (لوحة)، الموقع (خريطة + فتح في الخرائط)، الإقامة، بطاقة المرور (QR)، الطوارئ. pill «محدَّث».
- `PlanScreen`: DayTabs، الـ timeline بأنواعه الثلاثة، chip البروتوكول، chips الوقت الحر ← استكشف.
- `ContactLinks` + `ExternalLinks` (`tel:`, `wa.me`, خرائط Google؛ `UIApplication.open` مع تجاهل الفشل).

**القبول:** مطابقة الوضعين؛ دورة الوصول كاملة؛ الروابط بتفتح.

---

## Phase 5 — استكشف + الخدمات + المزيد

- `ExploreScreen`: كارت «حول {الفندق}» + الفلاتر الخمسة، كروت الأماكن، دورة الطلب + toast.
- `ServicesScreen`: الفئات، صف الخدمة بزر «فتح»، «معلومات سريعة»، سطر الغرفة.
- `MoreScreen`: الخدمات والبروتوكول + اختصار الإعدادات. الرجوع منهم يرجّع لـ «المزيد».

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

## Phase 8 — السائق + المرافق + الإعدادات

- `DriverScreen`: الرحلة التالية (استلام ← توصيل)، الركاب، اتصال بالمرافق، «ابدأ الملاحة»، «وصلت»، بقية اليوم. تابات السائق: رحلاتي / الجدول / حسابي.
- المرافق: نفس عرض الوفد باسم المستقبِل.
- `SettingsScreen`: الحساب، المهمة (الدور ← الإعداد، نوع المهمة)، الإشعارات (3 مفاتيح محفوظة)، المظهر (فاتح/داكن/النظام — مربوط بـ `AppManager`)، المساعدة، تسجيل الخروج، الإصدار.

**القبول:** تغيير الدور والوضع والثيم بيتحفظ ويتطبق فوراً؛ رحلات السائق مطابقة لاختبارات `DriverStrategy`.

---

## Phase 9 — المراجعة والإصدار

- مراجعة شاشة بشاشة مع Android والكانفس (Light/Dark، 375 و 430pt، Dynamic Type كبير).
- Accessibility: VoiceOver، مساحات اللمس، التباين.
- **الأيقونة:** نفس أيقونة Android (1024px في `AppIcon.appiconset`) + Launch Screen نهائي.
- تنظيف: `Localizable.xcstrings`، ألوان Asset القديمة الغير مستخدمة، رؤوس الملفات.
- الإصدار: signing (حساب Apple Developer)، Archive، TestFlight — عبر Codemagic أو Mac في السحابة.
- تحديث الوثائق وسجل القرارات.

**القبول:** build على TestFlight شغال على iPhone فعلي؛ صفر references للتوثيق؛ checklist المطابقة كاملة.

---

## الاعتماديات

```
ريبو + CI → 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
               (1 و 2 ممكن يتبدلوا؛ 4–8 ترتيبهم مرن بعد 3؛ 7 قبل اختبار الربط)
```
