# iOS Setup Guide - دليل إعداد iOS (Appwrite)

## ✅ الموجود والجاهز:
1. ✅ Info.plist محدث بجميع الأذونات
2. ✅ Podfile تم إنشاؤه (بدون Firebase)
3. ✅ هيكل المشروع صحيح
4. ✅ إعدادات الأمان والشبكة
5. ✅ التطبيق يستخدم Appwrite (لا يحتاج Firebase)

## 📱 المطلوب للبناء على iOS:

### 1. تثبيت Pods (على Mac فقط)
```bash
cd ios
pod install
cd ..
```

**ملاحظة:** إذا كنت على Windows، ستحتاج Mac أو CI/CD لبناء iOS.

---

### 3. إعدادات Xcode (على Mac)

1. افتح `ios/Runner.xcworkspace` (ليس .xcodeproj)
2. اختر Runner من القائمة اليسرى
3. في تبويب "Signing & Capabilities":
   - اختر Team
   - تأكد من Bundle Identifier: `com.mored.attendanceApp`
   - تفعيل Automatically manage signing

---

### 4. Capabilities المطلوبة في Xcode

أضف الـ Capabilities التالية:
- ✅ Push Notifications (للإشعارات)
- ✅ Background Modes:
  - Background fetch
  - Remote notifications
- ✅ Associated Domains (إذا كنت تستخدم deep links)

---

### 5. Privacy Permissions (موجودة بالفعل في Info.plist)

✅ Camera - للـ QR scanning
✅ Microphone - لتسجيل الصوت
✅ Photo Library - للصور
✅ Contacts - لبيانات الطلاب
✅ Calendar - للأحداث
✅ Location - للحضور المعتمد على الموقع

---

## 🏗️ بناء التطبيق للـ iOS

### البناء للتجربة:
```bash
flutter build ios --debug
```

### البناء للنشر:
```bash
flutter build ios --release
```

### البناء كـ IPA:
```bash
flutter build ipa --release
```

---

## 📱 متطلبات النشر على App Store

### 1. Apple Developer Account
- اشترك في: https://developer.apple.com
- التكلفة: $99/سنة

### 2. App Store Connect
1. أنشئ تطبيق جديد
2. املأ معلومات التطبيق:
   - الاسم
   - الوصف (عربي وإنجليزي)
   - Screenshots (مطلوب)
   - Privacy Policy URL
   - Support URL

### 3. Certificates & Provisioning Profiles
- يتم إنشاؤها تلقائياً إذا فعلت "Automatically manage signing"
- أو أنشئها يدوياً من developer.apple.com

---

## ⚠️ مشاكل شائعة وحلولها

### مشكلة: Pod install يفشل
**الحل:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
```

### مشكلة: Build يفشل بسبب Firebase
**الحل:** تأكد من وجود GoogleService-Info.plist

### مشكلة: Code signing error
**الحل:** تأكد من اختيار Team صحيح في Xcode

---

## 📋 Checklist قبل النشر

- [ ] GoogleService-Info.plist موجود
- [ ] Pod install نجح
- [ ] Bundle ID صحيح
- [ ] Code signing معد
- [ ] التطبيق يعمل على جهاز فعلي
- [ ] جميع الميزات تعمل
- [ ] Screenshots جاهزة
- [ ] App Store Connect معد
- [ ] Privacy Policy جاهزة
- [ ] وصف التطبيق مكتوب

---

## 🚀 أمر سريع للبناء (على Mac):

```bash
# 1. تثبيت dependencies
flutter pub get
cd ios && pod install && cd ..

# 2. بناء التطبيق
flutter build ios --release

# 3. فتح في Xcode لرفعه للـ App Store
open ios/Runner.xcworkspace
```

---

## 📞 للمساعدة:
- Flutter iOS docs: https://docs.flutter.dev/deployment/ios
- Firebase iOS setup: https://firebase.google.com/docs/ios/setup
- App Store Guidelines: https://developer.apple.com/app-store/review/guidelines/

---

**ملاحظة مهمة:** iOS build يتطلب macOS. إذا كنت على Windows، ستحتاج:
- Mac للبناء والنشر
- أو استخدام CI/CD مثل Codemagic أو GitHub Actions
