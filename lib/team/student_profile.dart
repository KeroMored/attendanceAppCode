import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class StudentProfile extends StatefulWidget {
  final String studentId;
  const StudentProfile({super.key, required this.studentId});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final databases = GetIt.I<appwrite.Databases>();
      final document = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        documentId: widget.studentId,
      );

      setState(() {
        studentData = document.data; // Store the student data
        isLoading = false; // Stop loading
      });
    } on appwrite.AppwriteException catch (e) {
      print(e);
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage(Constants.footballStadium),
            ),
          ),
        ),        Center(child: CircularProgressIndicator(color: Colors.white,)),
      ],
    )
        : studentData != null
        ? Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage(Constants.footballStadium),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'المدرب : ${studentData!['name']}', // Assuming 'name' is the field in the student document
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              // Add more fields if needed
            ],
          ),
        ),
      ],
    )
        : Center(child: Text('Student not found'));
  }
}