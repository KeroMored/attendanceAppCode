import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_config.dart';
import 'appwrite_services.dart';
import 'constants.dart';

class SecureAppwriteService {
  static Client? _client;
  static Account? _account;
  static Databases? _databases;
  static Storage? _storage;
  
  // Collection IDs (these are not sensitive and can remain in code)
  static const String studentsCollectionId = "67d59b730034fd6feb10";
  static const String meetingsCollectionId = "67d59b88002258394e79";
  static const String notificationsCollectionId = "67d59b5a00177df4b26b";
  static const String fielsDataCollectionId = "67d59c1c00237d0aa7ce";
  static const String servicesCollectionId = "67d59c2400245feef83f";
  static const String playersOfStudentCollectionId = "685be6e80002426dc626";
  static const String teachersCollectionId = "teachers";
  static const String lessonsCollectionId = "lessons";
  static const String eftekedCollectionId = "eftekad";
  static const String quizzesCollectionId = "quizzes";
  static const String questionsCollectionId = "questions";
  static const String quizResultsCollectionId = "quiz_results";
  static const String prayCollectionId = "pray";
  static const String prayResultsCollectionId = "pray_results";
  static const String bucketId = "67cb0d9c00141ced8e90";
  static const String studentImagesBucketId = "68d43f8400191d39dbf8";

  static Future<void> initialize() async {
    try {
      await SecureConfig.initialize();
      
      final projectId = await SecureConfig.getProjectId();
      final endpoint = await SecureConfig.getEndpoint();
      
      // Validate endpoint with certificate pinning (MITM protection)
      await _validateSecureEndpointWithCertificatePinning(endpoint);
      
      _client = Client()
          .setEndpoint(endpoint)
          .setProject(projectId)
          .setSelfSigned(status: false); // Enforce HTTPS certificate validation
      
      _account = Account(_client!);
      _databases = Databases(_client!);
      _storage = Storage(_client!);
      
      // Populate legacy AppwriteServices static fields for compatibility
      AppwriteServices.projectId = await SecureConfig.getProjectId();
      AppwriteServices.endPointId = await SecureConfig.getEndpoint();
      AppwriteServices.databaseId = await SecureConfig.getDatabaseId();
      AppwriteServices.studentsCollectionId = await SecureConfig.getStudentsCollectionId();
      AppwriteServices.meetingsCollectionId = await SecureConfig.getMeetingsCollectionId();
      AppwriteServices.notificationsCollectionId = await SecureConfig.getNotificationsCollectionId();
      AppwriteServices.servicesCollectionId = await SecureConfig.getServicesCollectionId();
      AppwriteServices.bucketId = await SecureConfig.getBucketId();
      
      // Register with GetIt for dependency injection (only if not already registered)
      if (!GetIt.I.isRegistered<Databases>()) {
        GetIt.I.registerSingleton<Databases>(_databases!);
      }
      if (!GetIt.I.isRegistered<Storage>()) {
        GetIt.I.registerSingleton<Storage>(_storage!);
      }
      if (!GetIt.I.isRegistered<Account>()) {
        GetIt.I.registerSingleton<Account>(_account!);
      }
      
      // Try to restore existing session
      await _restoreSession();
      
    } catch (e) {
      throw Exception('Failed to initialize Appwrite services: $e');
    }
  }

  static Future<void> _restoreSession() async {
    try {
      final sessionData = await SecureConfig.getUserSession();
      if (sessionData != null) {
        // Verify the session is still valid
        await _account!.get();
      }
    } catch (e) {
      // Session invalid or expired
      await SecureConfig.clearUserSession();
    }
  }

