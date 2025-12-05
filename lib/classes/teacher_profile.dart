// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../models/teacher_model.dart';
import 'add_teacher.dart';
import 'my_students.dart';
import '../team/view_players_of_the_month.dart';

class TeacherProfile extends StatefulWidget {
  const TeacherProfile({super.key});

  @override
  State<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  String teacherName = '';
  String teacherRole = '';
  String teacherId = '';
  String className = '';
  String teacherAddress = '';
  String teacherPhone1 = '';
  String teacherPhone2 = '';
  bool isLoading = true;
  TeacherModel? teacherModel;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get basic data from SharedPreferences
      teacherName = prefs.getString('teacherName') ?? 'غير محدد';
      teacherRole = prefs.getString('teacherRole') ?? 'user';
      teacherId = prefs.getString('teacherId') ?? 'غير محدد';
      className = prefs.getString('className') ?? 'غير محدد';
      
      // Set default values for personal data
      teacherAddress = 'غير محدد';
      teacherPhone1 = 'غير محدد';
      teacherPhone2 = 'غير محدد';
      
      // Fetch complete teacher data from Appwrite if teacherId is available
      if (teacherId.isNotEmpty && teacherId != 'غير محدد') {
        await _fetchTeacherFromAppwrite(teacherId);
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading teacher data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTeacherFromAppwrite(String teacherId) async {
    try {
      final databases = GetIt.I<Databases>();
      final document = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
        documentId: teacherId,
      );
      
      teacherModel = TeacherModel.fromMap(document.data);
      teacherAddress = teacherModel?.address ?? 'غير محدد';
      teacherPhone1 = teacherModel?.phoneNumber1 ?? 'غير محدد';
      teacherPhone2 = teacherModel?.phoneNumber2 ?? 'غير محدد';
      
    } catch (e) {
      print('Error fetching teacher from Appwrite: $e');
      // Use default values if fetch fails
      teacherAddress = 'غير محدد';
      teacherPhone1 = 'غير محدد';
      teacherPhone2 = 'غير محدد';
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'مشرف';
      case 'superAdmin':
        return 'ادمن';
      case 'user':
        return 'خادم';
      default:
        return 'خادم';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'superAdmin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'superAdmin':
        return Icons.supervisor_account;
      case 'user':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بيانات الخادم',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueGrey,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            // Profile Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getRoleColor(teacherRole).withOpacity(0.1),
                                border: Border.all(
                                  color: _getRoleColor(teacherRole),
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                _getRoleIcon(teacherRole),
                                size: 50,
                                color: _getRoleColor(teacherRole),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Teacher Name
                            Text(
                              teacherName,
                              style: TextStyle(
                                fontSize: Constants.deviceWidth / 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(teacherRole),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getRoleDisplayName(teacherRole),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Information Cards
                    _buildInfoCard(
                      'الفصل',
                      className,
                      Icons.class_,
                      Colors.green,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildInfoCard(
                      'العنوان',
                      teacherAddress.isNotEmpty ? teacherAddress : 'غير محدد',
                      Icons.location_on,
                      Colors.red,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildInfoCard(
                      'رقم الهاتف الأول',
                      teacherPhone1.isNotEmpty ? teacherPhone1 : 'غير محدد',
                      Icons.phone,
                      Colors.blue,
                    ),
                         
                    const SizedBox(height: 12),

                    _buildInfoCard(
                      'رقم الهاتف الثاني',
                      teacherPhone2.isNotEmpty ? teacherPhone2 : 'غير محدد',
                      Icons.phone_android,
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),

                    // My Students (visible to all roles)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyStudentsPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.group, size: 20),
                                label: const Text(
                                  'مسؤوليتي',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            (Constants.classId=="681f72c87215111b670e")?
                            // Player of the Month Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: () {
                                  if (teacherId.isNotEmpty && className.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewPlayersOfTheMonthPage(
                                          classId: teacherId,
                                          className: className,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('لا يمكن الوصول لبيانات الفصل'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.emoji_events, size: 20),
                                label: const Text(
                                  'اضافة صورة لاعب الشهر',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                      :Container()
                          ],
                        ),
                      ),
                    ),
               

                    const SizedBox(height: 12),
                    
                    // Quick Actions Card
                    (teacherRole == 'admin')
                        ? Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AddTeacher(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.person_add, size: 20),
                                      label: const Text(
                                        'اضافة خادم',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: Constants.deviceWidth / 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: Constants.deviceWidth / 22,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      ),
    );
  }


}