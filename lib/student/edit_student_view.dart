import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';
import 'students_page_view.dart';

class EditStudentView extends StatefulWidget {
  final String studentId;
  final String name;
  final String address;
  final String region;
  final String birthdayDate	;
  final String phone1;
  final String phone2;
  final List<dynamic> meetings;
  final String? notes;
  final String? abEle3traf;
  final String? faceBookLink;
  final String? instgramLink;
  final String? tiktokLink;


  const EditStudentView({
    super.key, 
    required this.studentId, 
    required this.name, 
    required this.birthdayDate, 
    required this.phone1, 
    required this.phone2, 
    required this.meetings, 
    required this.address, 
    required this.region,
    this.notes,
    this.abEle3traf,
    this.faceBookLink,
    this.instgramLink,
    this.tiktokLink,
  });

  @override
  State<EditStudentView> createState() => _EditStudentViewState();
}

class _EditStudentViewState extends State<EditStudentView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  final TextEditingController _birthMonthController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _abEle3trafController = TextEditingController();
  final TextEditingController _faceBookLinkController = TextEditingController();
  final TextEditingController _instgramLinkController = TextEditingController();
  final TextEditingController _tiktokLinkController = TextEditingController();

  String? region='غير محدد';
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
   _loadStudentData();
   _connectivityService =ConnectivityService();
  }

  // Helper function to parse birth date string into day, month, year
  Map<String, int> _parseBirthDate(String birthdayDate) {
    if (birthdayDate.isEmpty) {
      return {'birthDay': 0, 'birthMonth': 0, 'birthYear': 0};
    }
    
    try {
      // Try different date formats
      
      // Format 1: dd/MM/yyyy
      if (birthdayDate.contains('/')) {
        List<String> parts = birthdayDate.split('/');
        if (parts.length == 3) {
          int day = int.tryParse(parts[0]) ?? 0;
          int month = int.tryParse(parts[1]) ?? 0;
          int year = int.tryParse(parts[2]) ?? 0;
          return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
        }
      }
      
      // Format 2: dd-MM-yyyy
      if (birthdayDate.contains('-')) {
        List<String> parts = birthdayDate.split('-');
        if (parts.length == 3) {
          // Check if it's yyyy-MM-dd format
          if (parts[0].length == 4) {
            int day = int.tryParse(parts[2]) ?? 0;
            int month = int.tryParse(parts[1]) ?? 0;
            int year = int.tryParse(parts[0]) ?? 0;
            return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
          } else {
            // dd-MM-yyyy format
            int day = int.tryParse(parts[0]) ?? 0;
            int month = int.tryParse(parts[1]) ?? 0;
            int year = int.tryParse(parts[2]) ?? 0;
            return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
          }
        }
      }
      
      // Format 3: dd.MM.yyyy
      if (birthdayDate.contains('.')) {
        List<String> parts = birthdayDate.split('.');
        if (parts.length == 3) {
          int day = int.tryParse(parts[0]) ?? 0;
          int month = int.tryParse(parts[1]) ?? 0;
          int year = int.tryParse(parts[2]) ?? 0;
          return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
        }
      }
      
      // If no separator, try to parse as ddMMyyyy
      if (birthdayDate.length == 8) {
        int day = int.tryParse(birthdayDate.substring(0, 2)) ?? 0;
        int month = int.tryParse(birthdayDate.substring(2, 4)) ?? 0;
        int year = int.tryParse(birthdayDate.substring(4, 8)) ?? 0;
        return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
      }
      
    } catch (e) {
      print('Error parsing birth date: $birthdayDate - $e');
    }
    
    // Return defaults if parsing fails
    return {'birthDay': 0, 'birthMonth': 0, 'birthYear': 0};
  }

