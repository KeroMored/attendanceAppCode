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
    // **CONFIGURE CREDENTIALS ON FIRST RUN**
    // Note: Project ID is safe to be in code (it's public information)
    // Only API Secret Keys should be kept secret (not used in client apps)
    await SecureConfig.configureCredentials(
      projectId: '67c77998000b1b070682',  // Safe: Public identifier
      endpoint: 'https://cloud.appwrite.io/v1',  // Safe: Public endpoint
      databaseId: '67c789c1000c4f0c27b1',  // Safe: Public identifier
      studentsCollectionId: '67d59b730034fd6feb10',  // Safe: Public identifier
      meetingsCollectionId: '67d59b88002258394e79',   // Safe: Public identifier
      notificationsCollectionId: '67d59b5a00177df4b26b',  // Safe: Public identifier
      servicesCollectionId: '67d59c2400245feef83f',  // Safe: Public identifier
      bucketId: '67cb0d9c00141ced8e90',  // Safe: Public identifier
    );
    
    // Initialize secure Appwrite services
    await SecureAppwriteService.initialize();
    
    // ❌ REMOVED: addPasswordToDatabase call
    // Code 469369219 is now hardcoded in SecureAppwriteService.authenticateWithPassword
    // It does NOT need to be in the database and will NOT create any class
    // This code is special - it only grants access to AddClasses page
    
    // Initialize notifications    
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