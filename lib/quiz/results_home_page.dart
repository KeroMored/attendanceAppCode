import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/quiz_model.dart';
import 'quiz_results_page.dart';
import 'total_result_analytics_page.dart';

class ResultsHomePage extends StatefulWidget {
  const ResultsHomePage({Key? key}) : super(key: key);

  @override
  State<ResultsHomePage> createState() => _ResultsHomePageState();
}

class _ResultsHomePageState extends State<ResultsHomePage> {
  List<QuizModel> quizzes = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  final int _limit = 10;
  String? _lastDocumentId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData) {
        _loadMoreQuizzes();
      }
    }
  }

  Future<void> _loadQuizzes({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          isLoading = true;
          quizzes.clear();
          _lastDocumentId = null;
          hasMoreData = true;
        });
      } else {
        setState(() {
          isLoading = true;
        });
      }

      final databases = GetIt.I<Databases>();
      List<String> queries = [
        Query.equal('classId', Constants.classId),
        Query.orderDesc('\$createdAt'),
        Query.limit(_limit),
      ];

      if (_lastDocumentId != null) {
        queries.add(Query.cursorAfter(_lastDocumentId!));
      }

      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizzesCollectionId,
        queries: queries,
      );

      final newQuizzes = documents.documents
          .map((doc) {
            try {
              Map<String, dynamic> data = Map<String, dynamic>.from(doc.data);
              data['\$id'] = doc.$id;
              return QuizModel.fromMap(data);
            } catch (e) {
              print('Error parsing quiz document: $e');
              return null;
            }
          })
          .where((quiz) => quiz != null)
          .cast<QuizModel>()
          .toList();

      setState(() {
        if (isRefresh) {
          quizzes = newQuizzes;
        } else {
          quizzes.addAll(newQuizzes);
        }
        
        if (newQuizzes.length < _limit) {
          hasMoreData = false;
        }
        
        if (newQuizzes.isNotEmpty) {
          _lastDocumentId = newQuizzes.last.id;
        }
        
        isLoading = false;
      });
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreQuizzes() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      List<String> queries = [
        Query.equal('classId', Constants.classId),
        Query.orderDesc('\$createdAt'),
        Query.limit(_limit),
      ];

      if (_lastDocumentId != null) {
        queries.add(Query.cursorAfter(_lastDocumentId!));
      }

      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizzesCollectionId,
        queries: queries,
      );

      final newQuizzes = documents.documents
          .map((doc) {
            try {
              Map<String, dynamic> data = Map<String, dynamic>.from(doc.data);
              data['\$id'] = doc.$id;
              return QuizModel.fromMap(data);
            } catch (e) {
              print('Error parsing quiz document: $e');
              return null;
            }
          })
          .where((quiz) => quiz != null)
          .cast<QuizModel>()
          .toList();

      setState(() {
        quizzes.addAll(newQuizzes);
        
        if (newQuizzes.length < _limit) {
          hasMoreData = false;
        }
        
        if (newQuizzes.isNotEmpty) {
          _lastDocumentId = newQuizzes.last.id;
        }
        
        isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more quizzes: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: Constants.isUser ? null : FloatingActionButton.extended(
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
                builder: (context) => TotalResultAnalyticsPage(
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
      ),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'نتائج المسابقات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
            : quizzes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد مسابقات',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadQuizzes(isRefresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: quizzes.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the end
                        if (index == quizzes.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                              ),
                            ),
                          );
                        }
                        
                        final quiz = quizzes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            color: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.analytics,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                quiz.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 16,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'عرض النتائج',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                            
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blueGrey,
                                size: 20,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizResultsPage(quiz: quiz),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}