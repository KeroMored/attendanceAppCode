import 'package:attendance/meeting/display_meetings.dart';
import 'package:attendance/login_page.dart';
import 'package:attendance/notification/display_notifications.dart';
import 'package:attendance/student/students_page_view.dart';
import 'package:attendance/student/birthday_students_view.dart';
import 'package:attendance/team/login_to_team_lineup.dart';
import 'package:attendance/student/types_of_create_qr.dart';
import 'package:attendance/eftekad/eftekad_home.dart';
import 'package:attendance/quiz/quiz_home_page.dart';
import 'package:attendance/quiz/results_home_page.dart';
import 'package:attendance/display_verse_page.dart';
import 'package:attendance/pray/pray_home_page.dart';
import 'package:attendance/pray/pray_results_home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'classes/super_admin_page.dart';
import 'classes/teacher_profile.dart';
import 'helper/constants.dart';
import 'helper/connectivity_service.dart';
import 'helper/secure_appwrite_service.dart';
import 'voice/display_voice_notes.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
  }

  Future<void> _navigateToTeamLineup(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
          ),
        );
      },
    );

    try {
      // Check connectivity before navigating
      await _connectivityService.checkConnectivityWithoutActions(context);
      
      // Dismiss loading indicator
      Navigator.of(context).pop();
      
      if (_connectivityService.isConnected) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => LoginToTeamLineup()),
        );
      }
      // If not connected, the ConnectivityService will show the error message
    } catch (e) {
      // Dismiss loading indicator in case of error
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              'خطأ في التحقق من الاتصال',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: Constants.deviceWidth / 25,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
  }




  void openWhatsApp(String phoneNumber) async {
    print(Constants.deviceHeight);
    print(Constants.deviceWidth);
    final String whatsappUrl = "https://wa.me/$phoneNumber";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;
  //  WidgetsBinding.instance.addPostFrameCallback((_) {
      Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
  //  });
    double sizedBoxHeight = MediaQuery.of(context).size.height/40;


    return Scaffold(
      floatingActionButton: (!Constants.isUser) 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherProfile(),
                  ),
                );
              },
              backgroundColor: Colors.blueGrey,
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            )
          : null,

      appBar: AppBar(
actions: [
  TextButton(onPressed: () async{
    // Check if current user is super admin
    final userType = await SecureAppwriteService.getCurrentUserType();
    if (userType == UserType.superAdmin) {
      _showSuperAdminExitDialog();
    } else {
      _performNormalLogout();
    }
  }, child:Text("خروج",style: TextStyle(fontSize: Constants.deviceWidth/20,color: Colors.black,fontWeight: FontWeight.bold),))

],
     //   toolbarHeight: screenHeight/12,
 // actions: [
 //   IconButton(onPressed: () {
 //
 //   }, icon: Icon(Icons.edit))
 // ],

        title:  Container(
          // color: Colors.blueGrey,
          child: Text(
            "{ ${Constants.className} }",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: Constants.deviceWidth/22, color: Colors.black),
          ),
        ),
        centerTitle: true,
        // leading:  TextButton(onPressed: () async{
        //   final pref= await SharedPreferences.getInstance();
        //   await pref.setString("password","");
        //   await pref.setString("className","");
        //   await pref.setString("classId","");
        //   Constants.classId="";
        //
        //   Constants.passwordValue="";
        //   Constants.classId="";
        //   Constants.className="";
        //   Constants.isUser= true;
        //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage(),), (route) => false,);
        // }, child:Text("خروج",style: TextStyle(fontSize: 50),))

      //  Text("تسجيل الخروج",style: TextStyle(fontSize: 20,color: Colors.blueGrey),))

      ),
      backgroundColor:Colors.amber, // Clean white background
      body: Stack(
    children: [
      Container(
    decoration: BoxDecoration(image: DecorationImage(
        fit: BoxFit.fill,
        image: AssetImage(Constants.backgroundImage,)),

   )
    ),

    Center(
            child: ListView(
              children: [
               // Spacer(),
               // Spacer(flex: 1,),


                if  (!Constants.isUser)
                  Column(
                    children: [
                      buildButton(context, "الأجتماعات والغياب", () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => DisplayMeetings()),
                        );

                      },
                     Constants.scan
                      ),
                      SizedBox(height: sizedBoxHeight),
                      buildButton(

                          context, "اضافة المخدومين", () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => TypesOfCreateQr()),
                        );
                      },
                        Constants.addUser
                      ),
                      SizedBox(height: sizedBoxHeight),
                      buildButton(
                        context, "الافتقاد", () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EftekedHome(),
                            ),
                          );
                        },
                        Constants.eftekad
                      ),
                      SizedBox(height: sizedBoxHeight),
                buildButton(context,
         
                "بيانات المخدومين", () {

                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => StudentsPageView()),
                  );
                },
                  Constants.users


                ),


          SizedBox(height: sizedBoxHeight),
                buildButton(context,
                "أعياد الميلاد", () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BirthdayStudentsView()),
                  );
                },
                Constants.cake
                ),


                    ],
                  )

                else Container(),
                                      SizedBox(height: sizedBoxHeight),

                (Constants.classId=="681f72c87215111b670e")?
    Column(
      children: [

        buildButton(

        context, "التشكيلة", () async {
        await _navigateToTeamLineup(context);
        },
        Constants.team
        ),
        SizedBox(height: sizedBoxHeight),

      ],
    )
                :
              Container()  ,

              Column( children: [


                buildButton(context, "آية اليوم", () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DisplayVersePage()),
                  );
                },
                  Constants.verse  // Using Bible verse icon
                ),
                (Constants.classId=="681f72c87215111b670e")?

                                      SizedBox(height: sizedBoxHeight):Container(),
