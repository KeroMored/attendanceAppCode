import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'add_player_of_the_month.dart';

class ManagePlayersOfTheMonthPage extends StatefulWidget {
  final String classId;
  final String className;

  const ManagePlayersOfTheMonthPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ManagePlayersOfTheMonthPage> createState() => _ManagePlayersOfTheMonthPageState();
}

class _ManagePlayersOfTheMonthPageState extends State<ManagePlayersOfTheMonthPage> {
  List<Map<String, dynamic>> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      final response = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.playersOfStudentCollectionId,
        queries: [
          appwrite.Query.equal('classId', widget.classId),
          appwrite.Query.equal('isPlayerOfTheMonth', true),
          appwrite.Query.orderDesc('dateAdded'),
        ],
      );

      setState(() {
        players = response.documents.map((doc) => {
          'id': doc.$id,
          'playerName': doc.data['name'] ?? doc.data['playerName'] ?? '', // Support both field names
          'imageUrl': doc.data['imageUrl'] ?? '',
          'fileId': doc.data['fileId'] ?? '',
          'dateAdded': doc.data['dateAdded'] ?? '',
          'month': doc.data['month'] ?? 0,
          'year': doc.data['year'] ?? 0,
          'originalFileName': doc.data['originalFileName'] ?? '',
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deletePlayer(String playerId, String fileId) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تأكيد الحذف',
            style: TextStyle(fontFamily: "NotoSansArabic"),
            textAlign: TextAlign.right,
          ),
          content: Text(
            'هل أنت متأكد من حذف هذا اللاعب؟',
            style: TextStyle(fontFamily: "NotoSansArabic"),
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              child: Text('إلغاء', style: TextStyle(fontFamily: "NotoSansArabic")),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('حذف', style: TextStyle(fontFamily: "NotoSansArabic", color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final databases = GetIt.I<appwrite.Databases>();
      final storage = GetIt.I<appwrite.Storage>();

      // Delete image from storage
      if (fileId.isNotEmpty) {
        try {
          await storage.deleteFile(
            bucketId: AppwriteServices.studentImagesBucketId,
            fileId: fileId,
          );
        } catch (e) {
          print('Error deleting file: $e');
        }
      }

      // Delete document from database
      await databases.deleteDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.playersOfStudentCollectionId,
        documentId: playerId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف اللاعب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload players
      _loadPlayers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف اللاعب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return month > 0 && month < months.length ? months[month] : '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'إدارة لاعبي الشهر',
          style: TextStyle(
            fontFamily: "NotoSansArabic",
            fontSize: screenWidth / 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffbcf1ff),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPlayerOfTheMonthPage(
                    classId: widget.classId,
                    className: widget.className,
                  ),
                ),
              ).then((_) => _loadPlayers()); // Reload after adding
            },
            tooltip: 'إضافة لاعب جديد',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage(Constants.footballStadium),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Class info
              Container(
                margin: EdgeInsets.all(screenWidth * 0.04),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  'فصل: ${widget.className}',
                  style: TextStyle(
                    fontSize: screenWidth / 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontFamily: "NotoSansArabic",
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Players list
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : players.isEmpty
                        ? Center(
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.05),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: screenWidth * 0.2,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'لا يوجد لاعبي شهر حتى الآن',
                                    style: TextStyle(
                                      fontSize: screenWidth / 18,
                                      color: Colors.grey[600],
                                      fontFamily: "NotoSansArabic",
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddPlayerOfTheMonthPage(
                                            classId: widget.classId,
                                            className: widget.className,
                                          ),
                                        ),
                                      ).then((_) => _loadPlayers());
                                    },
                                    child: Text(
                                      'إضافة لاعب الشهر الأول',
                                      style: TextStyle(fontFamily: "NotoSansArabic"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(15),
                                  leading: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: player['imageUrl'].isNotEmpty
                                          ? Image.network(
                                              player['imageUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 2,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                                            ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          player['playerName'],
                                          style: TextStyle(
                                            fontFamily: "NotoSansArabic",
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth / 20,
                                            color: Colors.blueGrey[800],
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(height: 4),
                                      Text(
                                        '${_getMonthName(player['month'])} ${player['year']}',
                                        style: TextStyle(
                                          fontFamily: "NotoSansArabic",
                                          color: Colors.grey[600],
                                          fontSize: screenWidth / 26,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                      if (player['originalFileName'].isNotEmpty) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          'اسم الملف: ${player['originalFileName']}',
                                          style: TextStyle(
                                            fontFamily: "NotoSansArabic",
                                            color: Colors.grey[500],
                                            fontSize: screenWidth / 30,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deletePlayer(
                                        player['id'],
                                        player['fileId'],
                                      ),
                                      tooltip: 'حذف',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlayerOfTheMonthPage(
                classId: widget.classId,
                className: widget.className,
              ),
            ),
          ).then((_) => _loadPlayers());
        },
        backgroundColor: Colors.green[600],
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'إضافة لاعب الشهر',
      ),
    );
  }
}