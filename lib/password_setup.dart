// One-time setup script to configure your passwords
// Run this once to add your password "469369219" to the database

import 'package:flutter/material.dart';
import 'helper/secure_appwrite_service.dart';

class PasswordSetup extends StatelessWidget {
  const PasswordSetup({Key? key}) : super(key: key);

  Future<void> _setupYourPasswords() async {
    try {
      print('🔧 Setting up your passwords...');
      
      // Initialize Appwrite first
      await SecureAppwriteService.initialize();
      
      // ❌ REMOVED: addPasswordToDatabase call
      // Code 469369219 is now hardcoded and doesn't need database entry
      // It grants access to AddClasses page only
      
     
      
    } catch (e) {
      print('❌ Setup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Password Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'تكوين كلمات المرور',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _setupYourPasswords();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تكوين كلمات المرور بنجاح')),
                  );
                }
              },
              child: Text('إعداد كلمات المرور'),
            ),
            SizedBox(height: 20),
            Text(
              'اضغط هنا مرة واحدة فقط لإضافة كلمة المرور\n"469369219"\nإلى قاعدة البيانات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}