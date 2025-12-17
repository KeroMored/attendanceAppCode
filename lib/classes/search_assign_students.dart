import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class SearchAssignStudentsPage extends StatefulWidget {
  const SearchAssignStudentsPage({Key? key}) : super(key: key);

  @override
  State<SearchAssignStudentsPage> createState() => _SearchAssignStudentsPageState();
}

class _SearchAssignStudentsPageState extends State<SearchAssignStudentsPage> {
  final TextEditingController _search = TextEditingController();
  bool isLoading = false;
  List<Map<String, dynamic>> results = [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final term = _search.text.trim();
    if (term.length < 2) {
      setState(() => results = []);
      return;
    }

    setState(() => isLoading = true);
    try {
      final db = GetIt.I<Databases>();
      final res = await db.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          Query.equal('classId', Constants.classId),
          if (term.isNotEmpty) Query.search('name', term),
          Query.limit(30),
        ],
      );

      final list = res.documents.map((d) {
        Map<String, dynamic> m;
        try { m = d.data; } catch (_) { m = {}; }
        return {
          'id': d.$id,
          'name': m['name'] ?? '',
          'age': m['age'] ?? 0,
          'classId': m['classId'] ?? '',
        };
      }).toList();

      setState(() => results = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل البحث: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _assignToTeacher(String studentId) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getString('teacherId') ?? '';
      if (teacherId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد معرف للخادم')));
        return;
      }
      final db = GetIt.I<Databases>();
      // Fetch current teacher to get existing relation values
      final teacherDoc = await db.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: teacherId,
      );
      List<dynamic> rel = [];
      try {
        final data = teacherDoc.data;
        final raw = data['students'];
        if (raw is List) rel = List<dynamic>.from(raw);
        if (raw is String && raw.isNotEmpty) rel = [raw];
      } catch (_) {}

      // Normalize to a set of string IDs to avoid duplicates when items are maps
      final Set<String> idSet = {};
      for (final e in rel) {
        if (e is String && e.isNotEmpty) idSet.add(e);
        if (e is Map && e['\$id'] != null) idSet.add(e['\$id'].toString());
      }
      idSet.add(studentId);

      await db.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: teacherId,
        data: {
          'students': idSet.toList(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المخدوم إلى قائمة مخدومينك')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التعيين: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: const Text('اضافة طالب إلى خادم', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(onPressed: _runSearch, icon: const Icon(Icons.search))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'ابحث باسم الطالب',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _runSearch(),
            ),
            const SizedBox(height: 12),
            if (isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = results[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(s['name'] ?? ''),
                    subtitle: Text('العمر: ${s['age']}'),
                    trailing: ElevatedButton(
                      onPressed: isLoading ? null : () => _assignToTeacher(s['id'] as String),
                      child: const Text('إضافة'),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
