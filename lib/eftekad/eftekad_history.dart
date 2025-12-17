import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart';

import '../helper/appwrite_services.dart';
import 'add_eftekad.dart';

class EftekadHistoryPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const EftekadHistoryPage({Key? key, required this.studentId, required this.studentName}) : super(key: key);

  @override
  State<EftekadHistoryPage> createState() => _EftekadHistoryPageState();
}

class _EftekadHistoryPageState extends State<EftekadHistoryPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
    });
    try {
      final databases = GetIt.I<Databases>();
      final res = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.eftekedCollectionId,
        queries: [
          Query.equal('studentId', [widget.studentId]),
          Query.limit(1000),
        ],
      );

      final mapped = res.documents.map((doc) {
        Map<String, dynamic> data;
        try {
          data = doc.data;
        } catch (_) {
          data = {};
        }
        return {
          'id': doc.$id,
          'visitType': data['visitType'] ?? '',
          'reason': data['reason'] ?? '',
          'notes': data['notes'] ?? '',
          'visitDate': data['visitDate'] ?? '',
          'followUpRequired': data['followUpRequired'] ?? false,
          'createdAt': data['createdAt'] ?? '',
        };
      }).toList();

      // Sort by visitDate desc (string yyyy-MM-dd) then createdAt desc
      mapped.sort((a, b) {
        final ad = a['visitDate'] as String? ?? '';
        final bd = b['visitDate'] as String? ?? '';
        final cmp = bd.compareTo(ad);
        if (cmp != 0) return cmp;
        final ac = a['createdAt'] as String? ?? '';
        final bc = b['createdAt'] as String? ?? '';
        return bc.compareTo(ac);
      });

      setState(() {
        records = mapped;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل السجل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل الافتقاد - ${widget.studentName}',
          style: const TextStyle(
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
            onPressed: _loadHistory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEftekad(
                students: [
                  {'id': widget.studentId, 'name': widget.studentName}
                ],
                selectedStudentId: widget.studentId,
              ),
            ),
          );
          if (result == true) {
            _loadHistory();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? const Center(
                  child: Text(
                    'لا يوجد سجلات افتقاد لهذا الطالب',
                    style: TextStyle(fontFamily: 'NotoSansArabic'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = records[index];
                    final reason = (r['reason'] ?? '').toString().trim();
                    final notes = (r['notes'] ?? '').toString().trim();
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () async {
                          final edited = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEftekad(
                                students: [
                                  {'id': widget.studentId, 'name': widget.studentName}
                                ],
                                selectedStudentId: widget.studentId,
                                initialRecord: {
                                  'id': r['id'],
                                  'studentId': widget.studentId,
                                  'visitType': r['visitType'],
                                  'reason': r['reason'],
                                  'notes': r['notes'],
                                  'visitDate': r['visitDate'],
                                  'followUpRequired': r['followUpRequired'],
                                },
                              ),
                            ),
                          );
                          if (edited == true) {
                            _loadHistory();
                          }
                        },
                        child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Icon(
                                r['followUpRequired'] == true ? Icons.flag : Icons.check_circle,
                                color: r['followUpRequired'] == true ? Colors.red : Colors.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${r['visitDate']} - ${r['visitType']}',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansArabic',
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.fade,
                                  ),
                                  if (reason.isNotEmpty)
                                    Text(
                                      'السبب: $reason',
                                      style: const TextStyle(fontFamily: 'NotoSansArabic'),
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                    ),
                                  if (notes.isNotEmpty)
                                    Text(
                                      'ملاحظات: $notes',
                                      style: const TextStyle(fontFamily: 'NotoSansArabic'),
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
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
}