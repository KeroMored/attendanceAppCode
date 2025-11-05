import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:async';
import '../helper/constants.dart';
import '../helper/appwrite_services.dart';

class PrayNameInputDialog extends StatefulWidget {
  final String prayTitle;
  final String prayId;

  const PrayNameInputDialog({
    Key? key,
    required this.prayTitle,
    required this.prayId,
  }) : super(key: key);

  @override
  State<PrayNameInputDialog> createState() => _PrayNameInputDialogState();
}

class _PrayNameInputDialogState extends State<PrayNameInputDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isCheckingPray = false;
  Timer? _debouncer;

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  Future<bool> _hasAttendedPray(String studentId) async {
    setState(() {
      _isCheckingPray = true;
    });
    
    try {
      final databases = GetIt.I<Databases>();
      final response = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayResultsCollectionId,
        queries: [
          Query.equal('solverId', studentId),
          Query.equal('prayId', widget.prayId),
          Query.limit(1),
        ],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحقق من الحضور: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error checking pray attendance: $e');
      return false;
    }
  }

  Future<void> _searchStudents(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

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

      if (mounted) {
        setState(() {
          _searchResults = response.documents.map((doc) {
            final name = doc.data['name']?.toString() ?? '';
            final id = doc.$id;
            if (name.isEmpty || id.isEmpty) return null;
            return {
              'id': id,
              'name': name,
            };
          }).whereType<Map<String, String>>().toList();
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في البحث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
        //  Icon(Icons.mosque, color: Colors.blueGrey),
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
                'الصلاة: ${widget.prayTitle}',
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
                        trailing: _isCheckingPray
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                              ),
                            )
                          : null,
                        enabled: !_isCheckingPray,
                        onTap: () async {
                          if (_isCheckingPray) return;
                          
                          setState(() {
                            _isCheckingPray = true;
                          });
                          
                          final hasAttended = await _hasAttendedPray(student['id'].toString());
                          
                          setState(() {
                            _isCheckingPray = false;
                          });

                          if (hasAttended) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لقد سجلت حضورك لهذه الصلاة بالفعل',
                                    textAlign: TextAlign.right,
                                  ),
                                  backgroundColor: Colors.orange,
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
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}