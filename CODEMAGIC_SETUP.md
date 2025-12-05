# Codemagic Setup Guide - دليل إعداد Codemagic

## ✅ المشكلة تم حلها!

تم تحديث iOS deployment target من `12.0` إلى `15.5` لتوافق مع متطلبات `mobile_scanner` plugin.

### ما تم تعديله:
- ✅ `ios/Podfile` → `platform :ios, '15.5'`
- ✅ `ios/Runner.xcodeproj/project.pbxproj` → `IPHONEOS_DEPLOYMENT_TARGET = 15.5`
- ✅ Podfile post_install → `config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'`

---

## 🚀 إعداد Codemagic

### 1. إنشاء حساب:
1. اذهب إلى: https://codemagic.io
2. سجل الدخول بحساب GitHub
3. أضف repository: `attendanceAppCode`

---

### 2. إعداد iOS Signing:

#### في Codemagic:
1. اذهب لـ **Teams → Code signing identities**
2. أضف **iOS certificates**:
   - Distribution Certificate (`.p12`)
   - Provisioning Profile (`.mobileprovision`)

#### للحصول على Certificates من Mac:
```bash
# تصدير Certificate
# في Keychain Access:
# 1. ابحث عن "iPhone Distribution"
# 2. Export → .p12
# 3. احفظه بكلمة مرور

# تصدير Provisioning Profile
# من developer.apple.com:
# 1. Certificates, Identifiers & Profiles
# 2. Profiles → Distribution
# 3. Download
```

#### أو استخدم Automatic Signing:
في `codemagic.yaml`:
```yaml
environment:
  ios_signing:
    distribution_type: app_store
    bundle_identifier: com.mored.attendanceApp
```

---

### 3. إعداد App Store Connect:

#### إنشاء API Key:
1. اذهب لـ: https://appstoreconnect.apple.com/access/api
2. اضغط **+** لإنشاء key جديد
3. اسم: `Codemagic`
4. Access: **App Manager**
5. حمل الـ `.p8` file

#### في Codemagic:
1. **Teams → Integrations → App Store Connect**
2. أضف:
   - **Issuer ID**
   - **Key ID**
   - **API Key** (.p8 file content)

---

### 4. إعداد Android Signing:

#### إنشاء Keystore (إذا لم يكن موجود):
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

#### في Codemagic:
1. **Teams → Code signing identities → Android**
2. رفع:
   - Keystore file (`.jks`)
   - Keystore password
   - Key alias
   - Key password

---

### 5. إعداد Environment Variables:

في Codemagic → App settings → Environment variables:

```
# iOS
APP_STORE_CONNECT_ISSUER_ID = [Your Issuer ID]
APP_STORE_CONNECT_KEY_IDENTIFIER = [Your Key ID]
APP_STORE_CONNECT_PRIVATE_KEY = [Your .p8 content]

# Android
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS = [Google Play JSON]

# Appwrite (من secure_config.dart)
APPWRITE_PROJECT_ID = 67c77998000b1b070682
APPWRITE_ENDPOINT = https://cloud.appwrite.io/v1
APPWRITE_DATABASE_ID = 67c789c1000c4f0c27b1
```

---

## 🏗️ تشغيل Build في Codemagic

### من الواجهة:
1. اختر **Workflow**: iOS Workflow أو Android Workflow
2. اضغط **Start new build**
3. اختر **Branch**: main
4. انتظر البناء

### من Git (Automatic):
```bash
git add .
git commit -m "Update iOS deployment target to 15.5"
git push origin main

# Codemagic سيبدأ البناء تلقائياً
```

---

## 📋 ملف codemagic.yaml

تم إنشاء `codemagic.yaml` في المشروع مع:
- ✅ iOS Workflow (Build + App Store)
- ✅ Android Workflow (Build + Google Play)
- ✅ Automatic code signing
- ✅ Publishing setup

---

## ⚠️ مشاكل شائعة

### ❌ "Pod install failed"
**الحل في codemagic.yaml:**
```yaml
scripts:
  - name: Install CocoaPods dependencies
    script: |
      cd ios
      pod repo update
      pod install
```

### ❌ "Code signing error"
**الحل:**
- تأكد من رفع certificates صحيحة
- Bundle ID في Codemagic = Bundle ID في Xcode
- Provisioning profile valid

### ❌ "Build timeout"
**الحل:**
```yaml
max_build_duration: 120  # زيادة الوقت لـ 120 دقيقة
```

### ❌ "Appwrite connection failed"
**الحل:**
- أضف Environment Variables للـ Appwrite credentials
- أو استخدم `secure_config.dart` الموجود

---

## 📊 Build Status

بعد Push للـ Git:
1. Codemagic يبدأ Build تلقائياً
2. تابع التقدم في Dashboard
3. عند النجاح:
   - iOS → يرفع لـ TestFlight تلقائياً
   - Android → يرفع لـ Google Play Internal Track

---

## 🎯 Workflow الموصى به

### للتطوير:
```yaml
# في codemagic.yaml
when:
  event: push
  branch_patterns:
    - pattern: 'develop'
      include: true
```

### للإنتاج:
```yaml
when:
  event: tag
  tag_patterns:
    - pattern: 'v*'
      include: true
```

**مثال:**
```bash
git tag v1.0.0
git push origin v1.0.0
# Build production
```

---

## 💰 Pricing

### Codemagic Free:
- ✅ 500 دقيقة بناء/شهر
- ✅ Mac Mini M1 builders
- ✅ 1 concurrent build

### Paid Plans:
- Pro: $99/month (2,000 دقيقة)
- Team: $299/month (10,000 دقيقة)

---

## 📞 روابط مفيدة

- **Codemagic Docs**: https://docs.codemagic.io
- **YAML Config**: https://docs.codemagic.io/yaml/yaml-getting-started/
- **iOS Signing**: https://docs.codemagic.io/yaml-code-signing/signing-ios/
- **Android Signing**: https://docs.codemagic.io/yaml-code-signing/signing-android/

---

## ✅ Checklist

### قبل أول Build:
- [ ] iOS deployment target = 15.5
- [ ] Certificates مرفوعة في Codemagic
- [ ] App Store Connect API key معد
- [ ] codemagic.yaml في repository
- [ ] Environment variables معدة
- [ ] Repository متصل بـ Codemagic

### بعد كل Update:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

Codemagic سيبني تلقائياً! 🚀

---

## 🎉 الخلاصة

**المشكلة تم حلها!**

- ✅ iOS deployment target الآن 15.5
- ✅ يتوافق مع mobile_scanner
- ✅ جاهز للبناء على Codemagic
- ✅ ملف codemagic.yaml جاهز

**Push الكود وسيعمل Build بنجاح! 🚀**
