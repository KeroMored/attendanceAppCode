import 'package:attendance/student/create_qr_for_all_students_view.dart';
import 'package:flutter/material.dart';
import '../helper/constants.dart';
import '../helper/special_button.dart';
import 'create_qr_view.dart';

class TypesOfCreateQr extends StatelessWidget {
  const TypesOfCreateQr({super.key});

  @override
  Widget build(BuildContext context) {
    double sizedBoxHeight = MediaQuery.of(context).size.height/20;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        title: Text("اختيار نوع الإضافة",style: TextStyle(color: Colors.white),),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back,size: Constants.arrowBackSize,color: Colors.white,),
        ),

      ),
      body: Center(
        child:
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpecialButton(label:  "اضافة المخدومين من شيت اكسل",

                  onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CreateQrForAllStudentsView()),
              );

            },

             imagePath: Constants.uploadExcel
            ),
             SizedBox(height: sizedBoxHeight),
            SpecialButton(
              label:

                 "اضافة مخدوم يدوي",

                  onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Createqrview()),
              );
            },
              imagePath:   Constants.addUser
            ),
             SizedBox(height: sizedBoxHeight),

          ],
        )

      ),


    );
  }
}
