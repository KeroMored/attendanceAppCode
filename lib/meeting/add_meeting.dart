import 'package:appwrite/appwrite.dart';
import 'package:attendance/meeting/display_meetings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class AddMeeting extends StatefulWidget {
  const AddMeeting({super.key});

  @override
  State<AddMeeting> createState() => _AddMeetingState();
}

class _AddMeetingState extends State<AddMeeting> {
  String type ="حصة الألحان";
  bool isLoading = false;
  DateTime selectedDate = DateTime.now(); // Store the selected date

  void _submitForm() async {
    // Use the selected date instead of DateTime.now()
   // String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
setState(() {
  isLoading=true;
});

    try {
      // Try to include the teacher name as createdBy if available
      String? createdBy;
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('teacherName');
        if (savedName != null && savedName.trim().isNotEmpty) {
          createdBy = savedName.trim();
        }
      } catch (_) {
        // Ignore errors reading prefs; createdBy will remain null
      }

      Map<String, dynamic> data = {
        'Type': type,
        'createdAt': selectedDate.toUtc().toIso8601String(), // Convert to UTC for consistency
        'students': <dynamic>[],
        'classId' : Constants.classId,
        if (createdBy != null) 'createdBy': createdBy,
      };

      try {
        final databases = GetIt.I<Databases>();
        final document = await databases.createDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.meetingsCollectionId,
          documentId: ID.unique(),
          data: data,
          permissions: [
            Permission.read(Role.any()), // Ensure users have read permission
            Permission.write(Role.any()), // Ensure users have write permission
          ],
        );

        print(document);
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
              duration:Duration(seconds: 1),

              backgroundColor: Colors.green,
              content: Center(child: Text('تم إضافة الأجتماع'))),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DisplayMeetings()),
              (route) => false,
        );

      } on AppwriteException catch (e) {
        print(e);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(

            content: Text('لم يتم الحفظ')),
      );
    }
    setState(() {
      isLoading=false;
    });

  }

  Future<void> _selectDateTime() async {
    await dtp.DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2020, 1, 1),
      maxTime: DateTime(2030, 12, 31, 23, 59),
      currentTime: selectedDate,
      locale: dtp.LocaleType.ar,
      onConfirm: (DateTime date) {
        setState(() {
          selectedDate = date;
        });
      },
      theme: dtp.DatePickerTheme(
        doneStyle: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
        cancelStyle: TextStyle(color: Colors.redAccent),
        itemStyle: TextStyle(fontSize: 18, color: Colors.black87),
        containerHeight: 220,
      ),
    );
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
      inAsyncCall: isLoading,


  child: Scaffold(

        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(onPressed: () {
            Navigator.pop(context);
          }, icon: Icon(Icons.arrow_back,size:Constants.arrowBackSize)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              DropdownButton<String>(

                padding: EdgeInsets.all(10),


                dropdownColor: Colors.white,
                value: type,
                style: TextStyle(fontSize: 25,color: Colors.black),
                icon: Icon(Icons.arrow_drop_down,size: Constants.deviceWidth/10,),
                items: <String>['حصة الألحان', 'قداس', "تسبحة", "مدارس أحد", "اجتماع"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(



                    alignment: Alignment.centerRight,
                    value: value,
                    child: Text(value,style: TextStyle(fontSize:Constants.deviceWidth/15 ),),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                   setState(() {
                     type = newValue;
                   });
          //                _updateOrderBy(newValue);
                  }
                },
              ),
      SizedBox(height: 20,),
      
      // Date and Time Selection Section
      Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'تاريخ ووقت الاجتماع:',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Constants.deviceWidth / 22, // Slightly smaller to avoid overflow
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8), // spacing
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: _selectDateTime,
                    icon: Icon(
                      Icons.calendar_today,
                      color: Colors.blueGrey,
                      size: Constants.deviceWidth / 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              child: Text(
                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year} - ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: Constants.deviceWidth / 24, // Slightly smaller to prevent overflow
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // Handle overflow
                maxLines: 2, // Allow text to wrap to 2 lines if needed
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime.now();
                  });
                },
                icon: Icon(Icons.refresh, color: Colors.white, size: Constants.deviceWidth / 28),
                label: Flexible(
                  child: Text(
                    'استخدام الوقت الحالي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Constants.deviceWidth / 28, // Reduced font size
                    ),
                    overflow: TextOverflow.ellipsis, // Handle text overflow
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Reduced horizontal padding
                ),
              ),
            ),
          ],
        ),
      ),
      
      SizedBox(height: 20,),
           ClipRRect(
             borderRadius: BorderRadius.circular(10),
             child: GestureDetector(
              onTap: () {
      _submitForm();

              },
               child: Container(
                 height: Constants.deviceWidth/5,
                 color: Colors.blueGrey,
                 width: double.infinity,


               child: Center(child: Text("إنشاء اجتماع",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w900),)),
               ),
             ),
           ),
           SizedBox(height: 20), // Add bottom padding
            ],
          ),
        ), // end SingleChildScrollView
      ), // end SafeArea
    ),
  );
  }
}
