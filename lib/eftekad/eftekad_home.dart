import 'eftekad_history.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:async';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'add_eftekad.dart';

class EftekedHome extends StatefulWidget {
  const EftekedHome({Key? key}) : super(key: key);

  @override
  State<EftekedHome> createState() => _EftekedHomeState();
}

class _EftekedHomeState extends State<EftekedHome> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> eftekedRecords = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Don't load all students initially; wait for user to search
    setState(() {
      isLoading = false;
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final term = _searchController.text.trim();
      _loadStudentsData(search: term);
    });
  }

  Future<void> _loadStudentsData({String? search}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();

      // If no or very short search, return empty to avoid loading all
      if (search == null || search.length < 2) {
        setState(() {
          students = [];
          eftekedRecords = [];
          isLoading = false;
        });
        return;
      }

      // Load students for current class only and by name search
      final List<String> studentQueries = [];
      if (Constants.classId.isNotEmpty) {
        studentQueries.addAll([Query.equal('classId', Constants.classId)]);
      }
      // Use full-text search on name; ensure index exists in Appwrite
      studentQueries.add(Query.search('name', search));
      studentQueries.add(Query.limit(50));

      final studentsResponse = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: studentQueries,
      );

      // Map students first
      final mappedStudents = studentsResponse.documents.map((doc) {
        Map<String, dynamic> data;
        try {
          data = doc.data;
        } catch (_) {
          data = {};
        }
        return {
          'id': doc.$id,
          'name': data['name'] ?? '',
          'age': data['age'] ?? 0,
          'classId': data['classId'] ?? '',
          'qrCode': data['qrCode'] ?? '',
          'coins': data['coins'] ?? 0,
          'alhanCounter': data['alhanCounter'] ?? 0,
          'qodasCounter': data['qodasCounter'] ?? 0,
          'tasbehCounter': data['tasbehCounter'] ?? 0,
          'madrasAhadCounter': data['madrasAhadCounter'] ?? 0,
          'ejtimaCounter': data['ejtimaCounter'] ?? 0,
        };
      }).toList();

      // Prepare eftekad fetch only for these students
      List<Map<String, dynamic>> mappedEftekad = [];
      final studentIds = mappedStudents.map((s) => s['id'] as String).toList();
      if (studentIds.isNotEmpty) {
        final eftekedResponse = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.eftekedCollectionId,
          queries: [
            Query.equal('studentId', studentIds),
            Query.limit(1000),
          ],
        );

        mappedEftekad = eftekedResponse.documents.map((doc) {
          Map<String, dynamic> data;
          try {
            data = doc.data;
          } catch (_) {
            data = {};
          }
          return {
            'id': doc.$id,
            'studentId': data['studentId'] ?? '',
            'visitType': data['visitType'] ?? '',
            'reason': data['reason'] ?? '',
            'notes': data['notes'] ?? '',
            'visitDate': data['visitDate'] ?? '',
            'followUpRequired': data['followUpRequired'] ?? false,
          };
        }).toList();
      }

      setState(() {
        students = mappedStudents;
        eftekedRecords = mappedEftekad;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  Map<String, dynamic>? _getLastEfteked(String studentId) {
    final studentEftekad = eftekedRecords
        .where((record) => record['studentId'] == studentId)
        .toList();
    
    if (studentEftekad.isEmpty) return null;
    
    // Sort by date and get the most recent
    studentEftekad.sort((a, b) => b['visitDate'].compareTo(a['visitDate']));
    return studentEftekad.first;
  }

  Color _getAttendanceColor(Map<String, dynamic> student) {
    int totalAttendance = (student['alhanCounter'] ?? 0) +
                         (student['qodasCounter'] ?? 0) +
                         (student['tasbehCounter'] ?? 0) +
                         (student['madrasAhadCounter'] ?? 0) +
                         (student['ejtimaCounter'] ?? 0);

    if (totalAttendance == 0) return Colors.red.shade100;
    if (totalAttendance <= 2) return Colors.orange.shade100;
    if (totalAttendance <= 5) return Colors.yellow.shade100;
    return Colors.green.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الافتقاد',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStudentsData(search: _searchController.text.trim()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEftekad(students: students),
            ),
          );
          if (result == true) {
            _loadStudentsData();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ابحث باسم الطالب (2 حرف فأكثر)',
                labelStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isEmpty
                    ? const Icon(Icons.search)
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadStudentsData(search: '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: students.isEmpty
                  ? const Center(
                      child: Text(
                        'اكتب اسم الطالب للبحث ضمن الفصل الحالي',
                        style: TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final lastEftekad = _getLastEfteked(student['id']);

                        return Card(
                          elevation: 2,
                          color: _getAttendanceColor(student),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                (student['name'] ?? 'ط').toString().substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansArabic',
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'] ?? 'غير محدد',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                               
                                if (lastEftekad != null) ...[
                                  Text(
                                    'آخر افتقاد: ${lastEftekad['visitDate']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'NotoSansArabic',
                                    ),
                                  ),
                                  Text(
                                    'النوع: ${lastEftekad['visitType']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'NotoSansArabic',
                                    ),
                                  ),
                                ] else
                                  Text(
                                    'لم يتم افتقاده بعد',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[600],
                                      fontFamily: 'NotoSansArabic',
                                    ),
                                  ),
                              ],
                            ),
                            trailing: lastEftekad != null && lastEftekad['followUpRequired'] == true
                                ? const Icon(Icons.flag, color: Colors.red, size: 20)
                                : null,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EftekadHistoryPage(
                                    studentId: student['id'],
                                    studentName: student['name'] ?? '',
                                  ),
                                ),
                              );
                              // Optional: refresh list to reflect follow-up flags after return
                              _loadStudentsData(search: _searchController.text.trim());
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}