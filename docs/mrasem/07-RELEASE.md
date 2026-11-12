# 07 — الإصدار (TestFlight) و checklist المراجعة

> Phase 9. كل اللي هنا محتاج **حساب Apple Developer** أو **Mac/Simulator** — الكود نفسه جاهز.

## الـ Bundle ID

✅ **`com.informatiqueComp.mrasem`** — تطبيق مستقل (القرار اتاخد في Phase 9). قبل أول رفع:

1. developer.apple.com → Identifiers → **+** → App IDs → Bundle ID صريح `com.informatiqueComp.mrasem` (نفس الـ Team `25N3SF9UHQ`).
2. Profiles → **+** → App Store Connect → اختار الـ ID ده وشهادة الـ Distribution.
3. App Store Connect → Apps → **+** → New App: الاسم «مراسم»، اللغة الأساسية العربية، نفس الـ Bundle ID.

الـ workflow بيقارن Bundle ID الـ profile بالـ project وبيوقف لو مختلفين.

## الـ Secrets المطلوبة (GitHub → Settings → Secrets and variables → Actions)

| Secret | منين |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | شهادة **Apple Distribution** كـ `.p12` (Keychain على أي Mac، أو تتعمل من developer.apple.com بـ CSR) ← `base64 -i dist.p12` |
| `P12_PASSWORD` | باسورد الـ `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | Profile نوع **App Store Connect** للـ Bundle ID ← `base64 -i Mrasem.mobileprovision` |
| `KEYCHAIN_PASSWORD` | أي نص عشوائي |
| `APPSTORE_API_KEY_ID` / `APPSTORE_ISSUER_ID` | App Store Connect → Users and Access → Integrations → Keys (صلاحية App Manager) |
| `APPSTORE_API_PRIVATE_KEY` | محتوى ملف `AuthKey_<id>.p8` كامل |

على Windows: `certutil -encode file.p12 out.txt` وبعدين امسح سطري BEGIN/END من الناتج.

## التشغيل

GitHub → Actions → **Release (TestFlight)** → Run workflow:
- `upload = false`: يعمل archive موقّع ويحفظ الـ `.ipa` كـ artifact (اختبار التوقيع).
- `upload = true`: يرفع على TestFlight. رقم الـ build = رقم الـ run؛ الإصدار من `MARKETING_VERSION`.


## Checklist المراجعة اليدوية (على Simulator أو جهاز)

لكل شاشة من الـ 10 (٦ ضيف + ٤ فريق) وفي الوضعين (الدوحة / لندن):

- [ ] Light و Dark مطابقين لـ Android `main`.
- [ ] iPhone SE (375pt) و Pro Max (430pt): مفيش نص مقطوع أو متداخل.
- [ ] Dynamic Type على أكبر مقاس (Accessibility 5): الشاشة بتسكرول ومفيش حاجة بتختفي.
- [ ] الخطوط فعلاً Reem Kufi / IBM Plex (مش San Francisco).
- [ ] **VoiceOver:**
  - [ ] الهيدر بيتقرأ عنوان (Header)، وأزرار الدور والوضع بتقول المختار.
  - [ ] الـ bottom bar: اسم التاب + «محدد».
  - [ ] التوست بيتقال لوحده (Announcement) بعد أي فعل (طلب، تأجيل، حفظ…).
  - [ ] بطاقات الـ KPI بتتقرأ رقم + وصف مع بعض.
  - [ ] صفوف الخدمات: الاسم والوصف مرة واحدة، من غير حروف اللوجو.
  - [ ] قائمة الفحص: البند + «محدد» لما يتعلّم.
  - [ ] الأيقونات مش بتتقرأ (مخفية).
- [ ] مساحة اللمس ≥ 44pt لكل زر/chip.
- [ ] سيناريوهات الربط الخمسة يدوياً: فريق ← ضيف (محدَّث، تأجيل، طلب، زي، تنبيه).
- [ ] الأيقونة على الـ Home Screen، والـ Launch عنّابي ثم الـ splash.
