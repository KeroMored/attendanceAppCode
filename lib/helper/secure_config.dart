import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SecureConfig {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for secure storage
  static const String _projectIdKey = 'appwrite_project_id';
  static const String _endpointKey = 'appwrite_endpoint';
  static const String _databaseIdKey = 'appwrite_database_id';
  static const String _studentsCollectionKey = 'students_collection_id';
  static const String _meetingsCollectionKey = 'meetings_collection_id';
  static const String _notificationsCollectionKey = 'notifications_collection_id';
  static const String _servicesCollectionKey = 'services_collection_id';
  static const String _bucketIdKey = 'bucket_id';
  static const String _userSessionKey = 'user_session';
  static const String _appSignatureKey = 'app_signature';

  // Initialize with encrypted credentials
  static Future<void> initialize() async {
    await _verifyAppIntegrity();
    await _setupSecureCredentials();
  }

  // Verify app signature to detect tampering
  static Future<bool> _verifyAppIntegrity() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final expectedSignature = await _storage.read(key: _appSignatureKey);
      
      if (expectedSignature == null) {
        // First run - store the signature
        final currentSignature = _generateAppSignature(packageInfo);
        await _storage.write(key: _appSignatureKey, value: currentSignature);
        return true;
      }
      
      final currentSignature = _generateAppSignature(packageInfo);
      if (currentSignature != expectedSignature) {
        throw Exception('App integrity check failed - possible tampering detected');
      }
      
      return true;
    } catch (e) {
      throw Exception('Security verification failed: $e');
    }
  }

  static String _generateAppSignature(PackageInfo packageInfo) {
    final data = '${packageInfo.packageName}${packageInfo.version}${packageInfo.buildNumber}';
    return sha256.convert(utf8.encode(data)).toString();
  }

  // Setup secure credentials - configured once on first run
  static Future<void> _setupSecureCredentials() async {
    try {
      final projectId = await _storage.read(key: _projectIdKey);
      if (projectId == null) {
        print('🔐 First run detected - configuring credentials from secure source...');
        
        // **TEMPORARY SOLUTION**: Auto-configure on first run
        // TODO: Replace this with secure credential fetching in production
        await _configureFromSecureSource();
        
        print('✅ Secure credentials configured on first run');
      } else {
        print('✅ Secure credentials already exist and loaded');
      }
    } catch (e) {
      print('⚠️ Error loading secure credentials: $e');
      throw e;
    }
  }

  // Configure credentials from external secure source (NO hardcoded values)
  static Future<void> _configureFromSecureSource() async {
    throw Exception('''
🔐 SECURITY SETUP REQUIRED 🔐

Your app needs to be configured with Appwrite credentials.
Choose one of these secure methods:

1. **FIRST-TIME SETUP**: Call this method from your main() function:
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Configure credentials ONCE (only on first install)
     await SecureConfig.configureCredentials(
       projectId: 'YOUR_PROJECT_ID',
       endpoint: 'https://cloud.appwrite.io/v1',
       databaseId: 'YOUR_DATABASE_ID', 
       studentsCollectionId: 'YOUR_STUDENTS_COLLECTION_ID',
       meetingsCollectionId: 'YOUR_MEETINGS_COLLECTION_ID',
       notificationsCollectionId: 'YOUR_NOTIFICATIONS_COLLECTION_ID',
       servicesCollectionId: 'YOUR_SERVICES_COLLECTION_ID',
       bucketId: 'YOUR_BUCKET_ID',
     );
     
     runApp(MyApp());
   }

2. **PRODUCTION**: Use environment variables or remote config

This ensures NO credentials are stored in your source code!
    ''');
  }

  // Method to configure credentials securely (call this once during setup)
  static Future<void> configureCredentials({
    required String projectId,
    required String endpoint,
    required String databaseId,
    required String studentsCollectionId,
    required String meetingsCollectionId,
    required String notificationsCollectionId,
    required String servicesCollectionId,
    required String bucketId,
  }) async {
    try {
      print('🔐 Configuring secure credentials...');
      
      await _storage.write(key: _projectIdKey, value: projectId);
      await _storage.write(key: _endpointKey, value: endpoint);
      await _storage.write(key: _databaseIdKey, value: databaseId);
      await _storage.write(key: _studentsCollectionKey, value: studentsCollectionId);
      await _storage.write(key: _meetingsCollectionKey, value: meetingsCollectionId);
      await _storage.write(key: _notificationsCollectionKey, value: notificationsCollectionId);
      await _storage.write(key: _servicesCollectionKey, value: servicesCollectionId);
      await _storage.write(key: _bucketIdKey, value: bucketId);
      
      print('✅ Secure credentials configured successfully');
    } catch (e) {
      print('❌ Failed to configure credentials: $e');
      throw e;
    }
  }

  // Secure getters
  static Future<String> getProjectId() async {
    final value = await _storage.read(key: _projectIdKey);
    if (value == null) {
      throw Exception('Project ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getEndpoint() async {
    final value = await _storage.read(key: _endpointKey);
    if (value == null) {
      throw Exception('Endpoint not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getDatabaseId() async {
    final value = await _storage.read(key: _databaseIdKey);
    if (value == null) {
      throw Exception('Database ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getStudentsCollectionId() async {
    final value = await _storage.read(key: _studentsCollectionKey);
    if (value == null) {
      throw Exception('Students Collection ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getMeetingsCollectionId() async {
    final value = await _storage.read(key: _meetingsCollectionKey);
    if (value == null) {
      throw Exception('Meetings Collection ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getNotificationsCollectionId() async {
    final value = await _storage.read(key: _notificationsCollectionKey);
    if (value == null) {
      throw Exception('Notifications Collection ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getServicesCollectionId() async {
    final value = await _storage.read(key: _servicesCollectionKey);
    if (value == null) {
      throw Exception('Services Collection ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  static Future<String> getBucketId() async {
    final value = await _storage.read(key: _bucketIdKey);
    if (value == null) {
      throw Exception('Bucket ID not configured. Run SecureConfig.configureCredentials() first.');
    }
    return value;
  }

  // Session management
  static Future<void> saveUserSession(String sessionId, String userId) async {
    final sessionData = {
      'sessionId': sessionId,
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _storage.write(key: _userSessionKey, value: jsonEncode(sessionData));
  }

  static Future<Map<String, dynamic>?> getUserSession() async {
    final sessionJson = await _storage.read(key: _userSessionKey);
    if (sessionJson == null) return null;
    
    try {
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final timestamp = sessionData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Session expires after 24 hours
      if (now - timestamp > 24 * 60 * 60 * 1000) {
        await clearUserSession();
        return null;
      }
      
      return sessionData;
    } catch (e) {
      await clearUserSession();
      return null;
    }
  }

  static Future<void> clearUserSession() async {
    await _storage.delete(key: _userSessionKey);
  }

  // Secure password handling (for migration period only)
  static Future<void> storeTemporaryClassData(String classId, String className) async {
    final classData = {
      'classId': classId,
      'className': className,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _storage.write(key: 'temp_class_data', value: jsonEncode(classData));
  }

  static Future<Map<String, dynamic>?> getTemporaryClassData() async {
    final classJson = await _storage.read(key: 'temp_class_data');
    if (classJson == null) return null;
    return jsonDecode(classJson) as Map<String, dynamic>;
  }

  static Future<void> clearTemporaryClassData() async {
    await _storage.delete(key: 'temp_class_data');
  }

  // Clear all secure data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}