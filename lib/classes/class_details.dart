import 'package:appwrite/appwrite.dart';
import 'package:attendance/classes/edit_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'add_teacher.dart';

class ClassDetails extends StatefulWidget {
  final String classId;
  const ClassDetails({super.key, required this.classId});

  @override
  State<ClassDetails> createState() => _ClassDetailsState();
}

class _ClassDetailsState extends State<ClassDetails> {

  Map<dynamic, dynamic>? classData;
  bool isLoading = true;
@override
  void initState() {
    super.initState();
    _assignClassData();

}
  Future<void> _assignClassData() async {
    final data = await getClassData(widget.classId);
    if (data != null) {
      setState(() {
        classData = data;
        isLoading = false;
      });
    }
    else{
      setState(() {
        isLoading=false;
      });
    }
  }
  Future<Map<String, dynamic>?> getClassData(String classId) async {
    try {
      final databases = GetIt.I<Databases>();
      final document = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.servicesCollectionId,
        documentId: classId,
        // queries: [
        //   appwrite.Query.equal('classId', Constants.classId),
        //
        // ]
      );
      return document.data;
    } on AppwriteException {
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
floatingActionButton: FloatingActionButton(
  backgroundColor: Colors.blueGrey,
  onPressed: () {
Navigator.push(context, MaterialPageRoute(builder: (context) => EditClass(

    id: classData!["\$id"],
    name: classData!["name"],
    church: classData!["church"],
    usersPass: classData!["usersPassword"],
    adminsPass: classData!["adminsPassword"],
    payment: PaymentStatus.values.firstWhere(
            (e) => e.toString().split('.').last == classData!["payment"],
    )))
        );
},child: Icon(Icons.edit,color: Colors.white,),),
      body:isLoading?Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SpinKitWaveSpinner(
            color: Colors.blueGrey,
          ),
        ),
      )  :
          Container(
            width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.all( 16.0),
              child:
    Card(
    color: Colors.white,
    elevation: 4,
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child:Column(
      mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("${classData!["name"]}"),
      Text("${classData!["church"]}"),
      Text("باسورد مخدومين : ${classData!["usersPassword"]}"),
      Text("باسورد خدام : ${classData!["adminsPassword"]}"),
      Text("الحالة : ${classData!["payment"]}"),
 ListTile(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTeacher(),
      ),
    );
  },
 title: Text("اضافة ادمن", style: TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.blueGrey
 ),),
 leading: Icon(Icons.person_add, color: Colors.blueGrey, size: 30,)
 )

    ],
    ) ,
    )

          )
          )

    );
  }
}
