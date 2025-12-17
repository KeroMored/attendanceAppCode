import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../helper/styles.dart';
import '../helper/offline_manager.dart';
import 'attendars_for_meeting.dart';

class MeetingDetailsOffline extends StatefulWidget {
  final String meetingId;

  const MeetingDetailsOffline({super.key, required this.meetingId});

  @override
  _MeetingDetailsOfflineState createState() => _MeetingDetailsOfflineState();
}

class _MeetingDetailsOfflineState extends State<MeetingDetailsOffline> {
  Map<String, dynamic>? meetingData;
  bool isLoading = true;
  List<dynamic> students = [];
  List<String> offlineAttendance = [];
  int pendingSyncCount = 0;
  bool _canScan = true;
  bool _loadForScan = false;
  double _syncProgress = 0.0;
  String _syncProgressText = '';
  Timer? _scanCooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
    // Removed automatic sync timer
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    // Removed sync timer cleanup since we're not using it anymore
    super.dispose();
  }

  // Removed _startPeriodicSync method since we don't need automatic sync

  Future<void> _loadOfflineData() async {
    try {
      offlineAttendance = await OfflineManager.getOfflineAttendance(widget.meetingId);
      pendingSyncCount = await OfflineManager.getPendingSyncCount();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading offline data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveOfflineAttendance(String studentId) async {
    try {
      final success = await OfflineManager.saveOfflineAttendance(widget.meetingId, studentId);
      
      if (success) {
        // Update local state
        if (!offlineAttendance.contains(studentId)) {
          offlineAttendance.add(studentId);
        }
        
        pendingSyncCount = await OfflineManager.getPendingSyncCount();
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
            content: Center(
              child: Text(
                'تم حفظ الحضور محلياً',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
            content: Center(
              child: Text(
                'تم تسجيل الحضور مسبقاً',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving offline attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              'خطأ في حفظ البيانات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _manualSync() async {
    // Check if there's any data to sync
    if (pendingSyncCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
          content: Center(
            child: Text(
              'لا توجد بيانات للمزامنة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      return;
    }

    // Check connectivity first
    final isConnected = await OfflineManager.isConnected();
    
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'لا يوجد اتصال بالإنترنت، يرجى المحاولة مرة أخرى',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Show sync in progress
    setState(() {
      _loadForScan = true; // Use existing loading state
    });

    try {
      await _syncOfflineData();
    } catch (e) {
      print('Manual sync failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'فشل في المزامنة، يرجى المحاولة مرة أخرى',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadForScan = false;
          _syncProgress = 0.0;
          _syncProgressText = '';
        });
      }
    }
  }

  Future<void> _syncOfflineData() async {
    try {
      final allOfflineData = await OfflineManager.getAllOfflineAttendance();
      
      if (allOfflineData.isEmpty) {
        pendingSyncCount = 0;
        setState(() {});
        return;
      }

      // Calculate total students for progress tracking
      int totalStudents = 0;
      for (List<String> attendanceList in allOfflineData.values) {
        totalStudents += attendanceList.length;
      }

      int syncedCount = 0;
      int failedCount = 0;
      int skippedCount = 0;
      int processedStudents = 0;
      List<String> failedMeetings = [];
      
      // Initialize progress
      setState(() {
        _syncProgress = 0.0;
        _syncProgressText = 'بدء المزامنة...';
      });
      
      // Process each meeting separately for better performance
      for (String meetingId in allOfflineData.keys) {
        final attendanceList = allOfflineData[meetingId]!;
        
        setState(() {
          _syncProgressText = 'معالجة الاجتماع (${attendanceList.length} طالب)';
        });
        
        try {
          final result = await _syncMeetingAttendanceBatch(
            meetingId, 
            attendanceList,
            (progress, text) {
              // Update progress during batch processing
              double currentProgress = (processedStudents + (progress * attendanceList.length)) / totalStudents;
              setState(() {
                _syncProgress = currentProgress;
                _syncProgressText = text;
              });
            }
          );
          
          syncedCount += result['synced']!;
          skippedCount += result['skipped']!;
          failedCount += result['failed']!;
          processedStudents += attendanceList.length;
          
          // Update progress after meeting completion
          setState(() {
            _syncProgress = processedStudents / totalStudents;
            _syncProgressText = 'مكتمل: ${((_syncProgress * 100).round())}%';
          });
          
          // Clear data only if no failures occurred
          if (result['failed'] == 0) {
            await OfflineManager.clearOfflineAttendanceAfterSuccessfulSync(meetingId);
          } else {
            failedMeetings.add(meetingId);
          }
        } catch (e) {
          print('Error syncing meeting $meetingId: $e');
          failedMeetings.add(meetingId);
          failedCount += attendanceList.length;
          processedStudents += attendanceList.length;
          
          setState(() {
            _syncProgress = processedStudents / totalStudents;
            _syncProgressText = 'خطأ في معالجة الاجتماع';
          });
        }
      }
      
      // Final progress update
      setState(() {
        _syncProgress = 1.0;
        _syncProgressText = 'اكتمال المزامنة - جاري التحديث...';
      });
      
      // Update last sync time if we had some success
      if (syncedCount > 0 || skippedCount > 0) {
        await OfflineManager.updateLastSyncTime();
      }
      
      // Reload offline data to get current state
      await _loadOfflineData();
      
      // Show results using the existing success/failure message logic
      if (mounted) {
        if (syncedCount > 0 && failedCount == 0) {
          // Complete success
          String message = 'تم مزامنة جميع البيانات بنجاح ($syncedCount سجل)';
          if (skippedCount > 0) {
            message += '\nتم تخطي $skippedCount طالب من صفوف أخرى';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (syncedCount > 0 && failedCount > 0) {
          // Partial success
          String message = 'تم مزامنة $syncedCount سجل، فشل في $failedCount سجل';
          if (skippedCount > 0) {
            message += '\nتم تخطي $skippedCount طالب من صفوف أخرى';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Complete failure or only skipped students
          String message;
          Color backgroundColor;
          IconData iconData;
          
          if (skippedCount > 0 && syncedCount == 0 && failedCount == 0) {
            message = 'تم تخطي جميع الطلاب ($skippedCount طالب من صفوف أخرى)';
            backgroundColor = Colors.blue;
            iconData = Icons.info;
          } else {
            message = 'فشل في مزامنة البيانات، يرجى المحاولة مرة أخرى';
            backgroundColor = Colors.red;
            iconData = Icons.error;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 3),
              backgroundColor: backgroundColor,
              content: Row(
                children: [
                  Icon(iconData, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      
    } catch (e) {
      print('Error syncing offline data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'خطأ في المزامنة، يرجى التحقق من الاتصال والمحاولة مرة أخرى',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  // New optimized batch sync method
  Future<Map<String, int>> _syncMeetingAttendanceBatch(
    String meetingId, 
    List<String> studentIds,
    [Function(double, String)? progressCallback]
  ) async {
    final databases = GetIt.I<Databases>();
    
    int syncedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    
    print('Starting batch sync for meeting $meetingId with ${studentIds.length} students');
    
    progressCallback?.call(0.0, 'جلب بيانات الاجتماع...');
    
    try {
      // 1. Fetch meeting data once (not for each student)
      final meetingDocument = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.meetingsCollectionId,
        documentId: meetingId,
      );
      
      final meetingType = meetingDocument.data['Type'];
      List<dynamic> currentMeetingStudents = meetingDocument.data['students'] ?? [];
      print('Meeting type: $meetingType, Currently has ${currentMeetingStudents.length} students');
      
      progressCallback?.call(0.1, 'جلب بيانات الطلاب...');
      
      // 2. Batch fetch all student documents at once
      List<Document> studentDocuments = [];
      List<String> validStudentIds = [];
      
      // Split into smaller chunks to avoid query limits (Appwrite has a limit of ~25 items per query for IN operations)
      const int chunkSize = 25;
      print('Processing ${studentIds.length} students in chunks of $chunkSize');
      
      int totalChunks = (studentIds.length / chunkSize).ceil();
      
      for (int i = 0; i < studentIds.length; i += chunkSize) {
        final chunk = studentIds.skip(i).take(chunkSize).toList();
        int currentChunk = (i / chunkSize).floor() + 1;
        
        progressCallback?.call(0.1 + (currentChunk / totalChunks) * 0.4, 'معالجة مجموعة $currentChunk من $totalChunks...');
        
        print('Processing chunk $currentChunk: ${chunk.length} students');
        
        try {
          final studentDocs = await databases.listDocuments(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            queries: [
              Query.equal('\$id', chunk),
              Query.equal('classId', Constants.classId), // Filter by class at query level
            ],
          );
          
          print('Found ${studentDocs.documents.length} valid students in this chunk');
          studentDocuments.addAll(studentDocs.documents);
          validStudentIds.addAll(studentDocs.documents.map((doc) => doc.$id));
        } catch (e) {
          print('Error fetching student chunk: $e');
          failedCount += chunk.length;
        }
      }
      
      print('Total valid students found: ${validStudentIds.length}');
      
      progressCallback?.call(0.5, 'معالجة بيانات الحضور...');
      
      // Count skipped students (those not in valid class)
      skippedCount = studentIds.length - validStudentIds.length - failedCount;
      
      // 3. Process valid students in batch
      List<String> newStudentIds = [];
      List<Map<String, dynamic>> studentUpdates = [];
      
      print('Processing ${studentDocuments.length} valid students for attendance');
      
      for (final studentDoc in studentDocuments) {
        final studentId = studentDoc.$id;
        
        // Check if student is already in meeting
        bool studentExists = currentMeetingStudents.any((student) {
          if (student is String) return student == studentId;
          if (student is Map) return student['\$id'] == studentId;
          return false;
        });
        
        if (!studentExists) {
          newStudentIds.add(studentId);
          
          // Prepare student counter update
          int newTotalCounter = (studentDoc.data["totalCounter"] ?? 0) + 1;
          Map<String, dynamic> updateData = {'totalCounter': newTotalCounter};
          
          // Add coins calculation for specific class
          // if (Constants.classId == "681f72c87215111b670e") {
          //   int currentCoins = studentDoc.data["totalCoins"] ?? 0;
          //   int coinsToAdd = 0;
            
          //   switch (meetingType) {
          //     case "حصة الألحان":
          //       coinsToAdd = 5;
          //       break;
          //     case "قداس":
          //       coinsToAdd = 10;
          //       break;
          //     case "تسبحة":
          //       coinsToAdd = 8;
          //       break;
          //   }
            
          //   updateData['totalCoins'] = currentCoins + coinsToAdd;
          // }
          
          studentUpdates.add({
            'studentId': studentId,
            'updateData': updateData,
          });
        } else {
          print('Student $studentId already exists in meeting, skipping');
        }
      }
      
      print('Found ${newStudentIds.length} new students to add to meeting');
      
      // 4. Batch update meeting document (if there are new students)
      if (newStudentIds.isNotEmpty) {
        progressCallback?.call(0.7, 'تحديث بيانات الاجتماع...');
        print('Adding ${newStudentIds.length} new students to meeting');
        currentMeetingStudents.addAll(newStudentIds);
        
        await databases.updateDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.meetingsCollectionId,
          documentId: meetingId,
          data: {
            'students': currentMeetingStudents,
          },
        );
        print('✅ Meeting document updated successfully');
      } else {
        print('No new students to add to meeting');
      }
      
      // 5. Batch update student documents
      print('Updating ${studentUpdates.length} student records');
      progressCallback?.call(0.8, 'تحديث بيانات الطلاب...');
      
      for (int i = 0; i < studentUpdates.length; i++) {
        final update = studentUpdates[i];
        
        // Update progress for each student update
        if (i % 5 == 0 || i == studentUpdates.length - 1) {
          double updateProgress = 0.8 + (i / studentUpdates.length) * 0.2;
          progressCallback?.call(updateProgress, 'تحديث الطالب ${i + 1} من ${studentUpdates.length}...');
        }
        
        try {
          await databases.updateDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            documentId: update['studentId'],
            data: update['updateData'],
          );
          syncedCount++;
          print('✅ Updated student: ${update['studentId']}');
        } catch (e) {
          print('❌ Error updating student ${update['studentId']}: $e');
          failedCount++;
        }
      }
      
      progressCallback?.call(1.0, 'اكتمال معالجة الاجتماع');
      print('Batch sync completed - Synced: $syncedCount, Skipped: $skippedCount, Failed: $failedCount');
      
    } catch (e) {
      print('❌ Error in batch sync for meeting $meetingId: $e');
      failedCount += studentIds.length - syncedCount - skippedCount;
    }
    
    return {
      'synced': syncedCount,
      'skipped': skippedCount,
      'failed': failedCount,
    };
  }

  Future<void> submitForm(String studentRef) async {
    setState(() {
      _canScan = false;
      _loadForScan = true;
    });

    try {
      await _saveOfflineAttendance(studentRef);
    } catch (e) {
      print('Error in submitForm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              'خطأ في حفظ البيانات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _loadForScan = false;
    });

    _scanCooldownTimer?.cancel();
    _scanCooldownTimer = Timer(Duration(seconds: 2), () {
      setState(() {
        _canScan = true;
      });
    });
  }

  Future<void> _clearLocalData() async {
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'حذف البيانات المحلية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف جميع البيانات المحفوظة محلياً؟\nلن يتم استرداد هذه البيانات.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'حذف',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Show loading
        setState(() {
          _loadForScan = true;
        });

        // Clear all offline data
        final success = await OfflineManager.clearAllOfflineData();
        
        if (success) {
          // Update local state
          offlineAttendance.clear();
          pendingSyncCount = 0;
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تم حذف جميع البيانات المحلية بنجاح',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'فشل في حذف البيانات المحلية',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        print('Error clearing local data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'خطأ في حذف البيانات المحلية',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } finally {
        setState(() {
          _loadForScan = false;
          _syncProgress = 0.0;
          _syncProgressText = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return ModalProgressHUD(
      progressIndicator: _loadForScan 
        ? Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: _syncProgress > 0 ? _syncProgress : null,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _syncProgress > 0 ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Percentage Text
                  if (_syncProgress > 0)
                    Text(
                      '${(_syncProgress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  SizedBox(height: 8),
                  // Progress Description
                  Text(
                    _syncProgressText.isNotEmpty 
                      ? _syncProgressText 
                      : 'جاري التحميل...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : Center(
            child: SpinKitWaveSpinner(
              color: Colors.white,
              waveColor: Colors.white,
              trackColor: Colors.blueGrey,
            ),
          ),
      inAsyncCall: _loadForScan,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          actions: [
            // Clear local data button - only show if there's data to clear
            if (pendingSyncCount > 0)
              IconButton(
                icon: Icon(Icons.delete_sweep, color: Colors.white),
                onPressed: _clearLocalData,
                tooltip: 'حذف البيانات المحلية',
              ),
            // Sync button
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.sync, color: Colors.white),
                  if (pendingSyncCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingSyncCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _manualSync,
            ),
          ],
          backgroundColor: Colors.orange,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                "تسجيل الحضور (أوفلاين)",
                style: Styles.textStyleSmall.copyWith(color: Colors.white),
              ),
              if (pendingSyncCount > 0)
                Text(
                  "في انتظار المزامنة: $pendingSyncCount",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          leading: MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Status Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.orange[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Colors.orange[600],
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الوضع الأوفلاين',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            'سيتم حفظ الحضور محلياً ومزامنته عند توفر الاتصال',
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: Colors.orange[600],
                            ),
                          ),
                          if (offlineAttendance.isNotEmpty)
                            Text(
                              'محفوظ محلياً: ${offlineAttendance.length} طالب',
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // QR Scanner
              Container(
                height: screenWidth / 1.5,
                width: screenWidth / 1.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.orange, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: MobileScanner(
                    onDetect: (barcodes) {
                      if (_loadForScan == false && 
                          _canScan == true && 
                          barcodes.barcodes.isNotEmpty) {
                        final barcode = barcodes.barcodes.first.rawValue;
                        if (barcode != null) {
                          print('Scanned offline: $barcode');
                          submitForm(barcode);
                        }
                      }
                    },
                  ),
                ),
              ),
              
              // Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    // View Attendance Button
                    MaterialButton(
                      elevation: 3,
                      shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        borderSide: BorderSide(width: 1, color: Colors.orange),
                      ),
                      minWidth: screenWidth / 1.5,
                      height: screenHeight / 12,
                      color: Colors.orange,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendarsForMeeting(
                              meetingId: widget.meetingId,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "الحضور",
                        style: Styles.textStyleSmall.copyWith(color: Colors.white),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Manual Sync Button
                    if (pendingSyncCount > 0)
                      MaterialButton(
                        elevation: 3,
                        shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                          borderSide: BorderSide(width: 1, color: Colors.blue),
                        ),
                        minWidth: screenWidth / 1.5,
                        height: screenHeight / 14,
                        color: Colors.blue,
                        onPressed: _manualSync,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync, color: Colors.white, size: screenWidth * 0.05),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              "مزامنة البيانات",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Clear Local Data Button
                    if (pendingSyncCount > 0) ...[
                      SizedBox(height: screenHeight * 0.015),
                      MaterialButton(
                        elevation: 3,
                        shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                          borderSide: BorderSide(width: 1, color: Colors.red),
                        ),
                        minWidth: screenWidth / 1.5,
                        height: screenHeight / 16,
                        color: Colors.red[400],
                        onPressed: _clearLocalData,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_sweep, color: Colors.white, size: screenWidth * 0.045),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              "حذف البيانات المحلية",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
