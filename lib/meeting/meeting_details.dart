import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';
import '../helper/styles.dart';
import 'attendars_for_meeting.dart';



class MeetingDetails extends StatefulWidget {
  final String meetingId;

  const MeetingDetails({super.key, required this.meetingId});

  @override
  _MeetingDetailsState createState() => _MeetingDetailsState();
}

class _MeetingDetailsState extends State<MeetingDetails> {
  Map<String, dynamic>? meetingData;
  bool isLoading = true;
  List<dynamic> students = [];
  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = ConnectivityService(); // Initialize the connectivity service

    //   _getMeetingDetails();
  }
  bool _canScan = true; // To control scanning
  bool _loadForScan = false; // To control scanning
  Timer? _scanCooldownTimer;
  String? studentName;
  String studentRef = '';
  Future<void> submitForm(String studentRef) async {
    setState(() {
      _canScan = false;
      _loadForScan = true;
      print("loooo$_loadForScan");
    });
    try {
      // Fetch the existing document
      final databases = GetIt.I<Databases>();
      Document document = await getMeetingData(databases);

      // Update the students list
      students = document.data['students'] ?? [];

      // Check if studentRef is already in the students list
      bool studentExists = students.any((student) => student['\$id'] == studentRef);
      Document studentDocument = await getStudentData(databases, studentRef);

      if (!studentExists && studentDocument.data["classId"]["\$id"].toString()== Constants.classId ) {
        students.add(studentRef);



        // Map<String, dynamic> data = {
        //   'students': students, // Ensure this is a list of references to student documents
        // };

        // Update the document
    //    await updateMeetingData(databases, document, data);
        await updateMeetingData(databases, document);

        //***************************************************
        //***************************************************
        //***************************************************
        //***************************************************

         // ignore: unused_local_variable
         int updatedValueForCoins = 0;
         int totalValue = 0;
        // String fieldToUpdate;

      //*
        totalValue = studentDocument.data["totalCounter"] + 1;
 await updateStudentData(databases, studentRef,totalValue);
      //   (Constants.classId=="681f72c87215111b670e")?

      //   {
      //     // if (document.data['Type'] == "حصة الألحان")
      //     // {
      //     //   updatedValue = studentDocument.data["alhanCounter"] + 1;
      //     //   fieldToUpdate = "alhanCounter";
      //     // }
      //     // else if (document.data['Type'] == "قداس") {
      //     //   updatedValue = studentDocument.data["qudasCounter"] + 1;
      //     //   fieldToUpdate = "qudasCounter";
      //     // }
      //     // else if (document.data['Type'] == "تسبحة") {
      //     //   updatedValue = studentDocument.data["tasbhaCounter"] + 1;
      //     //   fieldToUpdate = "tasbhaCounter";
      //     // }

      //     // else {
      //     //   return;
      //     // }
      //     // await updateStudentData(databases, studentRef, fieldToUpdate, updatedValue, totalValue);


      //     if (document.data['Type'] == "حصة الألحان")
      //       {
      //         updatedValueForCoins=     studentDocument.data["totalCoins"] + 5
      //       }
      //     else
      //       if (document.data['Type'] == "قداس") {
      //         updatedValueForCoins=    studentDocument.data["totalCoins"] + 10
      //       }
      //       else
      //         if (document.data['Type'] == "تسبحة") {
      //           updatedValueForCoins=  studentDocument.data["totalCoins"] + 8
      //         },
      //   await updateStudentDataForClassELtashkela(databases, studentRef,  updatedValueForCoins, totalValue)

      // }
      // :
      //       {
      //         await updateStudentData(databases, studentRef,totalValue)

      //       };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
              content: Center(child: Text(studentDocument.data['name'],style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,))),
        );
      }
      else if(studentExists && studentDocument.data["classId"]["\$id"].toString()== Constants.classId ){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
              content: Center(child: Text('تم تحضير المخدوم من قبل',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,))),
        );
      }




      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: Duration(seconds: 1),
              backgroundColor: Colors.black,
              content: Center(child: Text('المخدوم ينتمى لفصل آخر',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,))),
        );
      }
    } on AppwriteException catch (e) {
      print(e);
      if(e.code== 404)
          //"AppwriteException: document_not_found, Document with the requested ID could not be found. (404)")
        {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.black,
                duration: Duration(seconds: 2),

                content: Center(child: Text("غير مسجل فى هذا الفصل",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,))),
          );
        }
      else
        {

          ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
backgroundColor: Colors.black,
            duration: Duration(seconds:2),

            content: Center(child: Text("لم يتم الحفظ",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,))),
      );
        }
    } catch (e) {
      print(e);
    }
    setState(() {
      _loadForScan = false;
          });
      _scanCooldownTimer?.cancel(); // Cancel any existing timer
    _scanCooldownTimer = Timer(Duration(seconds:2), () {
      setState(() {

        _canScan = true; // Re-enable scanning
      });
    });

  }

 // Future<void> updateStudentData(Databases databases, String studentRef, String fieldToUpdate, int updatedValue,int total) async {
  Future<void> updateStudentData(Databases databases, String studentRef,int total) async {
    await databases.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        documentId: studentRef,

        data: {
          //fieldToUpdate: updatedValue,
          'totalCounter':total,
        }
    );
  }
  //int coins
  Future<void> updateStudentDataForClassELtashkela(Databases databases, String studentRef,int total) async {
    await databases.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        documentId: studentRef,

        data: {
          //fieldToUpdate: updatedValue,
          'totalCounter':total,
        //  'totalCoins':coins,
        }
    );
  }

  Future<Document> getStudentData(Databases databases, String studentRef) async {
    final studentDocument = await databases.getDocument(
      databaseId: AppwriteServices.databaseId,
      collectionId: AppwriteServices.studentsCollectionId,
      documentId: studentRef,
      // queries: [
      //   Query.equal('classId', Constants.classId),
      // ],
    );
    return studentDocument;
  }
  Future<void> updateMeetingData(Databases databases, Document document) async {
  // Future<void> updateMeetingData(Databases databases, Document document, Map<String, dynamic> data) async {
    await databases.updateDocument(
      databaseId: AppwriteServices.databaseId,
      collectionId: AppwriteServices.meetingsCollectionId,
      documentId: document.$id,
      data: {
        'students': students, // Ensure this is a list of references to student documents
      },
      permissions: [
        Permission.read(Role.any()), // Ensure users have read permission
        Permission.write(Role.any()), // Ensure users have write permission
      ],
    );
  }
  Future<Document> getMeetingData(Databases databases) async {
    final document = await databases.getDocument(
      databaseId: AppwriteServices.databaseId,
      collectionId: AppwriteServices.meetingsCollectionId,
      documentId: widget.meetingId,


    );
    return document;
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel(); // Clean up the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return ModalProgressHUD(
      progressIndicator:  Center(
        child: SpinKitWaveSpinner(
          color: Colors.white,
          waveColor: Colors.white,
          trackColor: Colors.blueGrey,
        ),
      ),
      inAsyncCall: _loadForScan,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white,),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate("name", "الاسم لتسجيل الحضور", submitForm,connectivityService),
                );
              },
            ),
          ],
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          title: Text("تسجيل الحضور", style: Styles.textStyleSmall.copyWith(color: Colors.white),),
          leading: MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back, color: Colors.white,size: Constants.arrowBackSize,),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                height: Constants.deviceWidth/1.5,
                width: Constants.deviceWidth/1.5,
                child: MobileScanner(
                  onDetect: (barcodes) {
                    if ( _loadForScan == false && _canScan == true && barcodes.barcodes.isNotEmpty) {
                      final barcode = barcodes.barcodes.first.rawValue;
                      if (barcode != null) {
                        print(barcode);
                          connectivityService.checkConnectivity(context, submitForm(barcode));

                      }
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: MaterialButton(
                  elevation: 3,
                  shape: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(width: 1, color: Colors.blue)),
                  minWidth: Constants.deviceWidth/1.5,
                  height: Constants.deviceHeight/12,
                  color: Colors.blueGrey,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AttendarsForMeeting(meetingId: widget.meetingId),));
                  },
                  child: Text("الحضور",
                    style: Styles.textStyleSmall.copyWith(color: Colors.white),),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<void> {
  final String searchBy;
  final String searchByInArabic;
  final Function(String) submitForm;
  late ConnectivityService connectivityService;

  CustomSearchDelegate(this.searchBy, this.searchByInArabic, this.submitForm,this.connectivityService);

  @override
  String get searchFieldLabel => 'بحث ب$searchByInArabic ...';
  @override
  TextStyle get searchFieldStyle => TextStyle(fontSize: Constants.deviceWidth/25, overflow: TextOverflow.ellipsis);
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        toolbarHeight: MediaQuery.of(context).size.height/12,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.black),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(
      color: Colors.white70,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _searchStudents(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No results found', style: TextStyle(color: Colors.black)));
          } else {
            return _buildStudentList(snapshot.data!);
          }
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Scaffold(backgroundColor: Colors.blueGrey,);
  }

  Future<List<Map<String, dynamic>>> _searchStudents(String query) async {
    List<Map<String, dynamic>> studentsList = [];
    try {
      final databases = GetIt.I<Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          Query.equal('classId', Constants.classId),

          Query.search(searchBy, query),
        ],
      );

      studentsList = documents.documents.map((doc) => doc.data).toList();
    } on AppwriteException catch (e) {
      print('Error searching students: $e');
    }
    return studentsList;
  }

  Widget _buildStudentList(List<Map<String, dynamic>> filteredStudents) {
    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Card(
            color: Colors.blueGrey,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(15),
              title: Text(
                student["name"],
                style: TextStyle(fontSize: Constants.deviceWidth/22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                "${student["region"]} - ${student["address"]}",
                style: TextStyle(fontSize: Constants.deviceWidth/28, color: Colors.white70),
              ),
              trailing: IconButton(
                onPressed: () {
print(student["\$id"]);
                  connectivityService.checkConnectivity(context, submitForm(student["\$id"]));
Navigator.pop(context);
                },
                icon: Container(color: Colors.white, child: Icon(Icons.add, color: Colors.green,size: Constants.deviceWidth/15,)),
              ),
            ),
          ),
        );
      },
    );
  }
}