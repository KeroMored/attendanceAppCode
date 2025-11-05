import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:async';
import '../helper/constants.dart';
import '../helper/appwrite_services.dart';

class NameInputDialog extends StatefulWidget {
  final String quizName;
  final String quizId;

  const NameInputDialog({
    Key? key, 
    required this.quizName,
    required this.quizId,
  }) : super(key: key);

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isCheckingQuiz = false;
  Timer? _debouncer;

  Future<bool> _hasCompletedQuiz(String studentId) async {
    try {
      final databases = GetIt.I<Databases>();
      final response = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.quizResultsCollectionId,
        queries: [
          Query.equal('solverId', studentId),
          Query.equal('quizId', widget.quizId),
          Query.limit(1),
        ],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      print('Error checking quiz completion: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  Future<void> _searchStudents(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final databases = GetIt.I<Databases>();
      final response = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          Query.search('name', query),
          Query.equal('classId', Constants.classId),
          Query.limit(10),
        ],
      );

      setState(() {
        _searchResults = response.documents
            .map((doc) => {
                  'id': doc.$id,
                  'name': doc.data['name'],
                })
            .toList();
      });
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debouncer?.isActive ?? false) _debouncer!.cancel();
    _debouncer = Timer(const Duration(milliseconds: 500), () {
      _searchStudents(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          //Icon(Icons.search, color: Colors.blueGrey),
          SizedBox(width: 8),
          Text(
            'ابحث عن اسمك',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                'المسابقة: ${widget.quizName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              textAlign: TextAlign.right,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'اكتب اسمك للبحث...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.blueGrey),
                ),
              )
            else if (_searchResults.isNotEmpty)
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      return ListTile(
                        title: Text(
                          student['name'],
                          textAlign: TextAlign.right,
                        ),
                        trailing: _isCheckingQuiz
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                              ),
                            )
                          : null,
                        enabled: !_isCheckingQuiz,
                        onTap: () async {
                          setState(() {
                            _isCheckingQuiz = true;
                          });
                          
                          final hasCompleted = await _hasCompletedQuiz(student['id'].toString());
                          
                          setState(() {
                            _isCheckingQuiz = false;
                          });

                          if (hasCompleted) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لقد أكملت هذه المسابقة بالفعل',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            return;
                          }
                          
                          // Return student ID and name as Map<String, String>
                          Navigator.of(context).pop({
                            'id': student['id'].toString(),
                            'name': student['name'].toString(),
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'إلغاء',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}