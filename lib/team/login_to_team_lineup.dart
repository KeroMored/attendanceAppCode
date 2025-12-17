// Team Login Page - Password Authentication
// Features:
// - Password-based authentication for team access
// - Auto-login using stored SharedPreferences (teamPassword, teamStudentId)
// - Faster login by avoiding unnecessary API loops
// - Proper session management with logout functionality
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../helper/styles.dart';
import 'team_home_page.dart';

class LoginToTeamLineup extends StatefulWidget {
  const LoginToTeamLineup({super.key});

  @override
  State<LoginToTeamLineup> createState() => _LoginToTeamLineupState();
}

class _LoginToTeamLineupState extends State<LoginToTeamLineup> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStoredCredentials();
  }

  Future<void> _checkStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('teamPassword') ?? '';
    final storedStudentId = prefs.getString('teamStudentId') ?? '';
    
    if (storedPassword.isNotEmpty && storedStudentId.isNotEmpty) {
      // Auto-login with stored credentials
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeamHomePage(studentId: storedStudentId),
        ),
      );
    }
  }

  Future<void> login() async {
    String enteredPassword = _controller.text.trim();

    if (enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('يرجى إدخال كلمة المرور'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      const int limit = 200;

      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          appwrite.Query.equal("classId", Constants.classId),
          appwrite.Query.limit(limit),
        ],
      );

      for (var doc in documents.documents) {
        var studentDataMap = doc.data;
        if (studentDataMap['password'] == enteredPassword) {
          // Store credentials for future auto-login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('teamPassword', enteredPassword);
          await prefs.setString('teamStudentId', doc.$id);
          
          // Password matches, navigate to TeamHomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeamHomePage(studentId: doc.$id),
            ),
          );
          return;
        }
      }

      // If no matching password was found
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('كلمة المرور غير صحيحة'),
        backgroundColor: Colors.red,
      ));

    } on appwrite.AppwriteException catch (e) {
      debugPrint('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ أثناء تسجيل الدخول'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage(Constants.team),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 5),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: AssetImage(Constants.coach),
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
                        decoration: InputDecoration(
                          labelText: 'الرقم السري للتشكيلة ..',
                          labelStyle: TextStyle(fontSize: Constants.deviceWidth / 22),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () {
                      login();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'تسجيل الدخول',
                      style: TextStyle(fontSize: Constants.deviceWidth / 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}