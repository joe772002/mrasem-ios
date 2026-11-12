# 06 — خريطة Android ← iOS

كود Android (`D:\private\new project\mrasem`، **branch `main`**) هو المرجع السلوكي: كل ملف Swift بيتكتب قدّام مقابله في Kotlin، بنفس الأسماء والحالات. المسارات تحت `app/src/main/java/com/informatique/tawsekmisr/`.

> فرع `enhance` فيه تصميم تاني (شاشة إعداد، سائق، إعدادات، «المزيد») — **مش** المرجع. شوف `05-ENHANCED-DESIGN.md`.

## البيانات والمنطق

| Android | iOS (`WantProcuration/Mrasem/`) |
|---|---|
| `data/model/mrasem/MissionModels.kt` | `Data/MissionModels.swift` |
| `data/model/mrasem/MrasemState.kt` | `Data/MrasemState.swift` |
| `data/local/MrasemDemoData.kt` | `Data/MrasemDemoData.swift` |
| `data/local/MrasemPreferences(+Impl).kt` (DataStore) | `Data/MrasemPreferences.swift` (UserDefaults) |
| `data/repository/MissionRepository(+Impl).kt` (StateFlow) | `Data/MissionRepository.swift` (CurrentValueSubject) |
| `domain/strategy/mrasem/MrasemSessionStrategy.kt` | `Domain/MrasemSessionStrategy.swift` |
| `…/MissionSummaryStrategy.kt` | `Domain/MissionSummaryStrategy.swift` |
| `…/ProgramStrategy.kt` | `Domain/ProgramStrategy.swift` |
| `…/ExploreStrategy.kt` | `Domain/ExploreStrategy.swift` |
| `…/AssistantStrategy.kt` | `Domain/AssistantStrategy.swift` |
| `…/VisitUpdateStrategy.kt` | `Domain/VisitUpdateStrategy.swift` |
| `…/TeamStrategy.kt` | `Domain/TeamStrategy.swift` |
| `…/ProtocolStrategy.kt` | `Domain/ProtocolStrategy.swift` |
| `…/MrasemSelectors.kt` | `Domain/MrasemSelectors.swift` |
| `util/ArabicDigits.kt` | `Util/ArabicDigits.swift` ✅ |
| `util/ContactLinks.kt` · `util/ExternalIntents.kt` | `Util/ContactLinks.swift` · `Util/ExternalLinks.swift` (Phase 4) |
| `di/module/MrasemModule.kt` + `RepositoryModule.kt` (Hilt) | `MrasemContainer.swift` (Phase 2) |

## الثيم والمكوّنات

| Android | iOS |
|---|---|
| `ui/theme/MrasemColors.kt` | `Theme/MrasemColors.swift` ✅ |
| `ui/theme/MrasemType.kt` | `Theme/MrasemType.swift` ✅ |
| `ui/theme/MrasemShapes.kt` | `Theme/MrasemShapes.swift` ✅ |
| `ui/theme/MrasemTheme.kt` | `Theme/MrasemTheme.swift` ✅ |
| `ui/icons/MrasemIcons.kt` | `Icons/MrasemIcons.swift` ✅ + `Icons/SVGPath.swift` ✅ |
| `ui/components/mrasem/MrasemCards.kt` | `Components/MrasemCards.swift` ✅ |
| `…/MrasemControls.kt` | `Components/MrasemControls.swift` ✅ |
| `…/MrasemInputs.kt` | `Components/MrasemInputs.swift` ✅ |
| `…/MrasemListItems.kt` | `Components/MrasemListItems.swift` ✅ |
| `…/MrasemActionRow.kt` | `Components/MrasemActionRow.swift` ✅ |
| `…/MrasemDrawings.kt` | `Components/MrasemDrawings.swift` ✅ |
| `…/MrasemChrome.kt` | `Components/MrasemChrome.swift` ✅ |
| `…/MrasemToast.kt` | `Components/MrasemToast.swift` ✅ |
| `…/MrasemScreenContent.kt` | `Components/MrasemScreenContent.swift` ✅ |
| `…/MrasemPreview.kt` | `Components/MrasemPreview.swift` ✅ |
| `…/MrasemNotices.kt` | `Components/MrasemNotices.swift` (Phase 2 — محتاج الموديلات) |
| — (مش موجود في `main`) | `Components/MrasemPreviews.swift` ✅ (previews Light/Dark) |
| — (مش موجود في `main`) | `Components/MrasemFlowLayout` + `MrasemKeyValueLayout` (في `MrasemListItems`/`MrasemCards`) ✅ |

