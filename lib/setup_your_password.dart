// Quick setup - Add this to your main.dart temporarily
import 'package:attendance/helper/secure_appwrite_service.dart';

// Add this function to main.dart and call it once
Future<void> setupYourPassword() async {
  try {
    await SecureAppwriteService.initialize();
    
    // Add your password "469369219" to database
    await SecureAppwriteService.addPasswordToDatabase(
      className: 'كنيسة العذراء الصاغة',  // Your class name
      userPassword: '469369219',       // For regular users  
      adminPassword: '469369219',      // For admin access
    );
    
    print('✅ Password "469369219" added to database successfully!');
  } catch (e) {
    print('❌ Setup error: $e');
  }
}

// Call this in main() function ONCE:
// await setupYourPassword();