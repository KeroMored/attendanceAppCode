import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import '../helper/constants.dart';
import '../helper/appwrite_services.dart';
import '../models/pray_model.dart';
import '../models/pray_result_model.dart';
import 'add_pray.dart';
import 'name_input_dialog.dart';

class PrayHomePage extends StatefulWidget {
  const PrayHomePage({Key? key}) : super(key: key);

  @override
  State<PrayHomePage> createState() => _PrayHomePageState();
}

class _PrayHomePageState extends State<PrayHomePage> {
  List<PrayModel> _prayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  Future<void> _loadPrayers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final databases = GetIt.I<Databases>();
      final response = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayCollectionId,
        queries: [
          Query.equal('classId', Constants.classId),
          Query.orderDesc('date'),
        ],
      );

      setState(() {
        _prayers = response.documents
            .map((doc) {
              try {
                final data = doc.data;
                // Add required fields if missing
                if (!data.containsKey('date')) {
                  data['date'] = DateTime.now().toIso8601String();
                }
                if (!data.containsKey('name')) {
                  data['name'] = '';
                }
                if (!data.containsKey('classId')) {
                  data['classId'] = Constants.classId;
                }
                if (!data.containsKey('createdBy')) {
                  data['createdBy'] = Constants.classId;
                }
                return PrayModel.fromMap(data);
              } catch (e) {
                debugPrint('Error parsing prayer: $e');
                return null;
              }
            })
            .whereType<PrayModel>()
            .where((pray) => !Constants.isUser || pray.isVisible)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الصلوات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAttendance(PrayModel pray) async {
    final participant = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrayNameInputDialog(
        prayTitle: pray.name,
        prayId: pray.id!,
      ),
    );

    if (participant == null) return;

    try {
      final databases = GetIt.I<Databases>();
      final result = PrayResultModel(
        solverId: participant['id']!,
        solverName: participant['name']!,
        prayId: pray.id!,
        classId: Constants.classId,
        completedAt: DateTime.now(),
      );

      await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayResultsCollectionId,
        documentId: ID.unique(),
        data: result.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل حضورك للصلاة',
              textAlign: TextAlign.right,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الحضور: $e'),
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
        title: const Text('الصلاة'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _prayers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد صلوات حالياً',
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                    itemCount: _prayers.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final pray = _prayers[index];
                      String dateString;
                      try {
                        dateString = pray.date.toString().split(' ')[0];
                      } catch (e) {
                        dateString = 'التاريخ غير متوفر';
                      }
                      return Card(
                        color: pray.isVisible ? Colors.white : Colors.grey[300],
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            trailing: !Constants.isUser
                              ? SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: PopupMenuButton<String>(

                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.more_vert, color: Colors.blueGrey,size: 24,),
                                  onSelected: (value) async {
                                    if (value == 'visibility') {
                                      try {
                                        final databases = GetIt.I<Databases>();
                                        await databases.updateDocument(
                                          databaseId: AppwriteServices.databaseId,
                                          collectionId: AppwriteServices.prayCollectionId,
                                          documentId: pray.id!,
                                          data: {
                                            'isVisible': !pray.isVisible,
                                          },
                                        );
                                        if (mounted) {
                                          _loadPrayers();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                pray.isVisible 
                                                  ? 'تم إخفاء الصلاة من الطلاب'
                                                  : 'تم إظهار الصلاة للطلاب',
                                              ),
                                              backgroundColor: Colors.green
                                              
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem<String>(
                                      value: 'visibility',
                                      child: Row(
                                        children: [
                                          Icon(
                                            pray.isVisible 
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                            color: Colors.blueGrey,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            pray.isVisible 
                                              ? 'إخفاء من الطلاب'
                                              : 'إظهار للطلاب',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  ),
                              )
                              : null,
                            title: Text(
                              pray.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'التاريخ: $dateString',
                            ),
                        
                            onTap: () => _markAttendance(pray),
                        ),
                      );
                    },
                  ),
      floatingActionButton: !Constants.isUser
          ? FloatingActionButton(
              onPressed: ()  {
                 Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddPrayPage()));
              },
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}