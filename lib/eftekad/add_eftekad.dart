// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;
import '../helper/appwrite_services.dart';

class AddEftekad extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final String? selectedStudentId;
  final Map<String, dynamic>? initialRecord; // when provided -> edit mode

  const AddEftekad({
    Key? key,
    required this.students,
    this.selectedStudentId,
    this.initialRecord,
  }) : super(key: key);

  @override
  State<AddEftekad> createState() => _AddEftekedState();
}

class _AddEftekedState extends State<AddEftekad> {
  final _formKey = GlobalKey<FormState>();
  String? selectedStudentId;
  String selectedVisitType = 'زيارة منزلية';
  String selectedReason = 'افتقاد دوري';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();
  bool followUpRequired = false;
  bool isLoading = false;
  bool get isEdit => widget.initialRecord != null;

  final List<String> visitTypes = [
    'زيارة منزلية',
    'اتصال هاتفي',
    'زيارة في الكنيسة',
    'رسالة نصية',
    'لقاء عام',
  ];

  final List<String> visitReasons = [
    'افتقاد دوري',
    'غياب متكرر',
    'مشكلة سلوكية',
    'مشكلة عائلية',
    'تشجيع ومتابعة',
    'مرض',
    'تغيير عنوان',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    selectedStudentId = widget.selectedStudentId;
    if (isEdit) {
      final r = widget.initialRecord!;
      // student id
      selectedStudentId = (r['studentId'] ?? selectedStudentId)?.toString();
      // visit type
      selectedVisitType = (r['visitType'] ?? selectedVisitType).toString();
      // reason and custom reason handling
      final existingReason = (r['reason'] ?? selectedReason).toString();
      if (visitReasons.contains(existingReason)) {
        selectedReason = existingReason;
      } else {
        selectedReason = 'أخرى';
        _customReasonController.text = existingReason;
      }
      _notesController.text = (r['notes'] ?? '').toString();
      _dateController.text = (r['visitDate'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now())).toString();
      followUpRequired = r['followUpRequired'] == true;
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    dtp.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2020, 1, 1),
      maxTime: DateTime.now(),
      currentTime: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      locale: dtp.LocaleType.ar,
      onConfirm: (picked) {
        setState(() {
          _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      },
    );
  }

  Future<void> _saveEftekad() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار طالب')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      
      final reason = selectedReason == 'أخرى' ? _customReasonController.text : selectedReason;
      
      if (isEdit) {
        final docId = (widget.initialRecord!['id'] ?? '').toString();
        await databases.updateDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.eftekedCollectionId,
          documentId: docId,
          data: {
            'studentId': selectedStudentId,
            'visitType': selectedVisitType,
            'reason': reason,
            'notes': _notesController.text,
            'visitDate': _dateController.text,
            'followUpRequired': followUpRequired,
          },
        );
      } else {
        await databases.createDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.eftekedCollectionId,
          documentId: ID.unique(),
          data: {
            'studentId': selectedStudentId,
            'visitType': selectedVisitType,
            'reason': reason,
            'notes': _notesController.text,
            'visitDate': _dateController.text,
            'followUpRequired': followUpRequired,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الافتقاد بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الافتقاد: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'تعديل الافتقاد' : 'إضافة افتقاد',
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Student Selection
                DropdownButtonFormField<String>(
                  value: selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: 'اختر الطالب',
                    labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.students.map((student) {
                    return DropdownMenuItem<String>(
                      value: student['id'],
                      child: Text(
                        student['name'] ?? 'غير محدد',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStudentId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار طالب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Visit Type
                DropdownButtonFormField<String>(
                  value: selectedVisitType,
                  decoration: const InputDecoration(
                    labelText: 'نوع الافتقاد',
                    labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(),
                  ),
                  items: visitTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVisitType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Visit Date
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الافتقاد',
                    labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار التاريخ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Visit Reason
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'سبب الافتقاد',
                    labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(),
                  ),
                  items: visitReasons.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Custom Reason Field (if "أخرى" is selected)
                if (selectedReason == 'أخرى') ...[
                  TextFormField(
                    controller: _customReasonController,
                    decoration: const InputDecoration(
                      labelText: 'اكتب السبب',
                      labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (selectedReason == 'أخرى' && (value == null || value.isEmpty)) {
                        return 'يرجى كتابة السبب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    labelStyle: TextStyle(fontFamily: 'NotoSansArabic'),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Follow-up Required
                CheckboxListTile(
                  title: const Text(
                    'يتطلب متابعة',
                    style: TextStyle(fontFamily: 'NotoSansArabic'),
                  ),
                  value: followUpRequired,
                  onChanged: (value) {
                    setState(() {
                      followUpRequired = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: isLoading ? null : _saveEftekad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'تعديل الافتقاد' : 'حفظ الافتقاد',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}