# iOS Setup Guide - دليل إعداد iOS (Appwrite Only)

## ✅ الموجود والجاهز (100%):
1. ✅ Info.plist محدث بجميع الأذونات المطلوبة
2. ✅ Podfile معد بدون Firebase
3. ✅ هيكل المشروع صحيح وكامل
4. ✅ إعدادات الأمان والشبكة (HTTPS)
5. ✅ التطبيق يستخدم **Appwrite فقط** (لا يحتاج Firebase!)
6. ✅ Bundle ID: `com.mored.attendanceApp`

---

## 🎉 **لا تحتاج GoogleService-Info.plist!**

التطبيق يستخدم **Appwrite** فقط، لذلك:
- ❌ لا تحتاج Firebase
- ❌ لا تحتاج GoogleService-Info.plist  
- ❌ لا تحتاج google-services.json
- ✅ Appwrite يعمل مباشرة عبر HTTPS APIs

---

## 📱 خطوات البناء على iOS

### المتطلبات:
- ✅ macOS (Catalina أو أحدث)
- ✅ Xcode 14+ مثبت من App Store
- ✅ CocoaPods مثبت
- ✅ Apple Developer Account ($99/سنة للنشر)

---

### 1. تثبيت CocoaPods (إذا لم يكن مثبتاً):

```bash
sudo gem install cocoapods
```

---

### 2. تثبيت Dependencies:

```bash
# في مجلد المشروع
flutter pub get

# الذهاب لمجلد iOS
cd ios

# تثبيت Pods
pod install --repo-update

# العودة للمجلد الرئيسي
cd ..
```

---

### 3. فتح المشروع في Xcode:

```bash
open ios/Runner.xcworkspace
```

⚠️ **مهم:** افتح `.xcworkspace` وليس `.xcodeproj`

---

### 4. إعداد Code Signing في Xcode:

1. في Xcode، اختر **Runner** من القائمة اليسرى
2. اذهب لتبويب **Signing & Capabilities**
3. **Automatically manage signing** ✅
4. اختر **Team** (حساب Apple Developer)
5. تأكد من **Bundle Identifier**: `com.mored.attendanceApp`

---

### 5. إضافة Capabilities (إذا لزم):

في **Signing & Capabilities**، أضف:
- ✅ **Push Notifications** (للإشعارات)
- ✅ **Background Modes**:
  - Background fetch
  - Remote notifications

---

## 🏗️ البناء والاختبار

### اختبار على Simulator:

```bash
flutter run -d "iPhone 15 Pro"
```

### اختبار على جهاز حقيقي:

1. وصل iPhone بالكمبيوتر
2. في Xcode: اختر الجهاز من القائمة العلوية
3. اضغط ▶️ Run

أو:
```bash
flutter run -d [device-id]
```

---

### بناء للنشر (Release):

```bash
# بناء iOS app
flutter build ios --release

# أو بناء IPA مباشرة
flutter build ipa --release
```

الملف سيكون في: `build/ios/ipa/attendance.ipa`

---

## 📦 النشر على App Store

### 1. إعداد App Store Connect:

1. اذهب إلى: https://appstoreconnect.apple.com
2. أنشئ تطبيق جديد:
   - **Name**: Attendance App
   - **Primary Language**: Arabic
   - **Bundle ID**: `com.mored.attendanceApp`
   - **SKU**: يمكنك استخدام `attendanceapp001`

### 2. املأ معلومات التطبيق:

#### **App Information:**
- **Name**: اسم التطبيق
- **Subtitle**: وصف قصير (30 حرف)
- **Category**: Education أو Productivity

#### **Pricing:**
- Free أو Paid

#### **App Privacy:**
- أضف Privacy Policy URL
- حدد البيانات المجمعة:
  - Camera (QR scanning)
  - Photos (Student images)
  - Location (Attendance verification)
  - Contacts (Student data)

### 3. رفع Screenshots:

