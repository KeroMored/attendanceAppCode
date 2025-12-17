import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class PlayerOfTheMonth extends StatefulWidget {
  final String studentId;

  const PlayerOfTheMonth({super.key, required this.studentId});

  @override
  State<PlayerOfTheMonth> createState() => _PlayerOfTheMonthState();
}

class _PlayerOfTheMonthState extends State<PlayerOfTheMonth> {
  bool isLoading = true;
  int totalGoals = 0;
  String studentName = '';
  List<Map<String, dynamic>> playersOfTheMonth = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
    _loadPlayersOfTheMonth();
  }

  Future<void> _loadPlayersOfTheMonth() async {
    try {
      final storage = GetIt.I<appwrite.Storage>();
      
      // List all files in the storage bucket
      final response = await storage.listFiles(
        bucketId: AppwriteServices.studentImagesBucketId,
        queries: [

          appwrite.Query.orderDesc('\$createdAt'),
          appwrite.Query.limit(50), // Limit to last 50 files
        ],
      );

      // Filter files that match the pattern for player of the month
      final playerFiles = response.files.where((file) {
        return file.name.contains('_player_of_month_');
      }).toList();

      setState(() {
        playersOfTheMonth = playerFiles.map((file) {
          // Extract student name and class from filename
          final parts = file.name.split('_');
          String studentName = 'غير معروف';
          String className = 'غير معروف';
          if (parts.length >= 3) {
            // Format: ClassName_StudentName_player_of_month_timestamp.extension
            className = parts[0];
            studentName = parts[1];
          }
          
          return {
            'id': file.$id,
            'studentName': studentName,
            'className': className,
            'fileName': file.name,
            'imageUrl': 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteServices.studentImagesBucketId}/files/${file.$id}/view?project=${AppwriteServices.projectId}',
            'uploadDate': file.$createdAt,
          };
        }).toList().cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error loading players of the month: $e');
    }
  }


  Future<void> _fetchStudentData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });
    
    final databases = GetIt.I<appwrite.Databases>();

    try {
      final studentDocument = await databases.getDocument(
        documentId: widget.studentId,
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
      );

      debugPrint("Student document data: ${studentDocument.data}");

      // Get the student's totalCounter as their goals
      totalGoals = studentDocument.data["totalCounter"] as int? ?? 0;
      studentName = studentDocument.data["name"] as String? ?? "طالب";
      
      debugPrint("Student name: $studentName");
      debugPrint("Student goals (totalCounter): $totalGoals");
    } on appwrite.AppwriteException catch (e) {
      debugPrint("AppwriteException in _fetchStudentData: ${e.message}");
      debugPrint("Error code: ${e.code}");
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل بيانات الطالب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("General error in _fetchStudentData: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال بقاعدة البيانات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  // Add refresh functionality
  Future<void> _refreshData() async {
    await _fetchStudentData();
    await _loadPlayersOfTheMonth();
  }  String _formatDate(String dateString) {
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage(Constants.footballStadium),
            ),
          ),
        ),
        Column(
          children: [
            // Enhanced goals display with refresh button and student name
            Container(
              margin: EdgeInsets.only(
                top: screenHeight * 0.025, 
                right: screenWidth * 0.04, 
                left: screenWidth * 0.04
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Goals display
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03, 
                        vertical: screenHeight * 0.01
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        border: Border.all(color: Colors.green, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: "NotoSansArabic",
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                color: Colors.green[700],
                                size: 24,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Flexible(
                                child: Text(
                                  "$totalGoals أهداف",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "NotoSansArabic",
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  // Refresh button and info button
                  Column(
                    children: [
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(screenWidth * 0.035),
                        child: InkWell(
                          onTap: _refreshData,
                          borderRadius: BorderRadius.circular(screenWidth * 0.035),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(screenWidth * 0.035),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
               ],
                  ),
                ],
              ),
            ),
            
            // Title
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                '#لاعبي_الشهر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth / 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: "NotoSansArabic",
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            
            // Players display
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : playersOfTheMonth.isEmpty
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
                                  textAlign: TextAlign.center,
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
                            childAspectRatio: 0.75,
                          ),
                          itemCount: playersOfTheMonth.length,
                          itemBuilder: (context, index) {
                            final player = playersOfTheMonth[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.amber, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Trophy icon
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                  ),
                                  
                                  // Student image
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber, width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          player['imageUrl'],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.grey[600],
                                              ),
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
                                  
                                  // Student info
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Text(
                                          player['studentName'],
                                          style: TextStyle(
                                            fontFamily: "NotoSansArabic",
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth / 24,
                                            color: Colors.blueGrey[800],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
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
      ],
    );
  }
}
