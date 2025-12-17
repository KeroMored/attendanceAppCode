import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineManager {
  static const String _offlinePrefix = 'offline_attendance_';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Save attendance record offline
  static Future<bool> saveOfflineAttendance(String meetingId, String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlinePrefix$meetingId';
      
      // Get existing data
      final existingDataJson = prefs.getString(key);
      List<String> attendanceList = [];
      
      if (existingDataJson != null) {
        final List<dynamic> existing = json.decode(existingDataJson);
        attendanceList = existing.cast<String>();
      }
      
      // Add new student if not already present
      if (!attendanceList.contains(studentId)) {
        attendanceList.add(studentId);
        
        // Save updated list
        final updatedJson = json.encode(attendanceList);
        await prefs.setString(key, updatedJson);
        
        return true;
      }
      
      return false; // Student already exists
    } catch (e) {
      debugPrint('Error saving offline attendance: $e');
      return false;
    }
  }

  // Get all offline attendance data
  static Future<Map<String, List<String>>> getAllOfflineAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final offlineKeys = allKeys.where((key) => key.startsWith(_offlinePrefix)).toList();
      
      Map<String, List<String>> offlineData = {};
      
      for (String key in offlineKeys) {
        final meetingId = key.replaceFirst(_offlinePrefix, '');
        final dataJson = prefs.getString(key);
        
        if (dataJson != null) {
          final List<dynamic> attendanceList = json.decode(dataJson);
          offlineData[meetingId] = attendanceList.cast<String>();
        }
      }
      
      return offlineData;
    } catch (e) {
      debugPrint('Error getting offline attendance: $e');
      return {};
    }
  }

  // Get offline attendance for specific meeting
  static Future<List<String>> getOfflineAttendance(String meetingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlinePrefix$meetingId';
      final dataJson = prefs.getString(key);
      
      if (dataJson != null) {
        final List<dynamic> attendanceList = json.decode(dataJson);
        return attendanceList.cast<String>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting offline attendance for meeting $meetingId: $e');
      return [];
    }
  }

  // Clear offline data for specific meeting only if sync was successful
  static Future<bool> clearOfflineAttendanceAfterSuccessfulSync(String meetingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlinePrefix$meetingId';
      final success = await prefs.remove(key);
      
      if (success) {
        await updateLastSyncTime();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error clearing offline attendance for meeting $meetingId: $e');
      return false;
    }
  }

  // Validate connectivity with retry mechanism
  static Future<bool> validateConnectivity({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.first != ConnectivityResult.none) {
          // Additional validation - try a simple network request
          return true;
        }
        
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1));
        }
      } catch (e) {
        debugPrint('Connectivity check attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }
    return false;
  }

  // Clear all offline data
  static Future<bool> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final offlineKeys = allKeys.where((key) => key.startsWith(_offlinePrefix)).toList();
      
      bool success = true;
      for (String key in offlineKeys) {
        final result = await prefs.remove(key);
        if (!result) success = false;
      }
      
      return success;
    } catch (e) {
      debugPrint('Error clearing all offline data: $e');
      return false;
    }
  }

  // Get total count of pending sync records
  static Future<int> getPendingSyncCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      return allKeys.where((key) => key.startsWith(_offlinePrefix)).length;
    } catch (e) {
      debugPrint('Error getting pending sync count: $e');
      return 0;
    }
  }

  // Check connectivity
  static Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Update last sync timestamp
  static Future<void> updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last sync time: $e');
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
      return null;
    }
  }

  // Get formatted last sync time string
  static Future<String> getLastSyncTimeString() async {
    final lastSync = await getLastSyncTime();
    
    if (lastSync == null) {
      return 'لم يتم المزامنة من قبل';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'تم المزامنة منذ قليل';
    } else if (difference.inHours < 1) {
      return 'تم المزامنة منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'تم المزامنة منذ ${difference.inHours} ساعة';
    } else {
      return 'تم المزامنة منذ ${difference.inDays} يوم';
    }
  }
}