**مطلوب للأجهزة التالية:**
- iPhone 6.7" (iPhone 15 Pro Max)
- iPhone 6.5" (iPhone 11 Pro Max)
- iPad Pro 12.9" (إذا كنت تدعم iPad)

**لأخذ Screenshots:**
```bash
# شغل على simulator
flutter run --release

# خذ screenshots من Simulator:
# Cmd + S في Simulator
```

### 4. رفع البناء:

**من Xcode:**
1. Product → Archive
2. انتظر حتى ينتهي الأرشفة
3. Distribute App
4. اختر **App Store Connect**
5. Upload

**أو من Terminal:**
```bash
# بناء وتصدير
flutter build ipa --release

# رفع للـ App Store
xcrun altool --upload-app --file build/ios/ipa/attendance.ipa \
  --type ios \
  --username "your@apple-id.com" \
  --password "app-specific-password"
```

### 5. إرسال للمراجعة:

1. في App Store Connect
2. اختر الـ Build المرفوع
3. املأ **What's New in This Version**
4. **Submit for Review**

---

## ⚠️ مشاكل شائعة وحلولها

### ❌ `pod install` يفشل:

```bash
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod repo update
pod install
cd ..
```

### ❌ Build يفشل - "No signing certificate":

**الحل:**
- تأكد من تسجيل الدخول بحساب Apple Developer في Xcode
- Xcode → Settings → Accounts → أضف حسابك

### ❌ "Runner.app is not properly signed":

**الحل:**
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

### ❌ App crashes عند البدء:

**الحل:**
- تأكد من Appwrite credentials صحيحة في `secure_config.dart`
- تحقق من network permissions في Info.plist

---

## 📋 Checklist قبل النشر

### التقني:
- [ ] `pod install` نجح بدون أخطاء
- [ ] Code signing معد بشكل صحيح
- [ ] Build يعمل على Simulator
- [ ] Build يعمل على جهاز حقيقي
- [ ] جميع الميزات تعمل (QR, Camera, Storage)
- [ ] Appwrite connection يعمل
- [ ] Permissions تعمل (Camera, Photos, etc)

### App Store:
- [ ] Screenshots جاهزة (جميع المقاسات)
- [ ] App Icon 1024x1024 جاهز
- [ ] وصف التطبيق مكتوب (عربي + إنجليزي)
- [ ] Privacy Policy URL جاهز
- [ ] Support URL/Email جاهز
- [ ] Keywords محددة
- [ ] Age Rating محدد

---

## 🚀 الأمر الكامل للبناء السريع:

```bash
# 1. تنظيف
flutter clean

# 2. تحديث dependencies
flutter pub get

# 3. تثبيت iOS pods
cd ios && pod install && cd ..

# 4. بناء
flutter build ipa --release

# ✅ الملف جاهز في: build/ios/ipa/
```

---

## 📞 روابط مفيدة:

- **Flutter iOS Deployment**: https://docs.flutter.dev/deployment/ios
- **App Store Connect**: https://appstoreconnect.apple.com
- **App Store Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Appwrite Docs**: https://appwrite.io/docs
- **Apple Developer**: https://developer.apple.com

---

## 💡 نصائح مهمة:

1. **احفظ Certificates و Provisioning Profiles** في مكان آمن
2. **App-Specific Password** لرفع البناء - أنشئه من appleid.apple.com
3. **TestFlight** - استخدمه للاختبار قبل النشر العام
4. **Version Numbers** - يجب زيادتها مع كل رفع جديد
5. **Privacy Policy** - مطلوبة وإلزامية

---

## ✅ الخلاصة:

**الكود جاهز 100% للـ iOS!**

لا تحتاج Firebase أو GoogleService-Info.plist - التطبيق يعمل على **Appwrite فقط**.

فقط محتاج:
1. Mac مع Xcode
2. `pod install`
3. Code signing
4. Build & Upload!

🎉 **جاهز للنشر على App Store!**
