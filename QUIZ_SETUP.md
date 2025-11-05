# إعداد المسابقات - Quiz Setup

## المطلوب في قاعدة البيانات Appwrite:

### 1. إنشاء Collection للمسابقات (Quizzes):
- Collection ID: `quizzes`
- Attributes مطلوبة:
  - `name` (String, required) - اسم المسابقة
  - `classId` (String, required, indexed) - معرف الفصل
  - `isVisible` (Boolean, default: false) - ظهور المسابقة
  - `createdAt` (DateTime, required) - تاريخ الإنشاء
  - `updatedAt` (DateTime, optional) - تاريخ التحديث
  - `questionIds` (String Array, optional) - معرفات الأسئلة

### 2. إنشاء Collection للأسئلة (Questions):
- Collection ID: `questions`
- Attributes مطلوبة:
  - `quizId` (String, required, indexed) - معرف المسابقة
  - `questionText` (String, required) - نص السؤال
  - `choiceA` (String, required) - الخيار الأول
  - `choiceB` (String, required) - الخيار الثاني
  - `choiceC` (String, required) - الخيار الثالث
  - `choiceD` (String, required) - الخيار الرابع
  - `correctAnswer` (String, required) - الإجابة الصحيحة (A, B, C, أو D)
  - `questionOrder` (Integer, required) - ترتيب السؤال
  - `createdAt` (DateTime, required) - تاريخ الإنشاء

### 3. إنشاء Indexes:
- في collection `quizzes`: index على `classId`
- في collection `questions`: index على `quizId`

### 4. Permissions مطلوبة:
- Read: Any
- Create: Any
- Update: Any
- Delete: Any

## خطوات الإعداد:

1. اذهب إلى Appwrite Console
2. اختر قاعدة البيانات الخاصة بك
3. أنشئ Collection جديد باسم "quizzes"
4. أضف جميع الـ attributes المطلوبة
5. أنشئ index على classId
6. كرر نفس الخطوات لـ collection "questions"
7. تأكد من الـ permissions

## رسائل الخطأ الشائعة:

- "Collection with the requested ID could not be found" = يجب إنشاء الـ collections أولاً
- "Index with the requested ID could not be found" = يجب إنشاء index على classId و quizId
- "Attribute with the requested ID could not be found" = نقص في الـ attributes المطلوبة

## تجربة الميزة:

بعد إنشاء الـ collections:
1. اذهب للصفحة الرئيسية واضغط على "مسابقات"
2. اضغط على زر + لإضافة مسابقة جديدة
3. أضف اسم المسابقة
4. أضف الأسئلة مع الخيارات
5. فعّل المسابقة من قائمة المسابقات لتظهر للطلاب