## الشاشات

| Android (`ui/screens/`) | iOS (`Screens/`) |
|---|---|
| `shell/MrasemShell.kt` · `MrasemDestination.kt` · `MrasemSessionViewModel.kt` · `MrasemToastBus.kt` · `MrasemSplash.kt` | `Shell/` بنفس الأسماء |
| `ui/activities/LandingActivity.kt` | `WantProcurationApp.swift` ✅ |
| `mission/` · `plan/` · `services/` · `explore/` · `protocol/` · `assistant/` | `Screens/` بنفس الأسماء (Phases 4–6) |
| `team/TeamHeader.kt` + 4 شاشات و ViewModels | `Screens/Team/` (Phase 7) |
| — (مش موجود في `main`) | `Screens/Gallery/MrasemGalleryScreen.swift` ✅ (معرض المكوّنات) |

**الوجهات العشرة (6 ضيف + 4 فريق)** — نفس `MrasemDestination` على `main`:

| الضيف | الفريق |
|---|---|
| Mission · Plan · Services · Explore · Protocol · Assistant | Visit · Changes · Requests · Archive |

## النصوص والاختبارات

| Android | iOS |
|---|---|
| `res/values-ar/strings.xml` (مفاتيح `mrasem_*`) | `Localizable.xcstrings` بنفس المفاتيح. `%1$s` ← `%1$@` |
| `src/test/…/domain/strategy/mrasem/*Test.kt` (57 اختبار) | `WantProcurationTests/*Tests.swift` بنفس الأسماء |
| `res/font/reem_kufi.ttf` · `ibm_plex_sans_arabic_*.ttf` | `Fonts/` نفس الملفات ✅ |

## فروق منصّة لازم تتراعى

| الموضوع | Android | iOS |
|---|---|---|
| الحالة المشتركة | `StateFlow` + `stateIn` | `CurrentValueSubject` + `sink` في الـ ViewModel |
| الحقن | Hilt | initializer + `MrasemContainer` |
| الحفظ | DataStore (suspend) | `UserDefaults` (متزامن) |
| الاتصال | `ACTION_DIAL` | `tel:` عبر `UIApplication.open` |
| الثيم | `ThemePreferences` | `MrasemThemeOption` + `\.mrasem` في الـ environment |
| الخط المتغيّر | `FontVariation.Settings` | `CTFontDescriptor` + `kCTFontVariationAttribute` |
| الرجوع | `BackHandler` | مفيش زر نظام: التنقل بين التابات بالحالة، وزر رجوع صريح في الشاشات اللي محتاجاه |
| scroll داخل scroll | ممنوع `LazyColumn` جوّه `verticalScroll` (كراش) | نفس الفكرة: `VStack` جوّه `ScrollView` واحد للشاشة |
| الأوقات | `padStart` يدوي | `String(format:)` ممنوع مع locale عربي — padding يدوي برضه |
| التخطيط المخصص | `Layout` + `FlowRow` | `Layout` مخصص (`MrasemKeyValueLayout` · `MrasemFlowLayout`) |
| الرسومات | `Canvas` | `Canvas` (SwiftUI) — نفس الإحداثيات |
| القوائم المرنة | `FlowRow` | `MrasemFlowLayout` (قياس حقيقي) |
| Arc في الأيقونات | `PathParser` | `SVGPath.parse` مع تحويل arc → bezier |