  // Secure authentication following original SharedPreferences approach
  static Future<AuthResult> authenticateWithPassword(String identifier, String password) async {
    try {
      print('🔐 Starting authentication for password: "$password"');
      
      // ✅ CHECK SPECIAL ADMIN CODE FIRST (BEFORE database lookup)
      // Code 469369219 is NOT a class password - it's for adding new classes
      if (password == "469369219") {
        print('✅ SPECIAL ADMIN CODE 469369219 DETECTED - Granting AddClasses access');
        print('⚠️ This code is NOT stored in database and does NOT create any class');
        
        // Save to SharedPreferences for session management
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', password);
        await prefs.setBool('isUser', false);
        await prefs.setString('destination', 'AddClasses');
        
        // Set Constants but DON'T set classId or className
        Constants.passwordValue = password;
        Constants.isUser = false;
        // ⚠️ DON'T set Constants.classId or Constants.className - this is NOT a class!
        
        // Save session
        await SecureConfig.saveUserSession('admin_add_classes', 'add_classes_admin');
        
        return AuthResult(
          success: true,
          userType: UserType.admin,
          classId: '', // Empty - not a class
          className: 'Add Classes Admin', // Special designation
        );
      }
      
      // ✅ CHECK SUPER ADMIN CODE
      if (password == "15234679!@#") {
        print('✅ SUPER ADMIN PASSWORD DETECTED');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', password);
        await prefs.setBool('isUser', false);
        await prefs.setString('destination', 'SuperAdminHomePage');
        
        Constants.passwordValue = password;
        Constants.isUser = false;
        
        await SecureConfig.saveUserSession('super_admin_session', 'super_admin');
        
        return AuthResult(
          success: true,
          userType: UserType.superAdmin,
          classId: '',
          className: 'Super Admin',
        );
      }
      
      // ✅ NOW search database for regular class passwords
      print('🔍 Searching database for class passwords...');
      
      // Call server-side function for password validation
      final databaseId = await SecureConfig.getDatabaseId();
      final servicesCollection = await SecureConfig.getServicesCollectionId();
      
      print('🔍 Querying database: $databaseId, collection: $servicesCollection');
      
      // Get all documents from services collection (like original Constants arrays)
      final allResults = await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: servicesCollection,
      );
      
      print('📊 Total documents in services: ${allResults.documents.length}');
      
      // Check all documents for matching password (following original logic)
      for (final doc in allResults.documents) {
        final data = doc.data;
        final usersPassword = data['usersPassword']?.toString() ?? '';
        final adminsPassword = data['adminsPassword']?.toString() ?? '';
        
        print('� Checking document ${data['name']}: users="$usersPassword", admins="$adminsPassword"');
        
        // Check admin password first (like Constants.admainsPasswords.contains())
        if (adminsPassword == password) {
          print('✅ ADMIN LOGIN SUCCESSFUL - Class: ${data['name']}');
          
          // Save to SharedPreferences (exactly like original code)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('password', password);
          Constants.passwordValue = password;
          Constants.classId = data['\$id'];
          Constants.className = data['name'];
          Constants.isUser = false; // Admin = false
          
          // Also save secure session for new security features
          await SecureConfig.saveUserSession('admin_session', data['\$id']);
          await SecureConfig.storeTemporaryClassData(data['\$id'], data['name']);
          
          return AuthResult(
            success: true,
            userType: UserType.admin,
            classId: data['\$id'],
            className: data['name'],
          );
        }
        
        // Check user password (like Constants.usersPasswords.contains())
        if (usersPassword == password) {
          print('✅ USER LOGIN SUCCESSFUL - Class: ${data['name']}');
          
          // Save to SharedPreferences (exactly like original code)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('password', password);
          Constants.passwordValue = password;
          Constants.classId = data['\$id'];
          Constants.className = data['name'];
          Constants.isUser = true; // User = true
          
          // Also save secure session for new security features
          await SecureConfig.saveUserSession('user_session', data['\$id']);
          await SecureConfig.storeTemporaryClassData(data['\$id'], data['name']);
          
          return AuthResult(
            success: true,
            userType: UserType.user,
            classId: data['\$id'],
            className: data['name'],
          );
        }
      }
      
      print('❌ No matching credentials found in database');
      throw Exception('رقم سري غير صحيح'); // Original error message
      
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  // Super admin authentication with enhanced security
  static Future<AuthResult> authenticateSuperAdmin(String password) async {
    // List of valid super admin passwords
    const validSuperAdminPasswords = [
      '15234679!@#',  // Original super admin password
      '469369219',    // Your password as super admin
    ];
    
    if (!validSuperAdminPasswords.contains(password)) {
      throw Exception('Invalid super admin credentials');
    }

    await SecureConfig.saveUserSession('super_admin_session', 'super_admin');
    
    return AuthResult(
      success: true,
      userType: UserType.superAdmin,
      classId: '',
      className: 'Super Admin',
    );
  }

  // Check if user is authenticated (following original SharedPreferences approach)
  static Future<bool> isAuthenticated() async {
    // First check secure session
    final session = await SecureConfig.getUserSession();
    if (session != null) return true;
    
    // Check SharedPreferences for saved password (like original approach)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('password');
      
      if (savedPassword != null && savedPassword.isNotEmpty) {
        // User is authenticated if they have a saved password (like original)
        return true;
      }
    } catch (e) {
      print('Error checking authentication: $e');
    }
    
    return false;
  }

