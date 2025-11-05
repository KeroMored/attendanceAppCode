
import 'package:attendance/home_page.dart';
import 'package:attendance/Splash/data/presentation/views/widgets/sliding_text.dart';
import 'package:attendance/login_page.dart';
import 'package:attendance/classes/add_classes.dart';
import 'package:attendance/classes/super_admin_home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helper/secure_appwrite_service.dart';
import '../../../../../helper/connectivity_service.dart';
import '../../../../../helper/constants.dart';


class SplashViewBody extends StatefulWidget {
  const SplashViewBody({super.key});

  @override
  State<SplashViewBody> createState() => _SplashViewBodyState();
}

class _SplashViewBodyState extends State<SplashViewBody>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<Offset> slidingAnimation;
  late ConnectivityService _connectivityService;
  bool isConnected = true;
  
  @override
  void initState() {
    super.initState();
    initSlidingAnimation();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check connectivity first
      _connectivityService = ConnectivityService();
      await _connectivityService.checkConnectivity(context, _performSecureInitialization());
      
      if (_connectivityService.isConnected == false) {
        setState(() {
          isConnected = false;
        });
        _showNoConnectionDialog();
        return;
      }
      
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      _navigateToSecureLogin();
    }
  }

  Future<void> _performSecureInitialization() async {
    try {
      // Initialize secure Appwrite services
      await SecureAppwriteService.initialize();
      
      // Check SharedPreferences for saved password (like your original approach)
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('password');
      
      if (savedPassword != null && savedPassword.isNotEmpty) {
        // User has saved password - restore session like original
        Constants.passwordValue = savedPassword;
        
        // Restore Constants values from saved session
        final savedClassName = prefs.getString('className') ?? '';
        final savedClassId = prefs.getString('classId') ?? '';
        
        if (savedClassName.isNotEmpty && savedClassId.isNotEmpty) {
          Constants.className = savedClassName;
          Constants.classId = savedClassId;
        }
        
        // Restore Constants.isUser from SharedPreferences
        final savedIsUser = prefs.getBool('isUser');
        if (savedIsUser != null) {
          Constants.isUser = savedIsUser;
        } else {
          // Set Constants.isUser based on saved password type for backward compatibility
          if (savedPassword == "469369219" || savedPassword == "15234679!@#") {
            Constants.isUser = false; // Admin/SuperAdmin level
          } else {
            Constants.isUser = true; // Default to user for regular passwords
          }
        }
        
        await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
        
        // Check for special navigation passwords
        if (savedPassword == "469369219") {
          Constants.isUser = false; // Ensure admin access for class management
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddClasses()),
          );
        } else if (savedPassword == "15234679!@#") {
          Constants.isUser = false; // Ensure admin access for super admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuperAdminHomePage()),
          );
        } else {
          // Navigate to Homepage for regular passwords
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        }
      } else {
        // No saved password, go to login
        await Future.delayed(const Duration(seconds: 2));
        _navigateToSecureLogin();
      }
      
    } catch (e) {
      debugPrint('Initialization failed: $e');
      await Future.delayed(const Duration(seconds: 2));
      _navigateToSecureLogin();
    }
  }

  void _navigateToSecureLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('لا يوجد اتصال بالإنترنت'),
        content: const Text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry initialization
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }



  void initSlidingAnimation() {
    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    slidingAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
        .animate(animationController);
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    double screenWidth= MediaQuery.of(context).size.width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Padding(
          padding:  EdgeInsets.symmetric(horizontal: screenWidth/5),
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
        SizedBox(
          height: 4,
        ),
        SlidingText(slidingAnimation: slidingAnimation),
    if(!isConnected)
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20,),
              IconButton(
                  style: ButtonStyle(
                      backgroundColor:
                      WidgetStatePropertyAll(Colors.blueGrey)),
                  onPressed: () {
                    _connectivityService.checkConnectivity(
                        context, _performSecureInitialization());
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size:screenWidth/15,
                  )),
             // SizedBox(height:20 ),
              Text(
                "إعادة المحاولة",
                style: TextStyle(
                   fontSize:  screenWidth/20,fontFamily: "NotoSansArabic",
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        )
      ],
    );
  }
}