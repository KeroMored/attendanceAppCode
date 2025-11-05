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
      
      // Add your password "469369219" to the database
      // You can set it as either user or admin password
      await SecureAppwriteService.addPasswordToDatabase(
        className: 'فصل الألحان', // Replace with your class name
        userPassword: '469369219',    // As user password
        adminPassword: '469369219',   // Also as admin password (if needed)
      );
      
      print('✅ Setup completed successfully!');
      print('📋 How to use:');
      print('  1. Password "469369219" → Works as both user and admin');
      print('  2. Super admin passwords → "15234679!@#" or "469369219"');
      print('  3. All passwords are now stored securely in database');
      
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