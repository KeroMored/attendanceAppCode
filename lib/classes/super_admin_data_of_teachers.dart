// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'teacher_profile_page.dart';

class SuperAdminTeachersData extends StatefulWidget {
  const SuperAdminTeachersData({super.key});

  @override
  State<SuperAdminTeachersData> createState() => _SuperAdminTeachersDataState();
}

class _SuperAdminTeachersDataState extends State<SuperAdminTeachersData> {
  List<Map<String, dynamic>> teachersData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllTeachers();
  }

  Future<void> _loadAllTeachers() async {
    try {
      final databases = GetIt.I<Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.teachersCollectionId,
      );

      setState(() {
        teachersData = documents.documents.map((doc) => {
          'id': doc.$id,
          'name': doc.data['name'] ?? '',
          'address': doc.data['address'] ?? '',
          'phoneNumber1': doc.data['phoneNumber1'] ?? '',
          'phoneNumber2': doc.data['phoneNumber2'] ?? '',
          'students': doc.data['students'] ?? '',
          'teacherPassword': doc.data['teacherPassword'] ?? '',
          'role': doc.data['role'] ?? 'user',
        }).toList();
        isLoading = false;
      });
    } on AppwriteException catch (e) {
      print('Error loading teachers: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في تحميل بيانات الخدام'),
        ),
      );
    }
  }

  void _openTeacherProfile(Map<String, dynamic> teacherData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherProfilePage(teacherData: teacherData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(
          'بيانات الخدام',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(
                child: SpinKitWaveSpinner(
                  color: Colors.blueGrey,
                ),
              )
            : teachersData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'لا يوجد معلمين',
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAllTeachers,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: teachersData.length,
                      itemBuilder: (context, index) {
                        final teacher = teachersData[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey[50]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(20),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blue[900],
                                    size: 30,
                                  ),
                                ),
                                title: Text(
                                  teacher['name'],
                                  style: TextStyle(
                                    fontSize: Constants.deviceWidth / 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                  
                                    SizedBox(height: 4),
                                    Text(
                                      teacher['role'] ?? 'معلم',
                                      style: TextStyle(
                                        fontSize: Constants.deviceWidth / 28,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'عرض',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: Constants.deviceWidth / 26,
                                    ),
                                  ),
                                ),
                                onTap: () => _openTeacherProfile(teacher),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllTeachers,
        backgroundColor: Colors.blueGrey,
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'تحديث القائمة',
      ),
    );
  }
}