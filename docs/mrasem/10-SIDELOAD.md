# 10 — تثبيت مراسم على iPhone من غير Mac (GitHub Actions + Sideloadly)

## الفكرة
الـ CI بيبني `.ipa` **غير موقّع** على runner بتاع macOS. Sideloadly على Windows بيوقّعه بحساب Apple ID المجاني بتاعك وبيثبّته على الموبايل بالكابل.

## الخطوات
1. على GitHub: **Actions → Sideload IPA → Run workflow** (على `main`).
2. لما يخلص، نزّل الـ artifact `Mrasem-unsigned-<رقم>` وفك الـ zip → `Mrasem-unsigned.ipa`.
3. على الويندوز: ثبّت **iTunes و iCloud من موقع Apple** (مش نسخة Microsoft Store) + Sideloadly.
4. وصّل الـ iPhone بالكابل، وافتح Sideloadly، اسحب الـ `.ipa`، اكتب Apple ID، اضغط Start.
5. على الموبايل: **الإعدادات ← عام ← VPN وإدارة الجهاز** ← ثق في حسابك. وفعّل **وضع المطوّر** (الإعدادات ← الخصوصية والأمان) لو طلب.

## حدود لازم تعرفها
- الحساب المجاني: التطبيق **بيقفل بعد ٧ أيام** ولازم تعيد التثبيت (بيحتفظ ببيانات UserDefaults لو ثبّتّه فوقه بنفس الـ Bundle ID). حد أقصى ٣ تطبيقات وعشرة App IDs كل أسبوع.
- المشروع `IPHONEOS_DEPLOYMENT_TARGET = 26.0` → الموبايل لازم يكون **iOS 26 أو أحدث**.
- مفيش entitlements في المشروع، فالحساب المجاني يكفي.
- Sideloadly ممكن يغيّر الـ Bundle ID لو `com.informatiqueComp.mrasem` محجوز على حساب تاني — عادي.
- للتثبيت اللاسلكي والتجديد التلقائي: Sideloadly بيدعم Auto-refresh بس بيحتاج الـ PC شغّال وعلى نفس الشبكة.
- لو الـ iPhone فيه TestFlight/حساب مطوّر مدفوع، `07-RELEASE.md` أفضل (٩٠ يوم، من غير كابل).