(Constants.classId=="681f72c87215111b670e")?
                  buildButton(context, "الألحان", () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DisplayVoiceNotes()),
                  );
                },
                Constants.naqoos

                  ):
                  Container(),
                SizedBox(height: sizedBoxHeight),





                buildButton(context, "تنبيهات", () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DisplayNotifications()),
                  );
                },

                  Constants.mic

                ),

                    SizedBox(height: sizedBoxHeight),

                buildButton(context, "مسابقات", () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => QuizHomePage()),
                  );
                },
                  Constants.quiz

                ),
                SizedBox(height: sizedBoxHeight),

                buildButton(context, "الصلاة", () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PrayHomePage()),
                  );
                },
                  Constants.pray
                ),
            
          
                
                // Results button - only for admins
                if (!Constants.isUser)
                  SizedBox(height: sizedBoxHeight),
                
                if (!Constants.isUser)
                  buildButton(context, "نتائج المسابقات", () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ResultsHomePage()),
                    );
                  },

                    Constants.result
                  ),
                
                if (!Constants.isUser)
                  SizedBox(height: sizedBoxHeight),

                if (!Constants.isUser)
                  buildButton(context, "نتائج الصلاة", () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PrayResultsHomePage()),
                    );
                  },
                    Constants.pray_results
                  ),


              ],),
          
              //  Spacer(flex: 1,),
              //  SizedBox(height: sizedBoxHeight),
//Spacer(),
                GestureDetector(
                  onTap: () {
                    openWhatsApp("1222703436");
                  },
                              child: Column(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     Text("Created By: Kero Mored",style: TextStyle(fontStyle: FontStyle.italic,fontSize: Constants.deviceWidth/30,color: Colors.black,fontWeight: FontWeight.bold),),

                        Text(

                         "للتواصل واتساب",
                         style: TextStyle(decoration: TextDecoration.underline,fontStyle: FontStyle.italic,fontSize: Constants.deviceWidth/30,color: Colors.black,fontWeight: FontWeight.bold),
                       ),

                   ],
                 ),
                              )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(BuildContext context, String label, VoidCallback onPressed,String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [ Color(0xffbcf1ff), Colors.white, Colors.white],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
            ),
      ),
      width: Constants.deviceWidth/1.1,
      child:
      MaterialButton(
padding: EdgeInsets.symmetric(vertical: 15),
        // style: ElevatedButton.styleFrom(
           

        //   backgroundColor: Colors.transparent,
        //   padding: EdgeInsets.symmetric(vertical: 15),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(10), // Rounded corners
        //   ),
        //   elevation: 5,
        // ),
        onPressed: onPressed,
        child: ListTile(

          trailing: AspectRatio(

              aspectRatio: 1,
              child: Container(

                  color: Colors.white,
                  child: Image.asset(

                      fit: BoxFit.fill,
                      imagePath))),
          //Icon(icon,color: Colors.white,size: Constants.deviceWidth/20,),
          title: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: Constants.deviceHeight/40,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSuperAdminExitDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Super Admin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Constants.deviceWidth / 20,
            ),
          ),
          content: Text(
            'اختر العملية المطلوبة:',
            style: TextStyle(fontSize: Constants.deviceWidth / 24),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SuperAdminPage()),
                );
              },
              child: Text(
                'الذهاب للوحة التحكم',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: Constants.deviceWidth / 26,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performNormalLogout();
              },
              child: Text(
                'خروج نهائي',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: Constants.deviceWidth / 26,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performNormalLogout() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
                SizedBox(height: 15),
                Text(
                  'جاري تسجيل الخروج...',
                  style: TextStyle(
                    fontSize: Constants.deviceWidth / 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: "NotoSansArabic",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setString("password", "");
      await pref.setString("className", "");
      await pref.setString("classId", "");
      await pref.setString("teacherPassword", "");
      await pref.setString("teacherId", "");
      await pref.setString("teacherName", "");
      await pref.setString("teacherRole", "");
      await pref.remove("superAdminSelectedClass");
      Constants.classId = "";
      Constants.passwordValue = "";
      Constants.classId = "";
      Constants.className = "";
      Constants.isUser = true;
      
      // Clear secure session to ensure proper logout
      await SecureAppwriteService.logout();
      
      // Small delay to show the loading indicator
      await Future.delayed(Duration(milliseconds: 500));
      
      // Dismiss loading dialog
      Navigator.of(context).pop();
      
      // Navigate to login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      // Dismiss loading dialog in case of error
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في تسجيل الخروج'),
        ),
      );
    }
  }
}