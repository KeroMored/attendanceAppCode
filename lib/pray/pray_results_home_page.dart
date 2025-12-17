import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import 'total_result_analytics_for_prays.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/pray_model.dart';
import '../models/pray_result_model.dart';
import 'pray_detail_page.dart';

class PrayResultsHomePage extends StatefulWidget {
  const PrayResultsHomePage({Key? key}) : super(key: key);

  @override
  _PrayResultsHomePageState createState() => _PrayResultsHomePageState();
}

class _PrayResultsHomePageState extends State<PrayResultsHomePage> {
  bool _isLoading = true;
  List<PrayModel> _prays = [];
  List<PrayResultModel> _results = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final databases = GetIt.I<Databases>();
      final prayResults = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayResultsCollectionId,
        queries: [
          Query.equal('classId', Constants.classId),
          Query.orderDesc('completedAt'),
        ],
      );

      final prays = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayCollectionId,
        queries: [
          Query.equal('classId', Constants.classId),
          Query.orderDesc('date'),
        ],
      );

      if (mounted) {
        setState(() {
          _results = prayResults.documents.map((doc) {
            try {
              return PrayResultModel.fromMap(doc.data);
            } catch (e) {
              debugPrint('Error parsing pray result: $e');
              return null;
            }
          }).whereType<PrayResultModel>().toList();

          _prays = prays.documents.map((doc) {
            try {
              return PrayModel.fromMap(doc.data);
            } catch (e) {
              debugPrint('Error parsing pray: $e');
              return null;
            }
          }).whereType<PrayModel>().toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: \${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('نتائج الصلاة'),
      ),
      floatingActionButton: !Constants.isUser 
          ? FloatingActionButton.extended(
              onPressed: () async {
                final now = DateTime.now();
                final firstDayOfMonth = DateTime(now.year, now.month, 1);
                final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
                
                DateTimeRange? dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: DateTimeRange(
                    start: firstDayOfMonth,
                    end: lastDayOfMonth,
                  ),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.blueGrey,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.blueGrey,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (dateRange != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TotalResultAnalyticsForPrays(
                        startDate: dateRange.start,
                        endDate: dateRange.end,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.analytics, size: 20, color: Colors.white),
              label: const Text('تحليل النتائج', style: TextStyle(fontSize: 16, color: Colors.white)),
              backgroundColor: Colors.blueGrey,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildResultsList(),
    );
  }

  Widget _buildResultsList() {
    // Group results by quiz
    Map<String, List<PrayResultModel>> resultsByPray = {};
    for (var result in _results) {
      if (!resultsByPray.containsKey(result.prayId)) {
        resultsByPray[result.prayId] = [];
      }
      resultsByPray[result.prayId]!.add(result);
    }

    if (_prays.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج حالياً',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 20,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _prays.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final pray = _prays[index];
        if (pray.id == null) return const SizedBox.shrink();
        
        final results = resultsByPray[pray.id] ?? [];
        String dateString = pray.date.toString().split(' ')[0];

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrayDetailPage(pray: pray),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pray.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'التاريخ: $dateString',
                              style: const TextStyle(
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            Text(
                              'عدد المصلين: ${results.length}',
                              style: const TextStyle(
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Visibility controls moved to pray_home_page.dart
                    ],
                  ),
                ),
              ),
              if (!pray.isVisible && !Constants.isUser)
                Container(
                  color: Colors.grey.shade100,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Text(
                    'مخفية عن الطلاب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    )
     ;     
        
      
    
  }
}