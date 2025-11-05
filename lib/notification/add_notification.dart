import 'package:appwrite/appwrite.dart';

import 'package:attendance/notification/display_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class AddNotification extends StatefulWidget {
  const AddNotification({super.key});

  @override
  State<AddNotification> createState() => _AddNotificationState();
}

class _AddNotificationState extends State<AddNotification> {
  final TextEditingController _messageController = TextEditingController();

  GlobalKey<FormState>formState=GlobalKey();

  Future<void> _uploadToAppwrite (String message)async{
  try{

    final database = GetIt.I<Databases>();
    await database.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.notificationsCollectionId,
        documentId: ID.unique(),
        data: {
          "message":message ,
          "classId":Constants.classId ,

        });
       _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Colors.green,
          content: Center(child: Text("تم اضافة الملاحظة",style: TextStyle(color: Colors.white),)))
    );

  }
  on AppwriteException catch(e)
    {
      print(e);
    }
    catch(e)
    {
      print(e);

    }

  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
      leading: IconButton(onPressed: () {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => DisplayNotifications(),), (route) => false,);
      }, icon: Icon(Icons.arrow_back,size: Constants.arrowBackSize,)),

        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ElevatedButton(
              onPressed: (){
                if(formState.currentState!.validate())
                {
                  _uploadToAppwrite(_messageController.text);
                //    _uploadToAppwrite(_filePath!,_nameController.text);

                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.blueGrey,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18),

                // primary: _isRecording ? Colors.red : Colors.blue,
              ),
              child: Text("حفظ",style: TextStyle(color: Colors.white),),
            ),
          ),
          SizedBox(width: 16,)
        ],
      ),

      body: Form(
        key: formState,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TextFormField(
                style: TextStyle(fontSize: Constants.deviceWidth/22),
                controller: _messageController,
                onTapOutside:(p){

                  FocusScope.of(context).unfocus();
                },
autovalidateMode: AutovalidateMode.onUnfocus,
                decoration: InputDecoration(
                  labelStyle:TextStyle(fontSize: Constants.deviceWidth/25),
                  fillColor: Colors.white,
                  filled: true,
                  labelText: 'إضافة ملاحظة',
                ),


                validator: (value) {
                  if(value==null|| value.isEmpty)
                    {
                      return "يجب كتابة الملاحظة";
                    }
                  return null;


                },
              ),
            ),



          ],


        ),
      ),
    );
  }
}
