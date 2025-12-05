import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../helper/styles.dart';
import '../home_page.dart';
import '../models/teacher_model.dart';

class TeacherLogin extends StatefulWidget {
  final String classId;
  final String className;
  final String adminPassword;
  
  const TeacherLogin({
    super.key, 
    required this.classId,
    required this.className,
    required this.adminPassword,
  });

  @override
  State<TeacherLogin> createState() => _TeacherLoginState();
}

class _TeacherLoginState extends State<TeacherLogin> {
  final TextEditingController _teacherPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkSavedTeacherPassword();
  }

  @override
  void dispose() {
    _teacherPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedTeacherPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTeacherPassword = prefs.getString('teacherPassword');
    
    if (savedTeacherPassword != null && savedTeacherPassword.isNotEmpty) {
      // Auto-login with saved teacher password
      _teacherPasswordController.text = savedTeacherPassword;
      // Auto-login silently
      await _loginWithTeacherPassword(savedTeacherPassword);
    }
  }

  Future<void> _loginWithTeacherPassword(String teacherPassword) async {
    if (teacherPassword.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(child: Text('يرجى إدخال كلمة مرور المدرس')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      TeacherModel? teacher;
      
      try {
        // First try: Query teacher directly by teacherPassword
        final documents = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.teachersCollectionId,
          queries: [
            Query.equal('teacherPassword', teacherPassword.trim()),
          ],
        );

        if (documents.documents.isNotEmpty) {
          final teacherData = documents.documents.first.data;
          print('Teacher data from Appwrite: $teacherData'); // Debug print
          teacher = TeacherModel.fromMap(teacherData);
        }
      } catch (queryError) {
        print('Query failed, trying fallback method: $queryError');
        
        // Fallback: Load all teachers and filter locally
        final allDocuments = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.teachersCollectionId,
        );
        
        for (var doc in allDocuments.documents) {
          try {
            final teacherModel = TeacherModel.fromMap(doc.data);
            if (teacherModel.teacherPassword == teacherPassword.trim()) {
              teacher = teacherModel;
              break;
            }
          } catch (e) {
            print('Error parsing teacher document: $e');
            continue;
          }
        }
      }

      if (teacher == null) {
        throw Exception('Teacher not found');
      }

      // Save login data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password', widget.adminPassword);
      await prefs.setString('userPassword', ''); // Not applicable for teacher
      await prefs.setString('className', widget.className);
      await prefs.setString('classId', widget.classId);
      await prefs.setString('teacherPassword', teacherPassword.trim());
      await prefs.setString('teacherId', teacher.id ?? '');
      await prefs.setString('teacherName', teacher.name);
      await prefs.setString('teacherRole', teacher.role.value);

      // Set global constants
      Constants.classId = widget.classId;
      Constants.passwordValue = widget.adminPassword;
      Constants.className = widget.className;
      Constants.isUser = false;

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        String errorMessage = 'كلمة مرور الخادم غير صحيحة';
        
        if (e.toString().contains('subtype')) {
          errorMessage = 'خطأ في تنسيق البيانات. يرجى المحاولة مرة أخرى';
        } else if (e.toString().contains('Teacher not found')) {
          errorMessage = 'كلمة مرور الخادم غير صحيحة';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text(errorMessage)),
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
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage(Constants.backgroundImage),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width / 5,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(Constants.logo),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // Title
                          Text(
                            'تسجيل دخول المدرس',
                            style: TextStyle(
                              fontSize: Constants.deviceWidth / 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Class name
                          Text(
                            widget.className,
                            style: TextStyle(
                              fontSize: Constants.deviceWidth / 22,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 15),                        // Teacher password field
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(5),
                            child: TextField(
                              style: Styles.textStyleSmall,
                              onTapOutside: (event) {
                                FocusScope.of(context).unfocus();
                              },
                              controller: _teacherPasswordController,
                              decoration: InputDecoration(
                                labelText: 'كلمة مرور الخادم..',
                                labelStyle: TextStyle(fontSize: Constants.deviceWidth / 22),
                                fillColor: Colors.white,
                                filled: true,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              onSubmitted: (value) {
                                _loginWithTeacherPassword(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _loginWithTeacherPassword(_teacherPasswordController.text);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: Constants.deviceWidth / 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // // Back button
                        // TextButton(
                        //   onPressed: () {
                        //     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                        //   },
                        //   child: Text(
                        //     'العودة',
                        //     style: TextStyle(
                        //       fontSize: Constants.deviceWidth / 24,
                        //       color: Colors.blueGrey,
                        //     ),
                        //   ),
                        // ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}