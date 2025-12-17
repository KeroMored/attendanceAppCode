import 'package:appwrite/appwrite.dart';
import 'package:attendance/classes/display_classes.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/appwrite_services.dart';
import '../helper/secure_appwrite_service.dart';
import '../helper/constants.dart';
import '../login_page.dart';

class AddClasses extends StatefulWidget {
  const AddClasses({super.key});

  @override
  State<AddClasses> createState() => _AddClassesState();
}

class _AddClassesState extends State<AddClasses> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _teacherPasswordController = TextEditingController();
  String _selectedChurch = 'كنيسة العذراء مريم بالصاغة';





  Future<void> _addClass ( ) async{

    try{
      final databases = GetIt.I<Databases>();
      databases.createDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.servicesCollectionId,
          documentId: ID.unique(),
          data:
          {
           "name" :_classNameController.text ,
           "church" : _selectedChurch,
           "usersPassword" : _userPasswordController.text,
           "adminsPassword" : _teacherPasswordController.text,
          //  "payment":PaymentStatus.paid.toString()

           // "minAge" : ,
           // "maxAge" : ,

          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Center(child: Text('تمت إضافة الفصل', style: TextStyle(fontWeight: FontWeight.bold))),
        ),
      );
      _classNameController.clear();
      _userPasswordController.clear();
      _teacherPasswordController.clear();
      setState(() {
        _selectedChurch = 'كنيسة العذراء مريم بالصاغة';
      });
    }on AppwriteException catch(e)
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

    return  Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayClasses(),));
      },child: Icon(Icons.sticky_note_2_outlined),),
      backgroundColor: Colors.white,
      appBar: AppBar(

        actions: [
          TextButton(onPressed: () async{
            // Use secure logout
            final pref= await SharedPreferences.getInstance();
            await pref.setString("password","");
            await pref.setString("className","");
            await pref.setString("classId","");
            await pref.setString("teacherPassword","");
            await pref.setString("teacherId","");
            await pref.setString("teacherName","");
            await pref.setString("teacherRole","");
            Constants.classId="";
            Constants.passwordValue="";
            Constants.className="";
            Constants.isUser= true;
            
            // Clear secure session
            try {
              // Import SecureAppwriteService if not already imported
              await SecureAppwriteService.logout();
            } catch (e) {
              print('Logout error: $e');
            }
            
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage(),), (route) => false,);
          }, child: Text("تسجيل الخروج",style: TextStyle(fontSize: 20,color: Colors.black),))
        ],
      ),

      body:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedChurch,

                decoration: InputDecoration(labelText: 'اسم الكنيسة'),
                items: ['كنيسة العذراء مريم بالصاغة']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedChurch = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يجب اختيار اسم الكنيسة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _classNameController,
                decoration: InputDecoration(labelText: 'اسم الفصل'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يجب إدخال اسم الفصل';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _userPasswordController,
                decoration: InputDecoration(labelText: 'باسورد مستخدمين'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يجب إدخال باسورد مستخدمين';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _teacherPasswordController,
                decoration: InputDecoration(labelText: 'باسورد الخدام'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يجب إدخال باسورد الخدام';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addClass();

                  }
                },
                child: Text('إضافة',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
              ),


            ],
          ),
        ),
      ),
    );

  }
}
