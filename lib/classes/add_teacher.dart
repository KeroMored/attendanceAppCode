// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/teacher_model.dart';
import 'teacher_data_page.dart';

class AddTeacher extends StatefulWidget {
  const AddTeacher({super.key});

  @override
  State<AddTeacher> createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacher> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumber1Controller = TextEditingController();
  final _phoneNumber2Controller = TextEditingController();
  
  bool _isLoading = false;
  TeacherRole _selectedRole = TeacherRole.user;
  
  // For tracking used passwords to ensure uniqueness
  Set<String> usedPasswords = {};

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneNumber1Controller.dispose();
    _phoneNumber2Controller.dispose();
    super.dispose();
  }

  // Generate unique password function similar to student creation
  String generateUniquePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    String password;
    do {
      password = '';
      for (int i = 0; i < 8; i++) {
        password += chars[(DateTime.now().microsecondsSinceEpoch * (i + 1)) % chars.length];
      }
    } while (usedPasswords.contains(password));
    
    usedPasswords.add(password);
    return password;
  }

  // Get current class admin password
  Future<String?> getCurrentClassAdminPassword() async {
    try {
      final databases = GetIt.I<Databases>();
      final document = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.servicesCollectionId,
        documentId: Constants.classId,
      );
      return document.data['adminsPassword'] as String?;
    } catch (e) {
      print('Error getting admin password: \$e');
      return null;
    }
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      
      // Generate unique password for the teacher
      String generatedPassword = generateUniquePassword();
      
      // Get current class admin password
      String? adminPassword = await getCurrentClassAdminPassword();
      if (adminPassword == null) {
        throw Exception('لا يمكن العثور على كلمة مرور الإدارة');
      }
      
      final teacherModel = TeacherModel(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phoneNumber1: _phoneNumber1Controller.text.trim().isEmpty ? null : _phoneNumber1Controller.text.trim(),
        phoneNumber2: _phoneNumber2Controller.text.trim().isEmpty ? null : _phoneNumber2Controller.text.trim(),
        teacherPassword: generatedPassword,
        role: _selectedRole,
      );

      await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: ID.unique(),
        data: teacherModel.toMap(),
      );

      if (mounted) {
        // Navigate to Teacher Data Page instead of showing dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDataPage(
              teacher: teacherModel.copyWith(id: 'generated'),
              generatedPassword: generatedPassword,
              adminPassword: adminPassword,
            ),
          ),
        );
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المدرس: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة خادم',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: SpinKitWaveSpinner(
                  color: Colors.blueGrey,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'بيانات الخادم',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Name field (required)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'الاسم مطلوب';
                              }
                              return null;
                            },
                          ),
          const SizedBox(height: 16),
                          
                          // Role dropdown (required)
                          DropdownButtonFormField<TeacherRole>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'الدور *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.admin_panel_settings),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: TeacherRole.user,
                                child: Text(TeacherRole.user.displayName),
                              ),
                              DropdownMenuItem(
                                value: TeacherRole.admin,
                                child: Text(TeacherRole.admin.displayName),
                              ),
                            ],
                            onChanged: (TeacherRole? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedRole = newValue;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'الدور مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Address field (optional)
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'العنوان',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Number 1 field (optional)
                          TextFormField(
                            controller: _phoneNumber1Controller,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف الأول',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Number 2 field (optional)
                          TextFormField(
                            controller: _phoneNumber2Controller,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف الثاني',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        

                                         const SizedBox(height: 16),
                          
                          // Password auto-generation notice
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'سيتم إنشاء كلمة مرور تلقائياً للخادم',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                         
                          const SizedBox(height: 24),
                          
                          // Note about required fields
                          const Text(
                            '* الحقول المطلوبة',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Save button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveTeacher,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'حفظ',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}