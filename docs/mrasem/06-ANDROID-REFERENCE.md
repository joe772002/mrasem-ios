# 06 — خريطة Android ← iOS

كود Android (`D:\private\new project\mrasem`، branch `enhance`) هو المرجع السلوكي: كل ملف Swift بيتكتب قدّام مقابله في Kotlin، بنفس الأسماء والحالات. المسارات تحت `app/src/main/java/com/informatique/tawsekmisr/`.

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
| `…/DriverStrategy.kt` | `Domain/DriverStrategy.swift` |
| `…/MrasemSelectors.kt` | `Domain/MrasemSelectors.swift` |
| `util/ArabicDigits.kt` · `ContactLinks.kt` · `ExternalIntents.kt` | `Util/ArabicDigits.swift` · `ContactLinks.swift` · `ExternalLinks.swift` |
| `di/module/MrasemModule.kt` + `RepositoryModule.kt` (Hilt) | `MrasemContainer.swift` |

## الثيم والمكوّنات

| Android | iOS |
|---|---|
| `ui/theme/MrasemColors.kt` · `MrasemType.kt` · `MrasemShapes.kt` · `MrasemTheme.kt` | `Theme/` بنفس الأسماء |
| `ui/icons/MrasemIcons.kt` | `Icons/MrasemIcons.swift` (+ `SVGPath.swift`) |
| `ui/components/mrasem/MrasemCards.kt` | `Components/MrasemCards.swift` |
| `…/MrasemControls.kt` · `MrasemInputs.kt` · `MrasemListItems.kt` | بنفس الأسماء |
| `…/MrasemActionRow.kt` · `MrasemSettingsItems.kt` · `MrasemNotices.kt` | بنفس الأسماء |
| `…/MrasemDrawings.kt` | `Components/MrasemDrawings.swift` |
| `…/MrasemChrome.kt` (الهيدر + الـ bar + النقشة) | `Components/MrasemChrome.swift` |
| `…/MrasemToast.kt` · `MrasemScreenContent.kt` | بنفس الأسماء |
| `…/MrasemPreview.kt` | `Components/MrasemPreview.swift` |

## الشاشات

| Android (`ui/screens/`) | iOS (`Screens/`) |
|---|---|
| `shell/MrasemShell.kt` · `MrasemDestination.kt` · `MrasemSessionViewModel.kt` · `MrasemStartViewModel.kt` · `MrasemToastBus.kt` · `MrasemSplash.kt` | `Shell/` بنفس الأسماء |
| `ui/activities/LandingActivity.kt` | `WantProcurationApp.swift` |
| `setup/SetupScreen.kt` + ViewModel | `Screens/Setup/` |
| `mission/` · `plan/` · `services/` · `explore/` · `protocol/` · `assistant/` | بنفس الأسماء |
| `more/MoreScreen.kt` | `Screens/More/` |
| `settings/SettingsScreen.kt` + ViewModel | `Screens/Settings/` |
| `driver/DriverScreen.kt` + ViewModel | `Screens/Driver/` |
| `team/TeamHeader.kt` + 4 شاشات و ViewModels | `Screens/Team/` |

## النصوص والاختبارات

| Android | iOS |
|---|---|
| `res/values-ar/strings.xml` (مفاتيح `mrasem_*`) | `Localizable.xcstrings` بنفس المفاتيح. `%1$s` ← `%1$@` |
| `src/test/…/domain/strategy/mrasem/*Test.kt` (57 اختبار) | `WantProcurationTests/*Tests.swift` بنفس الأسماء |
| `res/font/reem_kufi.ttf` · `ibm_plex_sans_arabic_*.ttf` | `Fonts/` نفس الملفات |

## فروق منصّة لازم تتراعى

| الموضوع | Android | iOS |
|---|---|---|
| الحالة المشتركة | `StateFlow` + `stateIn` | `CurrentValueSubject` + `sink` في الـ ViewModel |
| الحقن | Hilt | initializer + `MrasemContainer` |
| الحفظ | DataStore (suspend) | `UserDefaults` (متزامن) |
| الاتصال | `ACTION_DIAL` | `tel:` عبر `UIApplication.open` |
| الثيم | `ThemePreferences` | `AppManager` (يتوسّع لخيار «النظام») |
| الرجوع | `BackHandler` | مفيش زر نظام: زر رجوع ظاهر في الإعدادات، وسحب للرجوع غير مطلوب |
| scroll داخل scroll | ممنوع `LazyColumn` جوّه `verticalScroll` (كراش) | نفس الفكرة: `VStack` جوّه `ScrollView` واحد للشاشة |
| الأوقات | `padStart` يدوي | `String(format:)` ممنوع مع locale عربي — padding يدوي برضه |
