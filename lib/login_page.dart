// import 'package:attendance/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'HomePage.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _controller = TextEditingController();
//
//   Future<void> _signIn() async {
//     if (Constants.usersPasswords.contains(_controller.text)||Constants.admainsPasswords.contains(_controller.text)) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('password', _controller.text);
//        Constants.passwordValue= _controller.text;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => Homepage()),
//       );
//     } else {
//       // Show an error message if the password is incorrect
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//
//             content: Center(child: Text('رقم سري غير صحيح',style: TextStyle(fontWeight: FontWeight.bold),))),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//
//         title: const Text('Login'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: _controller,
//               decoration: const InputDecoration(
//                 labelText: 'Password',
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _signIn,
//               child: const Text('Sign In'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/secure_appwrite_service.dart';
import 'helper/appwrite_services.dart';
import 'helper/constants.dart';
import 'helper/styles.dart';
import 'classes/teacher_login.dart';
import 'classes/super_admin_home_page.dart';
import 'classes/add_classes.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String,dynamic>> classesData = [];
  String className = "";
  bool _isLoading = false;
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  @override
  void initState() {
    super.initState();
    _getClassesData();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    // Test Appwrite connection on first load
    await SecureAppwriteService.testConnection();
    
    if (await SecureAppwriteService.isAuthenticated()) {
      final userType = await SecureAppwriteService.getCurrentUserType();
      _navigateBasedOnUserType(userType!);
    }
  }

  // Only call this method when user explicitly logs out
  static Future<void> performLogout()async{
    final pref= await SharedPreferences.getInstance();
    await pref.setString("password","");
    await pref.setString("className","");
    await pref.setString("classId","");
    await pref.setString("teacherPassword","");
    await pref.setString("teacherId","");
    await pref.setString("teacherName","");
    await pref.setString("teacherRole","");
    await pref.remove("teamPassword");
    await pref.remove("teamStudentId");
    Constants.classId="";
    Constants.passwordValue="";
    Constants.className="";
    Constants.isUser= true;
    
    // Clear secure session
    await SecureAppwriteService.logout();
  }

  Future<void>_getClassesData()async{
    try{
      final databases  = GetIt.I<Databases>();
   final   documents=  await databases.listDocuments(databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.servicesCollectionId,

      );

setState(() {
  classesData = documents.documents.map((doc) => doc.data).toList();

});
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


  Future<void> _authenticate() async {
    final password = _controller.text.trim();
    
    if (password.isEmpty) {
      _showErrorSnackBar('يرجى إدخال كلمة المرور');
      return;
    }
    
    // Check rate limiting
    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
      final remainingTime = _lockoutEndTime!.difference(DateTime.now()).inMinutes;
      _showErrorSnackBar('تم حظر المحاولات لمدة $remainingTime دقيقة');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check for special navigation passwords first
      if (password == "469369219") {
        // Save session data for special passwords
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', "469369219"); // Save to 'password' key for splash
        await prefs.setString('passwordValue', "469369219");
        await prefs.setBool('isUser', false); // Save admin access flag
        await prefs.setString('destination', 'AddClasses'); // Save destination
        
        Constants.passwordValue = "469369219";
        Constants.isUser = false; // Admin access
        Constants.className = '';
        Constants.classId = '';
        
        _resetFailedAttempts();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddClasses()),
        );
        return;
      }
      
      if (password == "15234679!@#") {
        // Save session data for super admin password
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', "15234679!@#"); // Save to 'password' key for splash
        await prefs.setString('passwordValue', "15234679!@#");
        await prefs.setBool('isUser', false); // Save admin access flag
        await prefs.setString('destination', 'SuperAdminHomePage'); // Save destination
        
        Constants.passwordValue = "15234679!@#";
        Constants.isUser = false; // Admin access
        Constants.className = '';
        Constants.classId = '';
        
        _resetFailedAttempts();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuperAdminHomePage()),
        );
        return;
      }
      
      // Regular authentication for other passwords
      AuthResult result = await SecureAppwriteService.authenticateWithPassword('', password);

      if (result.success) {
        // Save session data based on authentication result
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('passwordValue', password);
        
        // Set isUser flag based on user type from authentication
        bool isUserFlag = result.userType == UserType.user;
        await prefs.setBool('isUser', isUserFlag);
        
        Constants.passwordValue = password;
        Constants.isUser = isUserFlag;
        
        _resetFailedAttempts();
        
        // ✅ Special handling for admin code 469369219
        if (password == "469369219") {
          // Navigate directly to AddClasses page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddClasses()),
          );
        } else {
          _navigateBasedOnUserType(result.userType);
        }
      } else {
        _handleFailedAttempt();
        _showErrorSnackBar('كلمة المرور غير صحيحة');
      }
      
    } catch (e) {
      _handleFailedAttempt();
      _showErrorSnackBar('كلمة المرور غير صحيحة');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    
    if (_failedAttempts >= 3) {
      // Lock out for 5 minutes after 3 failed attempts
      _lockoutEndTime = DateTime.now().add(const Duration(minutes: 5));
      _showErrorSnackBar('تم حظر المحاولات لمدة 5 دقائق بسبب المحاولات المتكررة');
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutEndTime = null;
  }

  void _navigateBasedOnUserType(UserType userType) async {
    Widget destination;
    
    switch (userType) {
      case UserType.superAdmin:
        destination = const SuperAdminHomePage();
        break;
      case UserType.admin:
      case UserType.user:
        // Check if we have a saved teacher session for admin users
        if (userType == UserType.admin) {
          final prefs = await SharedPreferences.getInstance();
          final savedTeacherPassword = prefs.getString('teacherPassword');
          
          // If no saved teacher session, go to TeacherLogin
          if (savedTeacherPassword == null || savedTeacherPassword.isEmpty) {
            final classData = await SecureAppwriteService.getTemporaryClassData();
            destination = TeacherLogin(
              classId: classData?['classId'] ?? '',
              className: classData?['className'] ?? '',
              adminPassword: _controller.text,
            );
            break;
          }
        }
        // For users or admins with saved teacher sessions, go directly to Homepage
        destination = const Homepage();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          Stack(
            children:[
              Container(
                  decoration: BoxDecoration(image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(Constants.backgroundImage,)),

                  )
              ),
              Center(
                child: Container(

                  padding: const EdgeInsets.all(32.0),
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white
                    ,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Text(
                      //   'Login',
                      //   style: TextStyle(
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.white,
                      //   ),
                      // ),
                      Padding(
                        padding:  EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width/5),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              //  borderRadius: BorderRadius.circular(200),
                              image: DecorationImage(
                                image: AssetImage(Constants.logo),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(5),
                          child: TextField(
                            style: Styles.textStyleSmall,

                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                            controller: _controller,
                            decoration:  InputDecoration(
                              labelText: 'الرقم السري..',
                              labelStyle: TextStyle(fontSize: Constants.deviceWidth/22),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(

                                  borderRadius: BorderRadius.all(Radius.circular(5))),
                            ),
                            obscureText: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'تسجيل الدخول',
                                style: TextStyle(fontSize: Constants.deviceWidth/20,color: Colors.white,fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          )

    );
  }
}