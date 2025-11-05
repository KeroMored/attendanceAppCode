import 'package:appwrite/appwrite.dart';
import 'package:attendance/classes/class_details.dart';
import 'package:attendance/helper/appwrite_services.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/connectivity_service.dart';
import '../helper/constants.dart';

class DisplayClasses extends StatefulWidget {
  const DisplayClasses({super.key});

  @override
  State<DisplayClasses> createState() => _DisplayClassesState();
}

class _DisplayClassesState extends State<DisplayClasses> {
  List<Map<String, dynamic>> classesData = [];
  late ConnectivityService _connectivityService;
bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.checkConnectivity(context, _getClasses());

  }
  Future<void> deleteClass (String classId)async{
    final scaffoldContext = ScaffoldMessenger.of(context);
    final databases = GetIt.I<Databases>();
    try {
      await databases.deleteDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.servicesCollectionId,
          documentId: classId

      );
      scaffoldContext.showSnackBar(
        SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            content: Center(child: Text('تم حذف البيانات' ,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),))),
      );
    //  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => StudentsPageView(),), (route) => false,);
     classesData.clear();
      await _getClasses();

    }
    on AppwriteException
    {
      scaffoldContext.showSnackBar(

          SnackBar(
              duration: Duration(seconds: 2),

              backgroundColor: Colors.red,
              content: Center(child: Text('لم يتم حذف البانات' ,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),))));

    }
  }

  Future<void> _getClasses ()async{
    setState(() {
      isLoading=true;
    });
    try {
      final databases = GetIt.I<Databases>();
      final documents=   await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.servicesCollectionId
      );

      classesData.addAll(documents.documents.map((doc) => doc.data).toList());

    }
    on AppwriteException catch(e)
    {
      print(e);
    }
    catch (e)
    {
      print(e);


    }
    setState(() {
      isLoading=false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body:
      (isLoading && classesData.isEmpty)?

      Container(
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
      )
          : ListView.builder(
        itemCount: classesData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Card(
              color: Colors.blueGrey,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                  title: Center(
                    child: Text(
                      classesData[index]["name"],
                      style: TextStyle(
                        fontSize: Constants.deviceWidth / 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  subtitle: Center(
                    child: Text(
                      classesData[index]["church"],
                      style: TextStyle(
                        fontSize: Constants.deviceWidth / 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),


                  onTap: () async{
                    await _connectivityService.checkConnectivityWithoutActions(context);
                    if(_connectivityService.isConnected) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ClassDetails(classId: classesData[index]['\$id']),
                      )
                      );
                    } else {
                      // Handle offline case
                    }
                  },

                  onLongPress: () {
                  AwesomeDialog(
                  dialogBackgroundColor: Colors.white,
                  context: context,
                  dialogType: DialogType.noHeader,
                  animType: AnimType.rightSlide,
                  title: 'أتريد حذف هذه البيانات؟',
                  //        desc: 'Dialog description here.............',
                  btnCancelText: "حذف",
                  btnCancelOnPress: () async{
                  await deleteClass(classesData[index]["\$id"]);


                  },
                  ).show();


            } ),
              ),
            ),
          );
        },
      )

      ,


    );
  }
}
