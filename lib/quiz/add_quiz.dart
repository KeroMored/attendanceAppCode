// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/quiz_model.dart';
import 'add_quiz_questions.dart';

class AddQuiz extends StatefulWidget {
  const AddQuiz({super.key});

  @override
  State<AddQuiz> createState() => _AddQuizState();
}

class _AddQuizState extends State<AddQuiz> {
  final _formKey = GlobalKey<FormState>();
  final _quizNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quizNameController.dispose();
    super.dispose();
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      
      final quiz = QuizModel(
        name: _quizNameController.text.trim(),
        classId: Constants.classId,
        isVisible: false, // Default to hidden
        createdAt: DateTime.now(),
      );

      final document = await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizzesCollectionId,
        documentId: ID.unique(),
        data: quiz.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المسابقة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to add questions page
        bool? addQuestions = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('إضافة أسئلة'),
              content: Text('جاهز لإضافة الأسئلة لمسابقة "${_quizNameController.text.trim()}" الآن؟'),
              actions: [
         
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('نعم'),
                ),
              ],
            );
          },
        );

        if (addQuestions == true) {
          final createdQuiz = quiz.copyWith(id: document.$id);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddQuizQuestions(quiz: createdQuiz),
            ),
          );
        }

        Navigator.pop(context, true); // Return true to indicate success
      }
    } on AppwriteException catch (e) {
      print('AppwriteException creating quiz: ${e.message}');
      if (mounted) {
        String errorMessage = 'خطأ في إنشاء المسابقة';
        if (e.message?.contains('Collection with the requested ID could not be found') == true) {
          errorMessage = 'يجب إنشاء جدول "quizzes" في قاعدة البيانات أولاً';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: ${e.message}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('General error creating quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
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
    Constants.setSize(
      MediaQuery.of(context).size.height,
      MediaQuery.of(context).size.width,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة مسابقة جديدة',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey.withOpacity(0.1), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Quiz name input
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.quiz,
                                    color: Colors.blueGrey,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'معلومات المسابقة',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _quizNameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم المسابقة *',
                                  hintText: 'أدخل اسم المسابقة',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.title),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'اسم المسابقة مطلوب';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'اسم المسابقة يجب أن يكون 3 أحرف على الأقل';
                                  }
                                  return null;
                                },
                                maxLines: 2,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info card
                      Card(
                        elevation: 2,
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ملاحظات',
                                    style: TextStyle(
                                      fontSize: Constants.deviceWidth / 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• المسابقة ستكون مخفية افتراضياً\n'
                                '• يمكنك إظهارها وإخفاؤها من قائمة المسابقات\n'
                                '• ستحتاج لإضافة أسئلة بعد إنشاء المسابقة',
                                style: TextStyle(
                                  fontSize: Constants.deviceWidth / 28,
                                  color: Colors.blue[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                   //   const Spacer(),
                      SizedBox(height: 30),
                      // Create button
                      Container(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 3,
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_circle_outline),
                                    const SizedBox(width: 8),
                                    Text(
                                      'إنشاء المسابقة',
                                      style: TextStyle(
                                        fontSize: Constants.deviceWidth / 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}