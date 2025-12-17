import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart' hide Permission;
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/quiz_result_model.dart';

class TotalResultAnalyticsPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const TotalResultAnalyticsPage({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  State<TotalResultAnalyticsPage> createState() => _TotalResultAnalyticsPageState();
}

class _TotalResultAnalyticsPageState extends State<TotalResultAnalyticsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> analytics = [];

  
  @override
  void initState() {
    super.initState();
    _generateAnalytics();
  }

  Future<void> _generateAnalytics() async {
    try {
      final databases = GetIt.I<Databases>();
      
      // Ensure the start date is at the beginning of the day and end date at the end
      final startDateTime = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, 0, 0, 0);
      final endDateTime = DateTime(widget.endDate.year, widget.endDate.month, widget.endDate.day, 23, 59, 59);
      
      // Get all quiz results in the date range
      final results = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizResultsCollectionId,
        queries: [
          Query.greaterThanEqual('completedAt', startDateTime.toIso8601String()),
          Query.lessThanEqual('completedAt', endDateTime.toIso8601String()),
          Query.equal('classId', Constants.classId),
          Query.limit(500),
        ],
      );

      // Group results by solver ID
      Map<String, int> totalScores = {};
      Map<String, String> solverNames = {};
      Map<String, int> quizCounts = {};
      Map<String, List<int>> allScores = {};
      
      for (var doc in results.documents) {
        try {
          final result = QuizResultModel.fromMap(doc.data..addAll({'\$id': doc.$id}));
          totalScores[result.solverId] = (totalScores[result.solverId] ?? 0) + result.score;
          solverNames[result.solverId] = result.solverName;
          quizCounts[result.solverId] = (quizCounts[result.solverId] ?? 0) + 1;
          
          // Store all scores for calculating highest and lowest
          if (!allScores.containsKey(result.solverId)) {
            allScores[result.solverId] = [];
          }
          allScores[result.solverId]!.add(result.score);
        } catch (e) {
          print('Error processing result document: $e');
          continue;
        }
      }

      // Convert to list and sort by score
      analytics = totalScores.entries.map((entry) {
        final scores = allScores[entry.key] ?? [];
        scores.sort();
        return {
          'id': entry.key,
          'name': solverNames[entry.key] ?? 'Unknown',
          'totalScore': entry.value,
          'quizCount': quizCounts[entry.key] ?? 0,
          'average': (entry.value / (quizCounts[entry.key] ?? 1)).toStringAsFixed(1),
          'highestScore': scores.isEmpty ? 0 : scores.last,
          'lowestScore': scores.isEmpty ? 0 : scores.first,
        };
      }).toList()
        ..sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
    
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نتائج الطلاب',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'من ${DateFormat('dd/MM/yyyy').format(widget.startDate)} إلى ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
              ),
            )
          : analytics.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد نتائج في هذه الفترة',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: analytics.length,
                  itemBuilder: (context, index) {
                    final student = analytics[index];
                    final rank = index + 1;
                    final totalScore = student['totalScore'] as int;
                    final quizCount = student['quizCount'] as int;
                    final highestScore = student['highestScore'] as int;
                    final lowestScore = student['lowestScore'] as int;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: rank <= 3 ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              rank == 1 ? Colors.amber.shade100 :
                              rank == 2 ? Colors.blueGrey.shade100 :
                              Colors.brown.shade100,
                              Colors.white,
                            ],
                          ) : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.blueGrey,
                                    child: Text(
                                      '$rank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'عدد المسابقات: $quizCount',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '( $totalScore )',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                   
                                    _buildStatItem(
                                      'أعلى نتيجة',
                                      '$highestScore',
                                      Icons.arrow_upward,
                                    ),
                                    _buildStatItem(
                                      'أقل نتيجة',
                                      '$lowestScore',
                                      Icons.arrow_downward,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}