import 'package:flutter/material.dart';
import '../helper/styles.dart';
import 'meeting_details.dart';
import 'meeting_details_offline.dart';
import 'display_lesson.dart';

class OnlineOrOffline extends StatelessWidget {
  final String meetingId;

  const OnlineOrOffline({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: Text(
          "اختيار وضع التسجيل", 
          style: Styles.textStyleSmall.copyWith(color: Colors.white),
        ),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back, 
            color: Colors.white,
            size: screenWidth * 0.06,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey[50]!,
              Colors.blueGrey[100]!,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Icon and Text
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.network_check,
                    size: screenWidth * 0.15,
                    color: Colors.blueGrey,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  'اختر وضع تسجيل الحضور',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'يمكنك التسجيل أونلاين أو أوفلاين حسب حالة الاتصال',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.blueGrey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.06),
                
                // Online Button
                _buildModeButton(
                  context: context,
                  title: 'التسجيل أونلاين',
                  subtitle: 'يتطلب اتصال بالإنترنت',
                  icon: Icons.wifi,
                  color: Colors.green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingDetails(meetingId: meetingId),
                      ),
                    );
                  },
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Offline Button
                _buildModeButton(
                  context: context,
                  title: 'التسجيل أوفلاين',
                  subtitle: 'يعمل بدون اتصال بالإنترنت',
                  icon: Icons.wifi_off,
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingDetailsOffline(meetingId: meetingId),
                      ),
                    );
                  },
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                
                SizedBox(height: screenHeight * 0.04),

                // Add Lesson Button
                _buildModeButton(
                  context: context,
                  title: 'اضافة الدرس',
                  subtitle: 'عرض وإضافة محتوى الدرس',
                  icon: Icons.menu_book,
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DisplayLesson(meetingId: meetingId),
                      ),
                    );
                  },
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                
                // Info Card
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: screenWidth * 0.05,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          'في الوضع الأوفلاين، سيتم حفظ البيانات محلياً ومزامنتها عند توفر الاتصال',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double screenWidth,
    required double screenHeight,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 5,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            side: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(
                icon,
                size: screenWidth * 0.08,
                color: color,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: screenWidth * 0.05,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
