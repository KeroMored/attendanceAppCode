import 'package:awesome_dialog/awesome_dialog.dart';
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
  int totalGoals = 0; // This will store the student's totalCounter as goals
  Map<String, dynamic>? playerOfTheMonth; // Future: will hold the player of the month data
  String studentName = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentData(); // Fetch the current student's data
  }

  void _showPlayerOfTheMonthInfo() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'لاعب الشهر',
      desc: 'سيتم تحديد لاعب الشهر بناءً على أعلى عدد الأهداف (أيام الحضور)',
      btnOkText: 'حسناً',
      btnOkOnPress: () {
        // Dialog automatically closes
      },
    ).show();
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

      // For now, we'll just prepare the UI structure
      playerOfTheMonth = null; // Will be implemented later
      //
      //
      //
      //studentImagesBucketId  انا عملت الباكت ده فى اابرايت تقدر تضيف فيه الصور وتجيبها منه 
      //
      //
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

  Widget _getDefaultPlayerIcon([double? width, double? height]) {
    final iconWidth = width ?? 100;
    final iconHeight = height ?? 100;
    final iconSize = iconWidth * 0.5;
    
    return Container(
      width: iconWidth,
      height: iconHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[300]!, Colors.grey[400]!],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[500]!, width: 2),
      ),
      child: Icon(
        Icons.person,
        size: iconSize,
        color: Colors.grey[600],
      ),
    );
  }

  // Add refresh functionality
  Future<void> _refreshData() async {
    await _fetchStudentData();
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('تم تحديث البيانات بنجاح'),
    //       backgroundColor: Colors.green,
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
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
                  // Goals display - moved to left
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03, 
                        vertical: screenHeight * 0.01
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        border: Border.all(color: Colors.green, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
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
                              fontSize: isSmallScreen ? 10 : (isMediumScreen ? 11 : 12),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                color: Colors.green[700],
                                size: isSmallScreen ? 20 : (isMediumScreen ? 24 : 26),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Flexible(
                                child: Text(
                                  "$totalGoals أهداف",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: isSmallScreen ? 14 : (isMediumScreen ? 16 : 18),
                                    fontWeight: FontWeight.bold,
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
                  // Refresh button - moved to right
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(screenWidth * 0.035),
                    child: InkWell(
                      onTap: _refreshData,
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(screenWidth * 0.035),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.blue,
                          size: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      isLoading ? CircularProgressIndicator(color: Colors.white,) : _buildPlayerOfTheMonthDisplay(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerOfTheMonthDisplay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Title
          Text(
            'لاعب الشهر',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : (isMediumScreen ? 24 : 28),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          // Player of the Month Display
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            shadowColor: Colors.yellow.withValues(alpha: 0.3),
            child: Container(
              width: isSmallScreen ? 160 : (isMediumScreen ? 200 : 230),
              constraints: BoxConstraints(
                minHeight: isSmallScreen ? 180 : (isMediumScreen ? 220 : 250),
                maxHeight: isSmallScreen ? 220 : (isMediumScreen ? 260 : 300),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.yellow[50]!, Colors.amber[100]!],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(color: Colors.amber, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Crown icon
                  Icon(
                    Icons.emoji_events,
                    size: isSmallScreen ? 40 : (isMediumScreen ? 50 : 60),
                    color: Colors.amber[700],
                  ),
                  SizedBox(height: 12),
                  
                  // Player image placeholder (TODO: implement logic to show actual player)
                  Container(
                    width: isSmallScreen ? 80 : (isMediumScreen ? 100 : 120),
                    height: isSmallScreen ? 80 : (isMediumScreen ? 100 : 120),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: playerOfTheMonth != null 
                        ? ClipOval(
                            child: Image.network(
                              playerOfTheMonth!['image'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _getDefaultPlayerIcon();
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.grey[300]!, Colors.grey[400]!],
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: isSmallScreen ? 50 : (isMediumScreen ? 60 : 70),
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                  SizedBox(height: 12),
                  
                  // Player name (TODO: show actual player name)
                  Text(
                    playerOfTheMonth?['name'] ?? 'سيتم تحديده قريباً',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  
                  // Goals count
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Text(
                      playerOfTheMonth != null 
                          ? '${playerOfTheMonth!['goals'] ?? 0} هدف'
                          : 'قريباً...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : (isMediumScreen ? 14 : 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Info button
          ElevatedButton.icon(
            onPressed: _showPlayerOfTheMonthInfo,
            icon: Icon(Icons.info_outline, color: Colors.white),
            label: Text(
              'معلومات',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
