// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';

class QuizPage extends StatefulWidget {
  final QuizModel quiz;
  final Map<String, String>? participant; // Changed to map containing id and name
  
  const QuizPage({super.key, required this.quiz, this.participant});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuestionModel> questions = [];
  Map<String, String> selectedAnswers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  int currentQuestionIndex = 0;
  PageController _pageController = PageController();
  DateTime? startTime;
  String? currentParticipantId;
  String? currentParticipantName;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    if (widget.participant != null) {
      currentParticipantId = widget.participant!['id'];
      currentParticipantName = widget.participant!['name'];
    }
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final databases = GetIt.I<Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.questionsCollectionId,
        queries: [
          Query.equal('quizId', widget.quiz.id!),
          Query.orderAsc('questionOrder'),
        ],
      );

      setState(() {
        questions = documents.documents
            .map((doc) {
              final question = QuestionModel.fromMap(doc.data);
              return question.copyWith(id: doc.$id);
            })
            .toList();
        isLoading = false;
      });

      if (questions.isEmpty) {
        _showNoQuestionsDialog();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الأسئلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoQuestionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('لا توجد أسئلة'),
          content: const Text('هذه المسابقة لا تحتوي على أسئلة بعد.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('العودة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveQuizResult(int score, int totalQuestions, List<String> answers) async {
    try {
      if (currentParticipantId == null || currentParticipantId!.isEmpty) {
        print('Warning: No participant name provided, skipping result save');
        return;
      }

      final databases = GetIt.I<Databases>();
      final timeTaken = startTime != null 
          ? DateTime.now().difference(startTime!).inSeconds 
          : null;

      final result = QuizResultModel(
        solverId: currentParticipantId!,
        solverName: currentParticipantName!,
        quizId: widget.quiz.id!,
        classId: Constants.classId,
        score: score,
        totalQuestions: totalQuestions,
        answers: answers,
        completedAt: DateTime.now(),
        timeTaken: timeTaken,
      );

      await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizResultsCollectionId,
        documentId: ID.unique(),
        data: result.toMap(),
      );

      print('Quiz result saved successfully for ${currentParticipantName}');
      print('Score: $score/$totalQuestions (${result.percentage.toStringAsFixed(1)}%)');
    } catch (e) {
      print('Error saving quiz result: $e');
      // Don't show error to user to avoid breaking the experience
    }
  }

  void _selectAnswer(String questionId, String answer) {
    setState(() {
      selectedAnswers[questionId] = answer;
    });
  }

  Future<void> _submitQuiz() async {
    if (selectedAnswers.length < questions.length) {
      bool? continueSubmit = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('أسئلة غير مجابة'),
            content: Text('لم تجب على ${questions.length - selectedAnswers.length} من الأسئلة. هل تريد المتابعة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('متابعة'),
              ),
            ],
          );
        },
      );

      if (continueSubmit != true) {
        return;
      }
    }

    setState(() {
      isSubmitting = true;
    });

    // Calculate score
    int correctAnswers = 0;
    List<String> userAnswers = [];
    
    for (final question in questions) {
      final selectedAnswer = selectedAnswers[question.id] ?? '';
      userAnswers.add(selectedAnswer);
      if (selectedAnswer.isNotEmpty && question.isCorrectAnswer(selectedAnswer)) {
        correctAnswers++;
      }
    }

    // Save results to database
    await _saveQuizResult(correctAnswers, questions.length, userAnswers);

    setState(() {
      isSubmitting = false;
    });

    // Show results
    _showResults(correctAnswers, questions.length, correctAnswers);
  }

  void _showResults(int correctAnswers, int totalQuestions, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  score >= totalQuestions/2 ? Icons.celebration : Icons.info_outline,
                  color: score >= totalQuestions/2 ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text('نتيجة المسابقة'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: score >= totalQuestions/2 ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: score >= totalQuestions/2 ? Colors.green[200]! : Colors.orange[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(score / totalQuestions * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: score >= totalQuestions/2 ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$correctAnswers من $totalQuestions',
                        style: TextStyle(
                          fontSize: 22,
                          color: score >= totalQuestions/2 ? Colors.green[600] : Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        score >= totalQuestions/2 ? 'أحسنت! 🎉' : '         ايه ده !!         ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: score >= totalQuestions/2 ? Colors.green[600] : Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'العودة للمسابقات',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(
      MediaQuery.of(context).size.height,
      MediaQuery.of(context).size.width,
    );

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
          children: [
            Text(
              widget.quiz.name,
              style: TextStyle(
                fontSize: Constants.deviceWidth / 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!isLoading && questions.isNotEmpty)
              Text(
                'سؤال ${currentQuestionIndex + 1} من ${questions.length}',
                style: TextStyle(
                  fontSize: Constants.deviceWidth / 30,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,

leading: Icon(Icons.quiz),

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
        child: isLoading
            ? Center(
                child: SpinKitWaveSpinner(
                  color: Colors.blueGrey,
                  size: 50.0,
                ),
              )
            : questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: Constants.deviceWidth / 4,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد أسئلة في هذه المسابقة',
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 20,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Progress bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'التقدم',
                                  style: TextStyle(
                                    fontSize: Constants.deviceWidth / 26,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${((currentQuestionIndex + 1) / questions.length * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: Constants.deviceWidth / 26,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (currentQuestionIndex + 1) / questions.length,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                              minHeight: 6,
                            ),
                          ],
                        ),
                      ),
                      
                      // Questions
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              currentQuestionIndex = index;
                            });
                          },
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            final selectedAnswer = selectedAnswers[question.id];
                            
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Question text
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          question.questionText,
                                          style: TextStyle(
                                            fontSize: Constants.deviceWidth / 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey[800],
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Choices
                                      _buildChoiceButton(question, 'A', question.choiceA, selectedAnswer),
                                      const SizedBox(height: 12),
                                      _buildChoiceButton(question, 'B', question.choiceB, selectedAnswer),
                                      const SizedBox(height: 12),
                                      _buildChoiceButton(question, 'C', question.choiceC, selectedAnswer),
                                      const SizedBox(height: 12),
                                      _buildChoiceButton(question, 'D', question.choiceD, selectedAnswer),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Navigation buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (currentQuestionIndex > 0)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _previousQuestion,
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('السابق'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueGrey,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            
                            if (currentQuestionIndex > 0 && currentQuestionIndex < questions.length - 1)
                              const SizedBox(width: 16),
                            
                            if (currentQuestionIndex < questions.length - 1)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _nextQuestion,
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('التالي'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            
                            if (currentQuestionIndex == questions.length - 1)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isSubmitting ? null : _submitQuiz,
                                  icon: isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  label: Text(isSubmitting ? 'جاري الإرسال...' : 'إرسال'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    ),
    );
  }

  Widget _buildChoiceButton(QuestionModel question, String choice, String text, String? selectedAnswer) {
    final isSelected = selectedAnswer == choice;
    
    return InkWell(
      onTap: () => _selectAnswer(question.id!, choice),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey[100] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blueGrey : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blueGrey : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blueGrey : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '$choice.',
              style: TextStyle(
                fontSize: Constants.deviceWidth / 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blueGrey[800] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: Constants.deviceWidth / 26,
                  color: isSelected ? Colors.blueGrey[800] : Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}