import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';

class Createqrview extends StatefulWidget {
  const Createqrview({super.key});

  @override
  State<Createqrview> createState() => _CreateqrviewState();
}

class _CreateqrviewState extends State<Createqrview> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  final TextEditingController _birthMonthController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  String? qrData;

  String? region = "غير محدد";
  late ConnectivityService _connectivityService;

  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _connectivityService =
        ConnectivityService(); // Initialize the connectivity service
  }

  Future<void> submitForm() async {
    print(Constants.classId);
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      print(Constants.classId);
      try {

        Map<dynamic, dynamic> data = {
          'name': _nameController.text,
          'address': _addressController.text,
          'region': region,
          'birthDay': int.tryParse(_birthDayController.text) ?? 0,
          'birthMonth': int.tryParse(_birthMonthController.text) ?? 0,
          'birthYear': int.tryParse(_birthYearController.text) ?? 0,
          'phone1': _phone1Controller.text,
          'phone2': _phone2Controller.text,
          'meetings': [], // Assuming meetings are initially empty
          'alhanCounter': 0,
          'qudasCounter': 0,
          'tasbhaCounter': 0,
          'madrasAhadCounter': 0,
          'ejtimaCounter': 0,
          'totalCounter': 0,
          'bonus': 0,
          'classId': Constants.classId,
          'password': generateUniquePassword(),
        };

        try {
          final databases = GetIt.I<Databases>();
          final document = databases.createDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            documentId: ID.unique(),
            data: data,
            permissions: [
              Permission.read(Role.any()), // Ensure users have read permission
              Permission.write(
                  Role.any()), // Ensure users have write permission
            ],
          );

          print(document);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
                content: Center(
                    child: Text(
                  'تم إضافة البيانات بنجاح',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ))),
          );
          _nameController.clear();
          _addressController.clear();
          _birthDayController.clear();
          _birthMonthController.clear();
          _birthYearController.clear();
          _phone1Controller.clear();
          _phone2Controller.clear();
          setState(() {
            region = "غير محدد"; // Reset to default value
          });
          FocusScope.of(context).unfocus();
        } on AppwriteException catch (e) {
          print(e);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لم يتم الحفظ')),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }
  Set<String> usedPasswords = {};
  String generateUniquePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random random = Random();
    String password;

    do {
      password = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
    } while (usedPasswords.contains(password));

    usedPasswords.add(password); // Add generated password to set
    return password;
  }


  @override
  Widget build(BuildContext context) {
    Constants.setSize(
        MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return ModalProgressHUD(
      progressIndicator: Center(
        child: SpinKitWaveSpinner(
          color: Colors.white,
          waveColor: Colors.blueGrey,
          trackColor: Colors.blueGrey,
        ),
      ),
      inAsyncCall: isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            ElevatedButton(
            onPressed: () async {
      FocusScope.of(context).unfocus(); // Close the keyboard
      if (_connectivityService.isConnected) {
      await _connectivityService.checkConnectivity(context, submitForm());
      } else {
      _connectivityService.checkConnectivityWithoutActions(context);
      }
      },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5))),
              child: Text(
                "إضافة",
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              width: 16,
            ),
          ],
          title: Text(
            "إضافة مخدوم",
            style: TextStyle(fontSize: Constants.deviceWidth / 22),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: Constants.arrowBackSize,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus(); // Close the keyboard
              Navigator.pop(context); // Navigate to the home page
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    onTapOutside: (e) {
                      FocusScope.of(context)
                          .unfocus(); // Unfocus all text fields
                    },
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "الاسم",
                      labelStyle:
                          TextStyle(fontSize: Constants.deviceWidth / 22),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person,
                        size: Constants.deviceWidth / 15,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال اسم المخدوم';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16), // Spacing between fields

                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    initialValue: region,
                    decoration: InputDecoration(
                      labelText: "المنطقة",
                      labelStyle:
                          TextStyle(fontSize: Constants.deviceWidth / 22),
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.map, size: Constants.deviceWidth / 15),
                    ),
                    items: ['غير محدد', 'شرق المحطة', 'غرب', 'بحري', 'قبلي']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        alignment: Alignment.centerRight,
                        value: value,
                        child: Text(
                          value,
                          style:
                              TextStyle(fontSize: Constants.deviceWidth / 30),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        region = newValue;
                      });
                    },
                  ),

                  SizedBox(height: 16), // Spacing between fields
                  TextFormField(
                    onTapOutside: (e) {
                      FocusScope.of(context)
                          .unfocus(); // Unfocus all text fields
                    },
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: "العنوان",
                      labelStyle:
                          TextStyle(fontSize: Constants.deviceWidth / 22),
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.home, size: Constants.deviceWidth / 15),
                    ),
                  ),
                  SizedBox(height: 16), // Spacing between fields
                  
                  // Birth Date Row with three input fields
                  Row(
                    children: [
                      // Day field
                      Expanded(
                        child: TextFormField(
                          onTapOutside: (e) {
                            FocusScope.of(context).unfocus();
                          },
                          controller: _birthDayController,
                          decoration: InputDecoration(
                            labelText: "اليوم",
                            labelStyle: TextStyle(fontSize: Constants.deviceWidth / 22),
                            border: OutlineInputBorder(),
                            hintText: "01-31",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              int? day = int.tryParse(value);
                              if (day == null || day < 1 || day > 31) {
                                return 'اليوم 1-31';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      
                      // Month field
                      Expanded(
                        child: TextFormField(
                          onTapOutside: (e) {
                            FocusScope.of(context).unfocus();
                          },
                          controller: _birthMonthController,
                          decoration: InputDecoration(
                            labelText: "الشهر",
                            labelStyle: TextStyle(fontSize: Constants.deviceWidth / 22),
                            border: OutlineInputBorder(),
                            hintText: "01-12",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              int? month = int.tryParse(value);
                              if (month == null || month < 1 || month > 12) {
                                return 'الشهر 1-12';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      
                      // Year field
                      Expanded(
                        child: TextFormField(
                          onTapOutside: (e) {
                            FocusScope.of(context).unfocus();
                          },
                          controller: _birthYearController,
                          decoration: InputDecoration(
                            labelText: "السنة",
                            labelStyle: TextStyle(fontSize: Constants.deviceWidth / 22),
                            border: OutlineInputBorder(),
                            hintText: "1990",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              int? year = int.tryParse(value);
                              int currentYear = DateTime.now().year;
                              if (year == null || year < 1900 || year > currentYear) {
                                return 'سنة صحيحة';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16), // Spacing between fields
                  TextFormField(
                    onTapOutside: (e) {
                      FocusScope.of(context)
                          .unfocus(); // Unfocus all text fields
                    },
                    controller: _phone1Controller,
                    decoration: InputDecoration(
                      labelStyle:
                          TextStyle(fontSize: Constants.deviceWidth / 22),
                      labelText: "Phone 1",
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.phone, size: Constants.deviceWidth / 15),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16), // Spacing between fields
                  TextFormField(
                    onTapOutside: (e) {
                      FocusScope.of(context)
                          .unfocus(); // Unfocus all text fields
                    },
                    controller: _phone2Controller,
                    decoration: InputDecoration(
                      labelStyle:
                          TextStyle(fontSize: Constants.deviceWidth / 22),
                      labelText: "Phone 2",
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.phone, size: Constants.deviceWidth / 15),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20), // Spacing before button
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
