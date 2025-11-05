# Flutter and Dart optimizations
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-dontwarn io.flutter.embedding.**

# Preserve Flutter engine
-keep class io.flutter.embedding.** { *; }

# Preserve Appwrite SDK
-keep class io.appwrite.** { *; }
-dontwarn io.appwrite.**

# Preserve security-sensitive classes
-keep class com.mored.attendanceApp.security.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom attributes
-keepattributes Signature,InnerClasses,EnclosingMethod

# Remove logging in release builds for security
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Obfuscate but preserve functionality
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Security: Remove stack traces in production
-keepattributes !SourceFile,!LineNumberTable

# Preserve security storage
-keep class androidx.security.** { *; }
-keep class javax.crypto.** { *; }

# Additional security measures
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*