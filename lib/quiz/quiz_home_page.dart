// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/quiz_model.dart';
import 'add_quiz.dart';
import 'quiz_page.dart';
import 'name_input_dialog.dart';

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  List<QuizModel> quizzes = [];
  List<QuizModel> visibleQuizzes = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  final int _limit = 10;
  String? _lastDocumentId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print('=== Quiz Home Page Initialized ===');
    print('User type: ${Constants.isUser ? "Student" : "Admin"}');
    print('Class ID: ${Constants.classId}');
    print('Class Name: ${Constants.className}');
    
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

  void _updateVisibleQuizzes() {
    if (Constants.isUser) {
      visibleQuizzes = quizzes.where((quiz) => quiz.isVisible).toList();
    } else {
      visibleQuizzes = List.from(quizzes); // Admin sees all quizzes
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

      print('Loading quizzes for classId: ${Constants.classId}');
      print('Using collection: ${AppwriteServices.quizzesCollectionId}');
      
      if (Constants.classId.isEmpty) {
        print('ERROR: classId is empty!');
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لم يتم تحديد الفصل بشكل صحيح'),
            backgroundColor: Colors.red,
          ),
        );
        return;
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

      print('Found ${documents.documents.length} quiz documents');

      final newQuizzes = documents.documents
          .map((doc) {
            try {
              Map<String, dynamic> data = Map<String, dynamic>.from(doc.data);
              data['\$id'] = doc.$id;
              return QuizModel.fromMap(data);
            } catch (e) {
              print('Error parsing quiz document: $e');
              print('Document data: ${doc.data}');
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
        _updateVisibleQuizzes(); // Make sure to update visible quizzes
      });

      _updateVisibleQuizzes(); // Update visible quizzes after loading

      print('=== QUIZ LOADING RESULTS ===');
      print('Total quizzes loaded: ${quizzes.length}');
      print('Visible quizzes for current user: ${visibleQuizzes.length}');
      print('User is: ${Constants.isUser ? "Student" : "Admin"}');
      print('Has more data: $hasMoreData');
      
      if (quizzes.isNotEmpty) {
        print('First quiz: ${quizzes.first.name}, visible: ${quizzes.first.isVisible}');
        for (int i = 0; i < quizzes.length; i++) {
          print('Quiz $i: ${quizzes[i].name} - Visible: ${quizzes[i].isVisible}');
        }
      } else {
        print('WARNING: No quizzes found in database!');
      }
      
      if (visibleQuizzes.isEmpty && quizzes.isNotEmpty) {
        print('WARNING: All quizzes are hidden from this user!');
      }
      print('========================');
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        String errorMessage = 'خطأ في تحميل المسابقات';
        if (e.toString().contains('Collection with the requested ID could not be found')) {
          errorMessage = 'لم يتم إنشاء جدول المسابقات في قاعدة البيانات بعد';
        } else if (e.toString().contains('Index with the requested ID could not be found')) {
          errorMessage = 'يجب إنشاء فهرس classId في جدول المسابقات';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
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

      print('Loaded ${documents.documents.length} more quiz documents');

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

      _updateVisibleQuizzes();
      print('Total quizzes after loading more: ${quizzes.length}');
    } catch (e) {
      print('Error loading more quizzes: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _toggleQuizVisibility(QuizModel quiz) async {
    if (Constants.isUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ليس لديك صلاحية لتعديل ظهور المسابقات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final databases = GetIt.I<Databases>();
      await databases.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizzesCollectionId,
        documentId: quiz.id!,
        data: {
          'isVisible': !quiz.isVisible,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        quizzes.clear();
        _lastDocumentId = null;
        hasMoreData = true;
      });
      await _loadQuizzes(isRefresh: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quiz.isVisible ? 'تم إخفاء المسابقة' : 'تم إظهار المسابقة'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث المسابقة: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    if (Constants.isUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ليس لديك صلاحية لحذف المسابقات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف مسابقة "\${quiz.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final databases = GetIt.I<Databases>();
        await databases.deleteDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.quizzesCollectionId,
          documentId: quiz.id!,
        );

        await _loadQuizzes(); // Refresh the list
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المسابقة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف المسابقة: \$e'),
            backgroundColor: Colors.red,
          ),
        );
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
          'المسابقات',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
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
            : visibleQuizzes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz,
                          size: Constants.deviceWidth / 4,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Constants.isUser ? 'لا توجد مسابقات متاحة حالياً' : 'لا توجد مسابقات',
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 20,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الفصل: ${Constants.className}',
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 28,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (!Constants.isUser) ...[
                          const SizedBox(height: 16),
                          Text(
                            'اضغط على زر + لإضافة مسابقة جديدة',
                            style: TextStyle(
                              fontSize: Constants.deviceWidth / 25,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadQuizzes(isRefresh: true),
                    child: Builder(
                      builder: (context) {
                        final displayQuizzes = visibleQuizzes;
                        if (displayQuizzes.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد مسابقات للعرض',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: displayQuizzes.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            try {
                              // Show loading indicator at the end
                              if (index == displayQuizzes.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                                    ),
                                  ),
                                );
                              }
                              
                              if (index >= displayQuizzes.length) {
                                return const SizedBox.shrink();
                              }
                              
                              final quiz = displayQuizzes[index];

                              return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                                            color: Colors.white,

                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    backgroundColor: quiz.isVisible ? Colors.green : Colors.grey,
                                    child: const Icon(
                                      Icons.quiz,
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
                                  subtitle:
                                   (!Constants.isUser)?
                                   Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          quiz.isVisible ? Icons.visibility : Icons.visibility_off,
                                          size: 14,
                                          color: quiz.isVisible ? Colors.green : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                     
                                        Text(
                                          quiz.isVisible ? 'مرئية للطلاب' : 'مخفية',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: quiz.isVisible ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                       
                                      ],
                                    ),
                                  ):null,
                                  trailing: Constants.isUser
                                      ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20)
                                      : IconButton(
                                          icon: const Icon(Icons.more_vert,color: Colors.black, size: 20),
                                          onPressed: () {
                                            showMenu(
                                              color: Colors.white,
                                              context: context,
                                              position: RelativeRect.fromLTRB(100, 100, 0, 0),
                                              items: [
                                                PopupMenuItem<String>(
                                                  value: 'toggle_visibility',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        quiz.isVisible ? Icons.visibility_off : Icons.visibility,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(quiz.isVisible ? 'إخفاء' : 'إظهار'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('حذف', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ).then((value) {
                                              if (value != null) {
                                                switch (value) {
                                                  case 'toggle_visibility':
                                                    _toggleQuizVisibility(quiz);
                                                    break;
                                                  case 'delete':
                                                    _deleteQuiz(quiz);
                                                    break;
                                                }
                                              }
                                            });
                                          },
                                        ),
                                  onTap: () async {
                              if (Constants.isUser && !quiz.isVisible) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('هذه المسابقة غير متاحة حالياً'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              // Ask for participant name before starting quiz
                              final participant = await showDialog<Map<String, String>>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => NameInputDialog(quizName: quiz.name, quizId: quiz.id!),
                              );
                              
                              if (participant != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizPage(
                                      quiz: quiz,
                                      participant: participant,
                                    ),
                                  ),
                                );
                              }
                                  },
                                ),
                              ),
                            );
                            } catch (e) {
                              print('Error building quiz item at index $index: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        );
                  },
                ),
              ),
      ),
      floatingActionButton: Constants.isUser
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddQuiz()),
                );
                if (result == true) {
                  setState(() {
                    quizzes.clear();
                    _lastDocumentId = null;
                    hasMoreData = true;
                  });
                  await _loadQuizzes(isRefresh: true);
                }
              },
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}