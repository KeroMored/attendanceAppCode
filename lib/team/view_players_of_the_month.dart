import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'add_player_of_the_month.dart';

class ViewPlayersOfTheMonthPage extends StatefulWidget {
  final String classId;
  final String className;

  const ViewPlayersOfTheMonthPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ViewPlayersOfTheMonthPage> createState() => _ViewPlayersOfTheMonthPageState();
}

class _ViewPlayersOfTheMonthPageState extends State<ViewPlayersOfTheMonthPage> {
  List<Map<String, dynamic>> playerImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerImages();
  }

  Future<void> _loadPlayerImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final storage = GetIt.I<appwrite.Storage>();
      
      // List all files in the storage bucket
      final response = await storage.listFiles(
        bucketId: AppwriteServices.studentImagesBucketId,
        queries: [
          appwrite.Query.orderDesc('\$createdAt'),
          appwrite.Query.limit(100), // Limit to last 100 files
        ],
      );

      // Filter files that match the pattern for player of the month and this class
      final classPlayerFiles = response.files.where((file) {
        return file.name.contains('_player_of_month_') && 
               file.name.startsWith('${widget.className}_');
      }).toList();

      setState(() {
        playerImages = classPlayerFiles.map((file) {
          // Extract student name from filename
          final parts = file.name.split('_');
          String studentName = 'غير معروف';
          if (parts.length >= 3) {
            // Format: ClassName_StudentName_player_of_month_timestamp.extension
            studentName = parts[1];
          }
          
          return {
            'id': file.$id,
            'studentName': studentName,
            'fileName': file.name,
            'imageUrl': 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteServices.studentImagesBucketId}/files/${file.$id}/view?project=${AppwriteServices.projectId}',
            'uploadDate': file.$createdAt,
          };
        }).toList().cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الصور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deletePlayerImage(String fileId, String studentName) async {
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
            'هل أنت متأكد من حذف صورة $studentName؟',
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
      final storage = GetIt.I<appwrite.Storage>();

      // Delete image from storage
      await storage.deleteFile(
        bucketId: AppwriteServices.studentImagesBucketId,
        fileId: fileId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف صورة $studentName بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload images
      _loadPlayerImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'تاريخ غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'لاعبي الشهر',
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
              ).then((_) => _loadPlayerImages()); // Reload after adding
            },
            tooltip: 'إضافة طالب جديد',
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
              
              // Players images grid
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : playerImages.isEmpty
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
                                    'لا يوجد طلاب لاعبي شهر حتى الآن',
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
                                      ).then((_) => _loadPlayerImages());
                                    },
                                    child: Text(
                                      'إضافة أول طالب لاعب الشهر',
                                      style: TextStyle(fontFamily: "NotoSansArabic"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.7, // Make cards taller for better image display
                            ),
                            itemCount: playerImages.length,
                            itemBuilder: (context, index) {
                              final playerImage = playerImages[index];
                              return Container(
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
                                child: Column(
                                  children: [
                                    // Trophy icon at top
                                   IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red, size: 18),
                                            onPressed: () => _deletePlayerImage(
                                              playerImage['id'],
                                              playerImage['studentName'],
                                            ),
                                            tooltip: 'حذف',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                       
                                    
                                    // Student image
                                    Expanded(
                                      flex: 3, // Give more space to the image
                                      child: Container(
                                        
                                        margin: EdgeInsets.all(8),
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
                                          borderRadius: BorderRadius.circular(9),
                                          child: Image.network(
                                            playerImage['imageUrl'],
                                            width: double.infinity,
                                            height: double.infinity,
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
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Student name and actions
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            playerImage['studentName'],
                                            style: TextStyle(
                                              fontFamily: "NotoSansArabic",
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth / 22,
                                              color: Colors.blueGrey[800],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines:2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                       
                                        ],
                                      ),
                                    ),
                             
                                  ],
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
          ).then((_) => _loadPlayerImages());
        },
        backgroundColor: Colors.green[600],
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'إضافة طالب لاعب الشهر',
      ),
    );
  }
}