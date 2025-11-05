// import 'package:attendace/HomePage.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_localization/flutter_localization.dart';
//
// void main() async{
//
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//
//       debugShowCheckedModeBanner: false,
//
//       title: 'Flutter Demo',
//
//       home: const Homepage(),
//     );
//   }
// }
import 'package:attendance/Splash/data/presentation/views/splash_view.dart';
import 'package:flutter/services.dart';

import 'helper/secure_appwrite_service.dart';
import 'helper/secure_config.dart';  // Add this import for one-time setup
import 'helper/constants.dart';
import 'helper/notification_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
  
    // **ONE-TIME PASSWORD SETUP** - Delete this entire block after first run!
    
    // Initialize secure Appwrite services
    await SecureAppwriteService.initialize();
    
    // **ADD YOUR PASSWORD TO DATABASE (RUN ONCE ONLY)**
    // Uncomment and run once, then comment out or delete:
    /*
    await SecureAppwriteService.addPasswordToDatabase(
      className: 'كنيسة العذراء الصاغة',
      userPassword: '469369219',    // Your password as user
      adminPassword: '469369219',   // Your password as admin  
    );
    print('✅ Password 469369219 added to database!');
    */
    
    // Initialize notifications
    await NotificationService.initialize();
    await NotificationService.scheduleDailyVerse();
  } catch (e) {
    // Handle initialization errors gracefully
    print('Failed to initialize app: $e');
    // In production, you might want to show an error screen
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  runApp(MyApp());
  //  runApp(
  //    DevicePreview(builder: (context) {
  //      return
  //      MyApp();
  //    },)
  
  //  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  // WidgetsBinding.instance.addPostFrameCallback((_) {
      Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
 //});
    // return ScreenUtilInit(
    //   designSize: const Size(360, 690),
    //   minTextAdapt: true,
    //   splitScreenMode: true,
    //   child:
    return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "كنيسة العذراء الصاغة",
      
        //    home:AddClasses() ,
            home:
            // Container(
            //   decoration: BoxDecoration(image: DecorationImage(image: AssetImage(Constants.backgroundImage))),
            //
            //   child: SplashView(),),

            SplashView() ,
            //(!Constants.usersPasswords.contains([password]))? LoginPage():Homepage(pass: password),
      
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,

        appBarTheme: AppBarTheme(
          toolbarHeight: MediaQuery.of(context).size.height/12,
          backgroundColor: Color(0xffbcf1ff),

          // toolbarHeight: Constants.deviceHeight/13
        ),
        listTileTheme: ListTileThemeData(
          iconColor: Colors.white,
      
        ),
        iconButtonTheme: IconButtonThemeData(

          style: ButtonStyle(
            iconSize:WidgetStateProperty.all(MediaQuery.of(context).size.width/20)
          )
        ),
        iconTheme: IconThemeData(
          size: Constants.deviceWidth
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: Constants.deviceWidth/20),
      
        )
      ),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('ar', ''), // العربية
              const Locale('en', ''), // الإنجليزية
            ],
            locale:Locale('ar', '') ,
          //),
    );
  }
}