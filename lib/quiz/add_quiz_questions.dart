// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';

class AddQuizQuestions extends StatefulWidget {
  final QuizModel quiz;
  
  const AddQuizQuestions({super.key, required this.quiz});

  @override
  State<AddQuizQuestions> createState() => _AddQuizQuestionsState();
}

class _AddQuizQuestionsState extends State<AddQuizQuestions> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _choiceAController = TextEditingController();
  final _choiceBController = TextEditingController();
  final _choiceCController = TextEditingController();
  final _choiceDController = TextEditingController();
  
  String _correctAnswer = 'A';
  bool _isLoading = false;
  List<QuestionModel> _questions = [];
  int _currentQuestionNumber = 1;

  @override
  void dispose() {
    _questionController.dispose();
    _choiceAController.dispose();
    _choiceBController.dispose();
    _choiceCController.dispose();
    _choiceDController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _questionController.clear();
    _choiceAController.clear();
    _choiceBController.clear();
    _choiceCController.clear();
    _choiceDController.clear();
    _correctAnswer = 'A';
  }

  Future<void> _addQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      
      final question = QuestionModel(
        quizId: widget.quiz.id!,
        questionText: _questionController.text.trim(),
        choiceA: _choiceAController.text.trim(),
        choiceB: _choiceBController.text.trim(),
        choiceC: _choiceCController.text.trim(),
        choiceD: _choiceDController.text.trim(),
        correctAnswer: _correctAnswer,
        questionOrder: _currentQuestionNumber,
        createdAt: DateTime.now(),
      );

      await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.questionsCollectionId,
        documentId: ID.unique(),
        data: question.toMap(),
      );

      setState(() {
        _questions.add(question);
        _currentQuestionNumber++;
        _clearForm();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة السؤال رقم ${_questions.length}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة السؤال: ${e.message}'),
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

  Future<void> _finishAddingQuestions() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة سؤال واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool? confirmFinish = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إنهاء إضافة الأسئلة'),
          content: Text('تم إضافة ${_questions.length} سؤال. هل تريد إنهاء إضافة الأسئلة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إضافة المزيد'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('إنهاء'),
            ),
          ],
        );
      },
    );

    if (confirmFinish == true) {
      Navigator.pop(context, _questions.length);
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
        title: Column(
          children: [
            Text(
              'إضافة أسئلة',
              style: TextStyle(
                fontSize: Constants.deviceWidth / 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.quiz.name,
              style: TextStyle(
                fontSize: Constants.deviceWidth / 28,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (_questions.isNotEmpty)
            IconButton(
              onPressed: _finishAddingQuestions,
              icon: const Icon(Icons.check),
              tooltip: 'إنهاء',
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السؤال رقم $_currentQuestionNumber',
                    style: TextStyle(
                      fontSize: Constants.deviceWidth / 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  if (_questions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        'تم إضافة ${_questions.length} سؤال',
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 28,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question input
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: Colors.blueGrey,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'نص السؤال',
                                    style: TextStyle(
                                      fontSize: Constants.deviceWidth / 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              TextFormField(
                                controller: _questionController,
                                decoration: InputDecoration(
                                  hintText: 'اكتب السؤال هنا...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'نص السؤال مطلوب';
                                  }
                                  if (value.trim().length < 5) {
                                    return 'السؤال يجب أن يكون 5 أحرف على الأقل';
                                  }
                                  return null;
                                },
                                maxLines: 3,
                                style: TextStyle(fontSize: Constants.deviceWidth / 25),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Choices
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.list,
                                    color: Colors.blueGrey,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'الخيارات',
                                    style: TextStyle(
                                      fontSize: Constants.deviceWidth / 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Choice A
                              _buildChoiceField(
                                controller: _choiceAController,
                                label: 'الخيار أ',
                                value: 'A',
                              ),
                              const SizedBox(height: 12),
                              
                              // Choice B
                              _buildChoiceField(
                                controller: _choiceBController,
                                label: 'الخيار ب',
                                value: 'B',
                              ),
                              const SizedBox(height: 12),
                              
                              // Choice C
                              _buildChoiceField(
                                controller: _choiceCController,
                                label: 'الخيار ج',
                                value: 'C',
                              ),
                              const SizedBox(height: 12),
                              
                              // Choice D
                              _buildChoiceField(
                                controller: _choiceDController,
                                label: 'الخيار د',
                                value: 'D',
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Correct answer
                      Card(
                        elevation: 3,
                        color: Colors.green[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'الإجابة الصحيحة',
                                    style: TextStyle(
                                      fontSize: Constants.deviceWidth / 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                'اختر الإجابة الصحيحة:',
                                style: TextStyle(
                                  fontSize: Constants.deviceWidth / 26,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  _buildCorrectAnswerOption('أ', 'A'),
                                  _buildCorrectAnswerOption('ب', 'B'),
                                  _buildCorrectAnswerOption('ج', 'C'),
                                  _buildCorrectAnswerOption('د', 'D'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Add question button
                      Container(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addQuestion,
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
                                    const Icon(Icons.add),
                                    const SizedBox(width: 8),
                                    Text(
                                      'إضافة السؤال',
                                      style: TextStyle(
                                        fontSize: Constants.deviceWidth / 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      if (_questions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _finishAddingQuestions,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              side: BorderSide(color: Colors.green[700]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline),
                                const SizedBox(width: 8),
                                Text(
                                  'إنهاء إضافة الأسئلة',
                                  style: TextStyle(
                                    fontSize: Constants.deviceWidth / 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
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

  Widget _buildChoiceField({
    required TextEditingController controller,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _correctAnswer,
          onChanged: (String? val) {
            setState(() {
              _correctAnswer = val!;
            });
          },
          activeColor: Colors.green,
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label مطلوب';
              }
              return null;
            },
            style: TextStyle(fontSize: Constants.deviceWidth / 26),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectAnswerOption(String label, String value) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(
          label,
          style: TextStyle(fontSize: Constants.deviceWidth / 28),
        ),
        value: value,
        groupValue: _correctAnswer,
        onChanged: (String? val) {
          setState(() {
            _correctAnswer = val!;
          });
        },
        activeColor: Colors.green,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}