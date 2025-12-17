import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../models/pray_model.dart';
import '../models/pray_result_model.dart';

class PrayDetailPage extends StatefulWidget {
  final PrayModel pray;
  
  const PrayDetailPage({
    Key? key,
    required this.pray,
  }) : super(key: key);

  @override
  State<PrayDetailPage> createState() => _PrayDetailPageState();
}

class _PrayDetailPageState extends State<PrayDetailPage> {
  bool _isLoading = true;
  List<PrayResultModel> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final databases = GetIt.I<Databases>();
      final response = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayResultsCollectionId,
        queries: [
          Query.equal('prayId', widget.pray.id!),
          Query.orderDesc('completedAt'),
        ],
      );

      if (mounted) {
        setState(() {
          _results = response.documents
              .map((doc) {
                try {
                  return PrayResultModel.fromMap(doc.data);
                } catch (e) {
                  debugPrint('Error parsing pray result: $e');
                  return null;
                }
              })
              .whereType<PrayResultModel>()
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateString = widget.pray.date.toString().split(' ')[0];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pray.name),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Prayer Info Card
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التاريخ: $dateString',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عدد المصلين: ${_results.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'لا يوجد مصلين حتى الآن',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        padding: const EdgeInsets.all(8.0),
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return Card(
                            child: ListTile(
                              title: Text(result.solverName),
                              subtitle: Text(
                                'وقت التسجيل: ${result.completedAt.toString().split('.')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}