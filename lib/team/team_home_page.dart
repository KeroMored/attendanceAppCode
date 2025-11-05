import 'package:attendance/team/player_of_the_month.dart';
import 'package:attendance/team/team_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/secure_appwrite_service.dart';
import 'instructions_page.dart';

class TeamHomePage extends StatefulWidget {
  final String studentId;
  const TeamHomePage({super.key, required this.studentId});

  @override
  State<TeamHomePage> createState() => _TeamHomePageState();
}

class _TeamHomePageState extends State<TeamHomePage> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    // Clear stored password-based credentials
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('teamPassword');
    await prefs.remove('teamStudentId');
    
    // Clear secure session
    await SecureAppwriteService.logout();
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
               );
            },
            child: Text("رجوع", style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Colors.white)),
          ),
        ],
        leading: IconButton(onPressed: _logout, icon: Icon(Icons.logout,color: Colors.white,)),
        title: Text('التشكيلة', style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.white,
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[

          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
         // BottomNavigationBarItem(icon: Icon(Icons.group), label: 'اللعيبة'),

          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'تعليمات'),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return PlayerOfTheMonth(studentId: widget.studentId);
      case 1:
      // //return StudentProfile(studentId: widget.studentId);
      //  return DisplayPlayers(widget.studentId);
      // case 2:
        return InstructionsPage();

      default:
        return TeamPage(studentId: widget.studentId);
    }
  }
}