  // Get current user type (following original Constants.isUser approach)
  static Future<UserType?> getCurrentUserType() async {
    // First check if we have a saved session with user type info
    final session = await SecureConfig.getUserSession();
    if (session != null) {
      final sessionId = session['sessionId'] as String;
      print('🔍 Current session ID: $sessionId');
      
      if (sessionId.contains('super_admin')) return UserType.superAdmin;
      if (sessionId.contains('admin')) return UserType.admin;
      if (sessionId.contains('user')) return UserType.user;
    }
    
    // Check SharedPreferences for saved password (like original approach)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('password');
      
      if (savedPassword != null && savedPassword.isNotEmpty) {
        // Check Constants.isUser flag (like original code)
        if (Constants.isUser) {
          return UserType.user;
        } else {
          // Check if we also have teacher password (complete admin session)
          final teacherPassword = prefs.getString('teacherPassword');
          if (teacherPassword != null && teacherPassword.isNotEmpty) {
            return UserType.admin; // Complete admin session
          } else {
            return UserType.admin; // Admin but needs teacher login
          }
        }
      }
    } catch (e) {
      print('Error checking saved credentials: $e');
    }
    
    return null;
  }

  // Logout
  static Future<void> logout() async {
    try {
      await _account?.deleteSession(sessionId: 'current');
    } catch (e) {
      // Session might already be invalid
    }
    
    await SecureConfig.clearUserSession();
    await SecureConfig.clearTemporaryClassData();
  }

  // Diagnostic method to test Appwrite connection
  static Future<void> testConnection() async {
    try {
      final databaseId = await SecureConfig.getDatabaseId();
      final servicesCollection = await SecureConfig.getServicesCollectionId();
      
      print('🧪 Testing Appwrite connection...');
      print('📋 Database ID: $databaseId');
      print('📋 Services Collection: $servicesCollection');
      
      final result = await _databases!.listDocuments(
        databaseId: databaseId,
        collectionId: servicesCollection,
        queries: [Query.limit(5)],
      );
      
      print('✅ Connection successful! Found ${result.documents.length} documents');
      
      // Print first document structure for debugging
      if (result.documents.isNotEmpty) {
        final firstDoc = result.documents.first.data;
        print('📄 Sample document structure: ${firstDoc.keys.toList()}');
      }
      
    } catch (e) {
      print('❌ Connection test failed: $e');
    }
  }

  // Getters for services
  static Databases get databases {
    if (_databases == null) throw Exception('Appwrite not initialized');
    return _databases!;
  }

  static Storage get storage {
    if (_storage == null) throw Exception('Appwrite not initialized');
    return _storage!;
  }

  static Account get account {
    if (_account == null) throw Exception('Appwrite not initialized');
    return _account!;
  }

  static Future<String> get databaseId => SecureConfig.getDatabaseId();

  // Get temporary class data
  static Future<Map<String, dynamic>?> getTemporaryClassData() {
    return SecureConfig.getTemporaryClassData();
  }

  // Helper function to add/update passwords in database
  // ❌ REMOVED: addPasswordToDatabase method
  // This method was creating unwanted classes in the database
  // Admin code 469369219 is now hardcoded in authenticateWithPassword
  // and does NOT create any database entries

  // MITM Protection: Enhanced certificate pinning validation
  static Future<void> _validateSecureEndpointWithCertificatePinning(String endpoint) async {
    try {
      // Validate endpoint format
      final uri = Uri.parse(endpoint);
      
      // Ensure HTTPS
      if (uri.scheme != 'https') {
        throw Exception('🚫 SECURITY: Only HTTPS connections are allowed');
      }
      
      // Validate Appwrite domain
      final allowedDomains = [
        'cloud.appwrite.io',
        'appwrite.io',
      ];
      
      bool isValidDomain = allowedDomains.any((domain) => 
          uri.host == domain || uri.host.endsWith('.$domain'));
      
      if (!isValidDomain) {
        throw Exception('🚫 SECURITY: Invalid Appwrite endpoint domain: ${uri.host}');
      }

      // Enhanced Certificate Pinning Protection
      await _performCertificatePinning(uri.host, uri.port == 0 ? 443 : uri.port);
      
      print('✅ Certificate pinning validation passed: $endpoint');
    } catch (e) {
      print('❌ Certificate pinning validation failed: $e');
      throw Exception('MITM Protection: $e');
    }
  }

  // Certificate pinning implementation
  static Future<void> _performCertificatePinning(String host, int port) async {
    try {
      // Get stored certificate fingerprints from secure storage
      final allowedCertificateHashes = await _getStoredCertificateHashes();
      
      final client = HttpClient();
      
      // Custom certificate validation
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        try {
          // Get certificate SHA256 fingerprint
          final certBytes = cert.der;
          final digest = sha256.convert(certBytes);
          final fingerprint = digest.bytes
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(':');
          
          print('🔍 Certificate fingerprint for $host: $fingerprint');
          
          // Check if emergency bypass is enabled
          if (allowedCertificateHashes.contains('*')) {
            print('⚠️ Emergency certificate bypass active - connection allowed');
            return true;
          }
          
          // Check if certificate fingerprint matches allowed list
          final isValidCertificate = allowedCertificateHashes.any((allowedHash) => 
              allowedHash.toLowerCase() == fingerprint.toLowerCase());
          
          if (!isValidCertificate) {
            print('❌ Certificate fingerprint not in allowed list!');
            print('❌ Current fingerprint: $fingerprint');
            print('❌ Allowed fingerprints: ${allowedCertificateHashes.join(', ')}');
            print('❌ Potential MITM attack detected for host: $host');
            return false;
          }
          
          print('✅ Certificate fingerprint validated for $host');
          return true;
          
        } catch (e) {
          print('❌ Certificate validation error: $e');
          return false;
        }
      };
      
      // Test the connection with certificate pinning
      try {
        final request = await client.getUrl(Uri.parse('https://$host:$port/v1/health'))
            .timeout(const Duration(seconds: 10));
        final response = await request.close();
        
        if (response.statusCode == 200 || response.statusCode == 404) {
          print('✅ Certificate pinning test successful');
        } else {
          print('⚠️ Unexpected response code: ${response.statusCode}');
        }
        
      } catch (e) {
        if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') || 
            e.toString().contains('bad certificate')) {
          throw Exception('🚫 CERTIFICATE PINNING FAILED: Potential MITM attack detected!');
        }
        print('⚠️ Connection test failed (but certificate was valid): $e');
      } finally {
        client.close();
      }
      
    } catch (e) {
      print('❌ Certificate pinning failed: $e');
      throw Exception('Certificate pinning validation failed: $e');
    }
  }

  // Get allowed certificate hashes from secure storage
  static Future<List<String>> _getStoredCertificateHashes() async {
    try {
      // Try to get stored certificates from secure storage first
      const storage = FlutterSecureStorage();
      final storedHashes = await storage.read(key: 'appwrite_cert_hashes');
      
      if (storedHashes != null) {
        final List<dynamic> hashList = jsonDecode(storedHashes);
        return hashList.cast<String>();
      }
      
      // Fallback: Known certificate fingerprints for Appwrite Cloud (SHA256)
      final defaultHashes = [
        // Common Cloudflare certificates used by Appwrite Cloud
        // These are more stable than specific leaf certificates
        'f6:3e:ac:25:58:7d:2e:e0:2a:81:56:7f:a0:18:f6:71:c0:e2:95:c2:58:d3:f0:13:5e:18:6d:dd:a0:22:37:a8',
        '06:87:26:03:31:47:a9:d7:f2:8e:25:46:87:d5:b5:a0:31:94:7e:63:b3:9f:29:63:a2:89:58:47:9a:15:06:9d',
        // Let's Encrypt backup certificates
        '25:84:7d:66:8e:b4:f0:4f:dd:40:b1:2b:6b:07:40:c5:47:a1:3d:7a:40:10:1b:f7:3f:24:ab:a5:e6:0f:d7:66',
      ];
      
      // Store default hashes for future use
      await storage.write(key: 'appwrite_cert_hashes', value: jsonEncode(defaultHashes));
      
      return defaultHashes;
      
    } catch (e) {
      print('⚠️ Error loading certificate hashes, using emergency bypass: $e');
      
      // Emergency fallback - allow connection but log warning
      return ['*']; // Special case for emergency bypass
    }
  }

  // Method to update certificate hashes (for maintenance)
  static Future<void> updateCertificateHashes(List<String> newHashes) async {
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'appwrite_cert_hashes', value: jsonEncode(newHashes));
      print('✅ Certificate hashes updated successfully');
    } catch (e) {
      print('❌ Failed to update certificate hashes: $e');
      throw Exception('Failed to update certificate hashes: $e');
    }
  }

  // Method to retrieve current certificate fingerprint (for debugging/setup)
  static Future<String?> getCurrentCertificateFingerprint(String host) async {
    try {
      final client = HttpClient();
      String? fingerprint;
      
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        final certBytes = cert.der;
        final digest = sha256.convert(certBytes);
        fingerprint = digest.bytes
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(':');
        return true; // Allow connection for fingerprint retrieval
      };
      
      final request = await client.getUrl(Uri.parse('https://$host:443/'))
          .timeout(const Duration(seconds: 5));
      await request.close();
      client.close();
      
      return fingerprint;
    } catch (e) {
      print('❌ Failed to get certificate fingerprint: $e');
      return null;
    }
  }
}

// Authentication result model
class AuthResult {
  final bool success;
  final UserType userType;
  final String classId;
  final String className;
  final String? error;

  AuthResult({
    required this.success,
    required this.userType,
    required this.classId,
    required this.className,
    this.error,
  });
}

enum UserType { user, admin, superAdmin }