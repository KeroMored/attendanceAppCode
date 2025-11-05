import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import 'secure_config.dart';

class AppwriteServices {
  // Static fields that will be populated from secure storage
  static String projectId = '';
  static String endPointId = '';
  static String databaseId = '';
  static String studentsCollectionId = '';
  static String meetingsCollectionId = '';
  static String notificationsCollectionId = '';
  static String servicesCollectionId = '';
  static String bucketId = '';
  
  // Keep these static for collections that are not sensitive or used frequently
  static const String fielsDataCollectionId = "67d59c1c00237d0aa7ce";
  static const String playersOfStudentCollectionId = "685be6e80002426dc626";
  static const String teachersCollectionId = "teachers"; // Teachers collection ID
  static const String lessonsCollectionId = "lessons"; // Lessons collection ID - CHANGE THIS TO YOUR ACTUAL LESSONS COLLECTION ID
  static const String eftekedCollectionId = "eftekad"; // Eftekad collection ID - CHANGE THIS TO YOUR ACTUAL EFTEKAD COLLECTION ID
  static const String quizzesCollectionId = "quizzes"; // Quizzes collection ID
  static const String questionsCollectionId = "questions"; // Questions collection ID
  static const String quizResultsCollectionId = "quiz_results"; // Quiz Results collection ID
  static const String prayCollectionId = "pray"; // Pray collection ID
  static const String prayResultsCollectionId = "pray_results"; // Pray Results collection ID
  static const String studentImagesBucketId = "68d43f8400191d39dbf8";


static Future<void> init() async {
  try {
    // Ensure SecureConfig is initialized first
    await SecureConfig.initialize();
    
    // Load secure credentials into static fields
    projectId = await SecureConfig.getProjectId();
    endPointId = await SecureConfig.getEndpoint();
    databaseId = await SecureConfig.getDatabaseId();
    studentsCollectionId = await SecureConfig.getStudentsCollectionId();
    meetingsCollectionId = await SecureConfig.getMeetingsCollectionId();
    notificationsCollectionId = await SecureConfig.getNotificationsCollectionId();
    servicesCollectionId = await SecureConfig.getServicesCollectionId();
    bucketId = await SecureConfig.getBucketId();
    
    Client client = Client();
    client.setEndpoint(endPointId).setProject(projectId);
    final Databases databases = Databases(client);
    final Storage storage = Storage(client);
    
    // Only register if not already registered (avoid conflicts with SecureAppwriteService)
    if (!GetIt.I.isRegistered<Databases>()) {
      GetIt.I.registerSingleton(databases);
    }
    if (!GetIt.I.isRegistered<Storage>()) {
      GetIt.I.registerSingleton(storage);
    }
  } catch (e) {
    throw Exception('Failed to initialize Appwrite services: $e');
  }
}

}
