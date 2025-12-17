
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';


class AttendarsForMeeting extends StatefulWidget {
  final String meetingId;

  const AttendarsForMeeting({super.key, required this.meetingId});

  @override
  State<AttendarsForMeeting> createState() => _AttendarsForMeetingState();
}

class _AttendarsForMeetingState extends State<AttendarsForMeeting> {
  List<dynamic> students = [];
  List<dynamic> studentsTotalList = [];
  Map<String, dynamic>? meetingData;
  bool isLoading = true;
  bool isFetchingMore = false;
  int currentPage = 0;
  final int itemsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getMeetingData(String meetingId) async {
    try {
      final databases = GetIt.I<Databases>();
      final document = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.meetingsCollectionId,
        documentId: meetingId,
        // queries: [
        //   Query.equal('classId', Constants.classId),
        //
        // ]
      );

      return document.data;
    } on AppwriteException catch (e) {
      print('Error fetching meeting data: ${e.message}');
      return null;
    }
  }

  Future<void> _fetchStudentData() async {
    try {
      final data = await getMeetingData(widget.meetingId);
      if (data != null) {
        setState(() {
          meetingData = data;
          studentsTotalList=    data['students'];
          students = data['students'].take((currentPage + 1) * itemsPerPage).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isFetchingMore) {
      _fetchMoreData();
    }
  }

  Future<void> _fetchMoreData() async {
    setState(() {
      isFetchingMore = true;
    });

    await Future.delayed(Duration(seconds: 2)); // Simulate network delay

    final newStudents = meetingData!['students']
        .skip((currentPage + 1) * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    setState(() {
      students.addAll(newStudents);
      currentPage++;
      isFetchingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text("الحضور", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: Constants.deviceWidth/22)),
        centerTitle: true,
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.white,size: Constants.arrowBackSize,),
        ),
        actions: [
          IconButton(
            tooltip: 'اختيار طالب عشوائي ❤️',
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: _selectRandomStudent,
          ),
          IconButton(
            tooltip: 'مشاركة قائمة الحضور',
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareAttenders,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: SpinKitWaveSpinner(
          color: Colors.blueGrey,
        ),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: students.length + (isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == students.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Card(
              color: Colors.blueGrey,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(15),
                title: Center(
                  child: Row(
                    children: [
                      Text("${studentsTotalList.length- index} - ",style: TextStyle(color: Colors.white),),
                      Text(
                        students[index]["name"],
                        style: TextStyle(
                            fontSize: Constants.deviceWidth/20, fontWeight: FontWeight.bold, color: Colors.white, overflow: TextOverflow.ellipsis),

                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Fetch the full attendees list (no pagination) and return names only
  Future<List<String>> _getAllStudentsData() async {
    try {
      // Use cached meetingData if present; otherwise fetch it
      final data = meetingData ?? await getMeetingData(widget.meetingId);
      if (data == null) return [];

      final List<dynamic> raw = (data['students'] ?? []) as List<dynamic>;
      final names = raw
          .map((e) {
            if (e is Map) {
              final n = e['name'] ?? e['Name'] ?? e['fullName'];
              return n?.toString() ?? '';
            }
            return e.toString();
          })
          .where((s) => s.trim().isNotEmpty)
          .toList();
      return names;
    } catch (e) {
      debugPrint('getAllStudentsData error: $e');
      return [];
    }
  }

  // Compose and open system share sheet (WhatsApp supported) with attendee names
  Future<void> _shareAttenders() async {
    // Indicate loading while fetching full list
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final names = await _getAllStudentsData();
    if (mounted) Navigator.of(context).pop();

    if (names.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد أسماء لحضور هذا الاجتماع')),
        );
      }
      return;
    }

    // Try to include meeting type and date if available
    final type = (meetingData ?? {})['Type']?.toString() ?? '';
    final dateStr = (meetingData ?? {})['date']?.toString() ?? '';
    final header = [
      if (type.isNotEmpty) 'نوع الاجتماع: $type',
      if (dateStr.isNotEmpty) 'التاريخ: $dateStr',
      'عدد الحضور: ${names.length}',
      '— — —',
    ].join('\n');

    final body = names.asMap().entries
        .map((e) => '${e.key + 1}- ${e.value}')
        .join('\n');

    final message = '$header\n$body';

    await Share.share(
      message,
      subject: type.isNotEmpty ? 'قائمة الحضور - $type' : 'قائمة الحضور',
    );
  }

  // Select random student from attendees
  Future<void> _selectRandomStudent() async {
    if (studentsTotalList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب حضروا هذا الاجتماع'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog while selecting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري الاختيار...'),
            ],
          ),
        ),
      ),
    );

    // Add a small delay for dramatic effect
    await Future.delayed(const Duration(milliseconds: 1500));

    // Select random student
    final random = Random();
    final randomIndex = random.nextInt(studentsTotalList.length);
    final selectedStudent = studentsTotalList[randomIndex];
    
    // Get student name
    String studentName = '';
    if (selectedStudent is Map) {
      studentName = selectedStudent['name'] ?? selectedStudent['Name'] ?? selectedStudent['fullName'] ?? 'طالب غير معروف';
    } else {
      studentName = selectedStudent.toString();
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show result dialog with animation
      _showRandomStudentDialog(studentName, randomIndex + 1);
    }
  }

  void _showRandomStudentDialog(String studentName, int position) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.shade50,
                Colors.red.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'الطالب المختار ❤️',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Student name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Position info
              Text(
                'المركز: $position من ${studentsTotalList.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Congratulations message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Text(
                  '🎉 مبروك! أنت الطالب المحظوظ اليوم! 🎉',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Close button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _selectRandomStudent(); // Select another random student
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'اختيار آخر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}