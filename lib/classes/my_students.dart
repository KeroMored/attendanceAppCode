// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/appwrite_services.dart';
import 'search_assign_students.dart';
import '../student/student_detailsage.dart';

class MyStudentsPage extends StatefulWidget {
  const MyStudentsPage({Key? key}) : super(key: key);

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState();
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  bool isLoading = true;
  String teacherId = '';
  String teacherName = '';
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _removeStudentFromMyList(String studentId) async {
    if (teacherId.isEmpty) return;
    try {
      final db = GetIt.I<Databases>();
      // Get current teacher doc
      final teacherDoc = await db.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: teacherId,
      );

      // Normalize current relation values to Set<String>
      final Set<String> idSet = {};
      try {
        final raw = teacherDoc.data['students'];
        if (raw is List) {
          for (final e in raw) {
            if (e is String && e.isNotEmpty) idSet.add(e);
            if (e is Map && e['\$id'] != null) idSet.add(e['\$id'].toString());
          }
        } else if (raw is String && raw.isNotEmpty) {
          idSet.add(raw);
        }
      } catch (_) {}

      // Remove the selected id
      idSet.remove(studentId);

      // Update teacher doc
      await db.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: teacherId,
        data: {'students': idSet.toList()},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إزالة الطالب من قائمتك')),
      );
      // Refresh list
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الإزالة: $e')),
      );
    }
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    teacherId = prefs.getString('teacherId') ?? '';
    teacherName = prefs.getString('teacherName') ?? '';

    if (teacherId.isEmpty) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد معرف للخادم')));
      }
      return;
    }

    try {
      final db = GetIt.I<Databases>();
      final teacherDoc = await db.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: teacherId,
      );

      // Read relation ids (support both list of strings and list of maps with $id)
      final List<dynamic> rel = [];
      try {
        final data = teacherDoc.data;
        final raw = data['students'];
        if (raw is List) rel.addAll(raw);
        if (raw is String && raw.isNotEmpty) rel.add(raw);
      } catch (_) {}

      // Normalize to list of string IDs
      final Set<String> idSet = {};
      for (final e in rel) {
        if (e is String && e.isNotEmpty) {
          idSet.add(e);
        } else if (e is Map && e['\$id'] != null) {
          idSet.add(e['\$id'].toString());
        }
      }

      if (idSet.isEmpty) {
        setState(() {
          students = [];
          isLoading = false;
        });
        return;
      }

      final ids = idSet.toList();
      final studentsRes = await db.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          Query.equal('\$id', ids),
          Query.limit(100),
        ],
      );

      final list = studentsRes.documents.map((d) {
        Map<String, dynamic> m;
        try { m = d.data; } catch (_) { m = {}; }
        return {
          'id': d.$id,
          'name': m['name'] ?? '',
          'age': m['age'] ?? 0,
        };
      }).toList();

      setState(() {
        students = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تحميل طلابي: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: const Text('مسؤوليتي', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchAssignStudentsPage(),
            ),
          );
          if (added == true) _load();
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('لا يوجد مخدومين معينين'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final name = (s['name'] ?? '') as String;
                    final id = (s['id'] ?? '') as String;
                    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentDetailsPage(studentId: id),
                            ),
                          );
                        },
                        onLongPress: () async {
                          // Confirm removal
                          final sure = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('إزالة الطالب'),
                              content: Text('هل تريد إزالة "$name" من قائمة طلابك؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('إزالة'),
                                ),
                              ],
                            ),
                          );
                          if (sure == true) {
                            await _removeStudentFromMyList(id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blueGrey.withOpacity(0.15),
                                child: Text(
                                  initial,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                               
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueGrey),
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