//
  void _loadStudentData() async {
      _nameController.text = widget.name ;
      _addressController.text = widget.address ;
      
      // Parse existing birth date into separate fields
      Map<String, int> parsedBirthDate = _parseBirthDate(widget.birthdayDate);
      _birthDayController.text = parsedBirthDate['birthDay']! > 0 ? parsedBirthDate['birthDay'].toString() : '';
      _birthMonthController.text = parsedBirthDate['birthMonth']! > 0 ? parsedBirthDate['birthMonth'].toString() : '';
      _birthYearController.text = parsedBirthDate['birthYear']! > 0 ? parsedBirthDate['birthYear'].toString() : '';
      
      _phone1Controller.text = widget.phone1;
      _phone2Controller.text = widget.phone2 ;
      region = widget.region;
      _notesController.text = widget.notes ?? '';
      _abEle3trafController.text = widget.abEle3traf ?? '';
      _faceBookLinkController.text = widget.faceBookLink ?? '';
      _instgramLinkController.text = widget.instgramLink ?? '';
      _tiktokLinkController.text = widget.tiktokLink ?? '';
  }

  Future<void> _updateStudent()async {
    if (_formKey.currentState!.validate()) {

      final databases = GetIt.I<Databases>();


  try{
    await  databases.updateDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        documentId: widget.studentId,
        data: {
          "name": _nameController.text ,
          "address":_addressController.text,
          "region":region,
          "birthDay": int.tryParse(_birthDayController.text) ?? 0,
          "birthMonth": int.tryParse(_birthMonthController.text) ?? 0,
          "birthYear": int.tryParse(_birthYearController.text) ?? 0,
          "phone1": _phone1Controller.text,
          "phone2": _phone2Controller.text,
          "notes": _notesController.text,
          "abEle3traf": _abEle3trafController.text,
          "faceBookLink": _faceBookLinkController.text,
          "instgramLink": _instgramLinkController.text,
          "tiktokLink": _tiktokLinkController.text,
        }
    );
    FocusScope.of(context).unfocus();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => StudentsPageView(),), (route) => false,);

  }on AppwriteException catch(e)

    {
      print(e);
    }


    }


  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    double sizedBoxHeight = MediaQuery.of(context).size.height/30;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,

        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: ElevatedButton(

              onPressed:
              () {
                _connectivityService.checkConnectivity(context,  _updateStudent());

              }
              ,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),side: BorderSide(width: 2,color: Colors.white)),
                backgroundColor: Colors.blueGrey,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                textStyle: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),
              ),
              //_updateStudent,
              child: Text("حفظ",style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
        title: Text("تعديل البيانات"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black,size: Constants.arrowBackSize),
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.pop(context);
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
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "الاسم",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يجب ادخال اسم المخدوم';
                    }
                    return null;
                  },
                ),

                SizedBox(height: sizedBoxHeight), // Spacing between fields

                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  initialValue: region,
                  decoration: InputDecoration(
                    labelText: "المنطقة",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: ['غير محدد','شرق المحطة', 'غرب', 'بحري', 'قبلي'].map((String value) {
                    return DropdownMenuItem<String>(


                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {

                    setState(() {
                      region = newValue;
                    });
                  },

                  // validator: (value) {
                  //
                  //   if ((_addressController.text.isNotEmpty&&(value == null || value.isEmpty)) ) {
                  //     return 'يجب اختيار منطقة';
                  //   }
                  //   return null;
                  // },
                ),

                SizedBox(height: sizedBoxHeight),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: "العنوان",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                SizedBox(height: sizedBoxHeight),
                
                // Birth Date Row with three input fields
                Row(
                  children: [
                    // Day field
                    Expanded(
                      child: TextFormField(
                        controller: _birthDayController,
                        decoration: InputDecoration(
                          labelText: "اليوم",
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
                        controller: _birthMonthController,
                        decoration: InputDecoration(
                          labelText: "الشهر",
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
                        controller: _birthYearController,
                        decoration: InputDecoration(
                          labelText: "السنة",
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
                
                SizedBox(height: sizedBoxHeight),
                TextFormField(
                  controller: _phone1Controller,
                  decoration: InputDecoration(
                    labelText: "Phone 1",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: sizedBoxHeight),
                TextFormField(
                  controller: _phone2Controller,
                  decoration: InputDecoration(
                    labelText: "Phone 2",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: sizedBoxHeight),
                
                // Notes field
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: "ملاحظات",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: "أضف ملاحظاتك هنا...",
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: sizedBoxHeight),
                
                // Confession Father field
                TextFormField(
                  controller: _abEle3trafController,
                  decoration: InputDecoration(
                    labelText: "أب الاعتراف",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: "اسم أب الاعتراف",
                  ),
                ),
                SizedBox(height: sizedBoxHeight),
                
                // Facebook Link field
                TextFormField(
                  controller: _faceBookLinkController,
                  decoration: InputDecoration(
                    labelText: "رابط Facebook",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.facebook),
                    hintText: "https://facebook.com/...",
                  ),
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: sizedBoxHeight),
                
                // Instagram Link field
                TextFormField(
                  controller: _instgramLinkController,
                  decoration: InputDecoration(
                    labelText: "رابط Instagram",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.camera_alt),
                    hintText: "https://instagram.com/...",
                  ),
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: sizedBoxHeight),
                
                // TikTok Link field
                TextFormField(
                  controller: _tiktokLinkController,
                  decoration: InputDecoration(
                    labelText: "رابط TikTok",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.music_video),
                    hintText: "https://tiktok.com/...",
                  ),
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: sizedBoxHeight),

              ],
            ),
          ),
        ),
      ),
    );
  }
}