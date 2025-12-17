// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';

class QuizResultsPage extends StatefulWidget {
  final QuizModel quiz;

  const QuizResultsPage({Key? key, required this.quiz}) : super(key: key);

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  List<QuizResultModel> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        isLoading = true;
      });

      final databases = GetIt.I<Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizResultsCollectionId,
        queries: [
          Query.equal('quizId', widget.quiz.id!),
          Query.equal('classId', Constants.classId),
          Query.orderDesc('score'), // Order by highest score first
          Query.orderDesc('\$createdAt'), // Then by completion time
        ],
      );

      setState(() {
        results = documents.documents
            .map((doc) {
              try {
                Map<String, dynamic> data = Map<String, dynamic>.from(doc.data);
                data['\$id'] = doc.$id;
                return QuizResultModel.fromMap(data);
              } catch (e) {
                print('Error parsing quiz result: $e');
                return null;
              }
            })
            .where((result) => result != null)
            .cast<QuizResultModel>()
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading quiz results: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل النتائج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.amber;
    return Colors.red;
  }

  IconData _getRankIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events; // Gold
      case 1:
        return Icons.military_tech; // Silver
      case 2:
        return Icons.stars; // Bronze
      default:
        return Icons.person;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نتائج المسابقة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.quiz.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              )
            : results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج لهذه المسابقة بعد',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'لم يقم أحد بحل هذه المسابقة حتى الآن',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Statistics header
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'المشاركين',
                              results.length.toString(),
                              Icons.people,
                              Colors.blue,
                            ),
                            _buildStatItem(
                              'أعلى نتيجة',
                              results.isNotEmpty
                                  ? '${results.first.score}/${results.first.totalQuestions}'
                                  : '0/0',
                              Icons.star,
                              Colors.amber,
                            ),
                            _buildStatItem(
                              'متوسط النتائج',
                              results.isNotEmpty
                                  ? '${(results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length).toStringAsFixed(1)}%'
                                  : '0%',
                              Icons.analytics,
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                      // Results list
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadResults,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final result = results[index];
                              final percentage = result.percentage;
                              final isTopThree = index < 3;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: isTopThree
                                      ? Border.all(
                                          color: _getRankColor(index),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Card(
                                  elevation: isTopThree ? 4 : 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getRankColor(index),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                            child: isTopThree
                                                ? Icon(
                                                    _getRankIcon(index),
                                                    color: Colors.white,
                                                    size: 20,
                                                  )
                                                : Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      result.solverName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isTopThree ? FontWeight.bold : FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.quiz,
                                              size: 14,
                                              color: _getScoreColor(percentage),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${result.score}/${result.totalQuestions}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _getScoreColor(percentage),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getScoreColor(percentage),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                result.gradeText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 12,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(result.completedAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _getScoreColor(percentage),
                                          ),
                                        ),
                                        if (result.timeTaken != null)
                                          Text(
                                            _formatTime(result.timeTaken!),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}