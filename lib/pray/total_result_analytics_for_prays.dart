import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/pray_result_model.dart';

class TotalResultAnalyticsForPrays extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const TotalResultAnalyticsForPrays({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  State<TotalResultAnalyticsForPrays> createState() => _TotalResultAnalyticsForPraysState();
}

class _TotalResultAnalyticsForPraysState extends State<TotalResultAnalyticsForPrays> {
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
      
      // Get all pray results in the date range
      final results = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayResultsCollectionId,
        queries: [
          Query.greaterThanEqual('completedAt', startDateTime.toIso8601String()),
          Query.lessThanEqual('completedAt', endDateTime.toIso8601String()),
          Query.equal('classId', Constants.classId),
          Query.limit(500),
        ],
      );

      // Group results by solver ID
      Map<String, int> prayerCounts = {};
      Map<String, String> solverNames = {};
      Map<String, Map<String, bool>> prayerDates = {}; // Track unique dates per student
      Map<String, List<DateTime>> allPrayDates = {};
      
      for (var doc in results.documents) {
        try {
          final result = PrayResultModel.fromMap(doc.data..addAll({'\$id': doc.$id}));
          prayerCounts[result.solverId] = (prayerCounts[result.solverId] ?? 0) + 1;
          solverNames[result.solverId] = result.solverName;
          
          // Track unique dates for consistency calculation
          if (!prayerDates.containsKey(result.solverId)) {
            prayerDates[result.solverId] = {};
          }
          final dateStr = DateFormat('yyyy-MM-dd').format(result.completedAt);
          prayerDates[result.solverId]![dateStr] = true;

          // Store all pray dates for patterns
          if (!allPrayDates.containsKey(result.solverId)) {
            allPrayDates[result.solverId] = [];
          }
          allPrayDates[result.solverId]!.add(result.completedAt);
        } catch (e) {
          print('Error processing result document: $e');
          continue;
        }
      }

      // Calculate total days in range
      final totalDays = endDateTime.difference(startDateTime).inDays + 1;

      // Convert to list and sort by prayer count
      analytics = prayerCounts.entries.map((entry) {
        final uniqueDays = prayerDates[entry.key]?.length ?? 0;
        final consistency = (uniqueDays / totalDays * 100).toStringAsFixed(1);
        final dates = allPrayDates[entry.key] ?? [];
        dates.sort();
        
        return {
          'id': entry.key,
          'name': solverNames[entry.key] ?? 'Unknown',
          'totalPrayers': entry.value,
          'uniqueDays': uniqueDays,
          'consistency': consistency,
          'longestStreak': _calculateLongestStreak(dates),
          'currentStreak': _calculateCurrentStreak(dates),
        };
      }).toList()
        ..sort((a, b) => (b['totalPrayers'] as int).compareTo(a['totalPrayers'] as int));

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

  int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    int currentStreak = 1;
    int maxStreak = 1;
    
    for (int i = 1; i < dates.length; i++) {
      final difference = dates[i].difference(dates[i - 1]).inDays;
      if (difference == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else if (difference > 1) {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }

  int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    final today = DateTime.now();
    final lastPrayDate = dates.last;
    
    if (today.difference(lastPrayDate).inDays > 1) return 0;
    
    int streak = 1;
    for (int i = dates.length - 2; i >= 0; i--) {
      final difference = dates[i + 1].difference(dates[i]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
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
              'إحصائيات الصلاة',
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

        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back,color: Colors.white,)),
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
                    final totalPrayers = student['totalPrayers'] as int;

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
                                          'عدد الصلوات: $totalPrayers',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              
                                ],
                              ),
                              const SizedBox(height: 16),
                              ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }



}