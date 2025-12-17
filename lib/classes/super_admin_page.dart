// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

import '../home_page.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  List<Map<String, dynamic>> classesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllClasses();
  }

  Future<void> _loadAllClasses() async {
    try {
      final databases = GetIt.I<Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.servicesCollectionId,
      );

      setState(() {
        classesData = documents.documents
          .map((doc) => {
            'id': doc.$id,
            'name': doc.data['name'] ?? '',
            'church': doc.data['church'] ?? '',
            'usersPassword': doc.data['usersPassword'] ?? '',
            'adminsPassword': doc.data['adminsPassword'] ?? '',
            'payment': doc.data['payment'] ?? '',
          })
          .where((classData) {
            // ✅ Filter out classes containing "حصة"
            final className = classData['name'] as String;
            return !className.contains('حصة');
          })
          .toList();
        isLoading = false;
      });
    } on AppwriteException catch (e) {
      print('Error loading classes: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في تحميل الفصول'),
        ),
      );
    }
  }

  Future<void> _selectClass(Map<String, dynamic> classData) async {
    try {
      // Save class data using secure storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('classId', classData['id']);
      await prefs.setString('className', classData['name']);
      await prefs.setString('superAdminSelectedClass', classData['id']); // Track selected class
      
      // Update Constants
      Constants.classId = classData['id'];
      Constants.className = classData['name'];
      Constants.isUser = false; // Super admin has full access

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          content: Text(
            'تم اختيار فصل: ${classData['name']}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );

      // Navigate to HomePage with selected class
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Homepage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في اختيار الفصل'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(
      MediaQuery.of(context).size.height,
      MediaQuery.of(context).size.width,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(
          'Super Admin - جميع الفصول',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back arrow
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
            : classesData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'لا توجد فصول متاحة',
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
                    onRefresh: _loadAllClasses,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: classesData.length,
                      itemBuilder: (context, index) {
                        final classItem = classesData[index];
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
                                    color: Colors.blueGrey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    Icons.class_,
                                    color: Colors.blueGrey,
                                    size: 30,
                                  ),
                                ),
                                title: Text(
                                  classItem['name'],
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
                                    Text(
                                      classItem['church'],
                                      style: TextStyle(
                                        fontSize: Constants.deviceWidth / 24,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'ID: ${classItem['id']}',
                                      style: TextStyle(
                                        fontSize: Constants.deviceWidth / 28,
                                        color: Colors.grey[500],
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
                                    'دخول',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: Constants.deviceWidth / 26,
                                    ),
                                  ),
                                ),
                                onTap: () => _selectClass(classItem),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllClasses,
        backgroundColor: Colors.blueGrey,
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'تحديث القائمة',
      ),
    );
  }
}