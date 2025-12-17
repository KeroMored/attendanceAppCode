# إعداد جدول نتائج المسابقات - Quiz Results Setup

## المطلوب في قاعدة البيانات Appwrite:

### إنشاء Collection للنتائج (Quiz Results):
- **Collection ID**: `quiz_results`

### Attributes مطلوبة:

1. **participantName** (String, required)
   - اسم المشارك في المسابقة
   - Max Length: 100
   - Required: Yes

2. **quizId** (String, required, indexed)
   - معرف المسابقة
   - Max Length: 100
   - Required: Yes
   - Index: Yes (للبحث السريع)

3. **classId** (String, required, indexed)
   - معرف الفصل
   - Max Length: 100
   - Required: Yes
   - Index: Yes (للبحث بالفصل)

4. **score** (Integer, required)
   - النتيجة المحققة
   - Min: 0
   - Required: Yes
   - Index: Yes (للترتيب)

5. **totalQuestions** (Integer, required)
   - إجمالي عدد الأسئلة
   - Min: 1
   - Required: Yes

6. **answers** (String Array, optional)
   - إجابات المشارك
   - Max Items: 100
   - Required: No

7. **completedAt** (DateTime, required)
   - تاريخ ووقت إنهاء المسابقة
   - Required: Yes

8. **timeTaken** (Integer, optional)
   - الوقت المستغرق بالثواني
   - Min: 0
   - Required: No

### Indexes مطلوبة:

1. **quizId Index**:
   - Type: Key
   - Attribute: quizId
   - Order: ASC

2. **classId Index**:
   - Type: Key
   - Attribute: classId
   - Order: ASC

3. **score Index**:
   - Type: Key
   - Attribute: score
   - Order: DESC (للترتيب من الأعلى إلى الأقل)

### Permissions مطلوبة:

- **Read**: Any
- **Create**: Any
- **Update**: Any
- **Delete**: Any

## خطوات الإعداد:

1. اذهب إلى **Appwrite Console**
2. اختر قاعدة البيانات الخاصة بك
3. انقر على **Create Collection**
4. اكتب **Collection ID**: `quiz_results`
5. أضف جميع الـ **Attributes** المطلوبة أعلاه
6. أنشئ **Indexes** المطلوبة
7. تأكد من **Permissions** الصحيحة

## الميزات الجديدة:

### 1. **طلب الاسم قبل بدء المسابقة**:
- نافذة إدخال اسم أنيقة
- التحقق من صحة الاسم
- عدم السماح بالمسابقة بدون اسم

### 2. **زر "نتائج المسابقات" للمدراء فقط**:
- يظهر في الصفحة الرئيسية
- يأخذ إلى صفحة عرض المسابقات للنتائج

### 3. **صفحة النتائج**:
- عرض جميع المسابقات
- إحصائيات لكل مسابقة
- ترتيب المشاركين حسب النتيجة
- تصنيف الدرجات (ممتاز، جيد، إلخ)
- رموز خاصة للمراكز الثلاثة الأولى

### 4. **تحسينات UI**:
- واجهة جميلة ومتجاوبة
- ألوان مختلفة حسب النتائج
- إحصائيات مفصلة
- تاريخ ووقت الإكمال

## رسائل الخطأ الشائعة:

- **"Collection with the requested ID could not be found"** = يجب إنشاء الـ collection أولاً
- **"Index with the requested ID could not be found"** = يجب إنشاء الـ indexes المطلوبة
- **"Document with the requested ID could not be found"** = مشكلة في الربط بين المسابقات والنتائج

## بعد الإعداد:

1. **اختبر إنشاء المسابقة**
2. **اختبر حل المسابقة مع إدخال الاسم**
3. **تأكد من حفظ النتائج**
4. **اختبر عرض النتائج للمدراء**
5. **تأكد من الترتيب الصحيح للنتائج**