import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:attendance/home_page.dart';
import 'package:attendance/meeting/add_meeting.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';
import 'online_or_offline.dart';

class DisplayMeetings extends StatefulWidget {
  const DisplayMeetings({super.key});

  @override
  State<DisplayMeetings> createState() => _DisplayMeetingsState();
}

class _DisplayMeetingsState extends State<DisplayMeetings> {
  bool isLoading = false;
  bool hasMoreData = true;
  List<Map<String, dynamic>> meetingsData = [];
  final int pageSize = 6; // Display 6 meetings per page
  late ConnectivityService _connectivityService;
  List<Map<String, dynamic>> studentsList = [];
  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.checkConnectivity(context, _getMeetingsData());
  }

  Future<void> _getStudentsDataAndReduceAndUpdate(String meetingId) async {
    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      // Get meeting data first
      print('Getting meeting data...');
      final meetingResponse = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.meetingsCollectionId,
        documentId: meetingId,
      );

      Map<String, dynamic> meetingData = meetingResponse.data;
     // String meetingType = meetingData['Type']?.toString() ?? '';
      List<dynamic> studentsArray = meetingData['students'] ?? [];

    //  print('Meeting type: $meetingType, Students count: ${studentsArray.length}');

      // Process each student one by one
      for (var studentItem in studentsArray) {
        try {
          // Get student ID - handle different formats
          String? studentId;
          if (studentItem is String) {
            studentId = studentItem;
          } else if (studentItem is Map) {
            studentId = studentItem['\$id']?.toString();
          }

          if (studentId == null || studentId.length < 10) {
            print('Skipping invalid student ID: $studentId');
            continue;
          }

          print('Processing student: $studentId');

          // Get student data
          final studentResponse = await databases.getDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            documentId: studentId,
          );

          Map<String, dynamic> studentData = studentResponse.data;
          
          // Check class membership
          String studentClassId = studentData['classId']["\$id"]?.toString() ?? '';
          if (studentClassId != Constants.classId) {
            print('Student not in current class, skipping');
            print(studentClassId);
            print(Constants.classId);
            continue;
          }

          // Get current values safely
          dynamic counterValue = studentData['totalCounter'];
         // dynamic coinsValue = studentData['totalCoins'];
          
          int currentCounter = 0;
         // int currentCoins = 0;
          
          // Convert counter
          if (counterValue is int) {
            currentCounter = counterValue;
          } else if (counterValue is double) {
            currentCounter = counterValue.toInt();
          } else if (counterValue is String) {
            currentCounter = int.tryParse(counterValue) ?? 0;
          }
          
          // // Convert coins
          // if (coinsValue is int) {
          //   currentCoins = coinsValue;
          // } else if (coinsValue is double) {
          //   currentCoins = coinsValue.toInt();
          // } else if (coinsValue is String) {
          //   currentCoins = int.tryParse(coinsValue) ?? 0;
          // }

          // Calculate new values
          int newCounter = currentCounter > 0 ? currentCounter - 1 : 0;
     //     int newCoins = currentCoins;

          // Apply coin deduction for specific class
          // if (Constants.classId == "681f72c87215111b670e") {
          //   switch (meetingType) {
          //     case "حصة الألحان":
          //       if (newCoins >= 5) newCoins -= 5;
          //       break;
          //     case "قداس":
          //       if (newCoins >= 10) newCoins -= 10;
          //       break;
          //     case "تسبحة":
          //       if (newCoins >= 8) newCoins -= 8;
          //       break;
          //     case "مدارس أحد":
          //       if (newCoins >= 3) newCoins -= 3;
          //       break;
          //     case "اجتماع":
          //       if (newCoins >= 2) newCoins -= 2;
          //       break;
          //   }
          // }

          print('Updating: ${studentData['name']} - Counter: $currentCounter->$newCounter');

          // Create update data with explicit types
          Map<String, dynamic> updateData = <String, dynamic>{
            'totalCounter': newCounter,
//            'totalCoins': newCoins,
          };

          // Update the student
          await databases.updateDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            documentId: studentId,
            data: updateData,
          );

          print('✅ Successfully updated student: ${studentData['name']}');

        } catch (e) {
          print('❌ Error processing individual student: $e');
          continue; // Continue with next student
        }
      }

      print('✅ Finished processing all students');

    } catch (e) {
      print('❌ Error in main function: $e');
    }
  }
  Future<void> _delMeetingsData(String meetingId) async {
    try {
      // Call the method to reduce student data before deleting the meeting
      await _getStudentsDataAndReduceAndUpdate(meetingId);

      final databases = GetIt.I<appwrite.Databases>();
      final storage = GetIt.I<appwrite.Storage>();

      // Delete related lesson data (metadata + files) for this meeting first
      try {
        final lessonDocs = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.lessonsCollectionId,
          queries: [
            appwrite.Query.equal('meetingId', meetingId),
            appwrite.Query.select(['\$id','fileId']),
          ],
        );
        for (final doc in lessonDocs.documents) {
          final data = doc.data;
          final fileId = data['fileId'];
          // delete metadata
          await databases.deleteDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.lessonsCollectionId,
            documentId: doc.$id,
          );
          // delete file
          if (fileId != null && (fileId as String).isNotEmpty) {
            try {
              await storage.deleteFile(
                bucketId: AppwriteServices.bucketId,
                fileId: fileId,
              );
            } catch (_) {}
          }
        }
      } catch (e) {
        // ignore errors while deleting lessons; continue with meeting deletion
      }

      // Now delete the meeting itself
      await databases.deleteDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.meetingsCollectionId,
        documentId: meetingId,
      );

      // Reset pagination state and fetch fresh data
      setState(() {
        meetingsData.clear();
        hasMoreData = true;
        isLoading = false;
      });
      _getMeetingsData();
    } on appwrite.AppwriteException catch (e) {
      print('Error deleting meeting: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'خطأ في حذف الاجتماع: ${e.message ?? 'خطأ غير معروف'}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  Future<void> _getMeetingsData() async {
    if (isLoading || !hasMoreData) return; // Prevent multiple calls
    
    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      // Optimized query - fetch 6 meetings per page
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.meetingsCollectionId,
        queries: [
          appwrite.Query.equal('classId', Constants.classId),
          appwrite.Query.orderDesc("createdAt"),
          appwrite.Query.limit(pageSize), // Load 6 meetings per page
          appwrite.Query.select(['\$id', 'createdAt', 'Type', 'createdBy']), // Include createdBy for display
          if (meetingsData.isNotEmpty)
            appwrite.Query.cursorAfter(meetingsData.last['\$id']),
        ],
      );

      if (documents.documents.isEmpty) {
        print('📭 No more meetings to load');
        setState(() {
          hasMoreData = false; // No more data to load
        });
      } else {
        print('📄 Loaded ${documents.documents.length} meetings (expected: $pageSize)');
        
        // Ultra-lightweight date processing for maximum speed
        List<Map<String, dynamic>> processedData = documents.documents.map((doc) {
          Map<String, dynamic> data = Map<String, dynamic>.from(doc.data);
          
          // Convert to local time for display
          DateTime createdAt = DateTime.parse(data["createdAt"]).toLocal();
          data['_formattedTime'] = ' ${createdAt.day}/${createdAt.month}/${createdAt.year}';
          // Capture optional createdBy
          final dynamic cb = data['createdBy'];
          if (cb != null) {
            data['_createdBy'] = cb.toString();
          }
        //        data['_formattedTime'] = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} - ${createdAt.day}/${createdAt.month}/${createdAt.year}';
    
          return data;
        }).toList();
        
        setState(() {
          meetingsData.addAll(processedData);
          // Check if we received fewer documents than requested (indicates end of data)
          hasMoreData = documents.documents.length == pageSize;
        });
        
        print('📊 Total meetings displayed: ${meetingsData.length}, hasMoreData: $hasMoreData');
      }
    } on appwrite.AppwriteException catch (e) {
      print('Appwrite Error: ${e.message}');
      // Handle specific network errors
      if (e.message != null && e.message!.contains('Failed host lookup')) {
        setState(() {
          _connectivityService.isConnected = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 4),
              backgroundColor: Colors.red,
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // Handle other Appwrite errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
              content: Text(
                'خطأ في تحميل الاجتماعات: ${e.message ?? 'خطأ غير معروف'}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any other errors
      print('General Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
            content: Text(
              'خطأ غير متوقع في تحميل الاجتماعات',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      // Always ensure loading state is properly updated
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("الأجتماعات", style: TextStyle(fontSize: Constants.deviceWidth / 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Homepage()),
                  (route) => false,
            );
          },
          icon: Icon(Icons.arrow_back, size: Constants.arrowBackSize),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AddMeeting(),
          ));
        },
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueGrey),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: isLoading && meetingsData.isEmpty
          ? Center(
              child: SpinKitWaveSpinner(color: Colors.blueGrey),
            )
          : !_connectivityService.isConnected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: Constants.deviceWidth / 6,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'لا يوجد اتصال بالإنترنت',
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'تحقق من اتصال الإنترنت وحاول مرة أخرى',
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 20,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          _connectivityService.checkConnectivity(
                            context, 
                            _getMeetingsData()
                          );
                        },
                        icon: Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Constants.deviceWidth / 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // Detect when user scrolls near bottom to load more meetings
                    if (!isLoading && 
                        hasMoreData && 
                        scrollInfo is ScrollUpdateNotification &&
                        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50) {
                      print('🔄 Loading next 6 meetings... Current total: ${meetingsData.length}');
                      _getMeetingsData(); // Load 6 more meetings
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: meetingsData.length + (isLoading && hasMoreData ? 1 : 0), // Only show loading indicator when actually loading
                    physics: const ClampingScrollPhysics(), // Better scroll performance
                    cacheExtent: 100, // Cache fewer items for memory efficiency
                    itemBuilder: (context, index) {
                      // Show loading indicator only when actually loading more data
                      if (index == meetingsData.length) {
                        return isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      
                      // Cache frequently accessed data
                      final meeting = meetingsData[index];
                      final formattedTime = meeting['_formattedTime'] ?? '';
                      final meetingType = meeting["Type"] ?? '';
                      final meetingId = meeting['\$id'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Card(
                          color: Colors.blueGrey,
                          elevation: 3, // Reduced elevation for better performance
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            title: Center(
                              child: Text(
                                meetingType,
                                style: TextStyle(fontSize: Constants.deviceWidth / 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            subtitle: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: Constants.deviceWidth / 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if ((meeting['_createdBy'] ?? '').toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'الخادم : ${meeting['_createdBy']}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: Constants.deviceWidth / 32,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {
                              // Removed async to reduce overhead
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => OnlineOrOffline(
                                  meetingId: meetingId,
                                ),
                              ));
                            },
                            onLongPress: () {
                              AwesomeDialog(
                                dialogBackgroundColor: Colors.white,
                                context: context,
                                dialogType: DialogType.noHeader,
                                animType: AnimType.rightSlide,
                                title: 'أتريد حذف هذا الأجتماع؟',
                                btnCancelText: "حذف",
                                btnCancelOnPress: () async {
                                  await _delMeetingsData(meetingId); // Use cached meetingId
                                },
                              ).show();
                            },
              ),
            ),
          );
                    },
                  ),
                ),
    );
  }
}