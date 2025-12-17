// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// class AttendanceDaysForStudent extends StatefulWidget {
//   final List<dynamic> meetings;
//
//   const AttendanceDaysForStudent(this.meetings, {super.key});
//
//   @override
//   State<AttendanceDaysForStudent> createState() => _AttendanceDaysForStudentState();
// }
//
// class _AttendanceDaysForStudentState extends State<AttendanceDaysForStudent> {
//    List<dynamic> orderdMeetings=[];
//   @override
//   void initState() {
//     super.initState();
//    if(widget.meetings.isNotEmpty)
//      {
// setState(() {
//   orderdMeetings=   widget.meetings.reversed.toList();
//
// });
//      }
//   }
//   String dayName="";
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         title: Text("جميع أيام الحضور"),
//
//         leading: IconButton(onPressed: () {
//           Navigator.of(context).pop();
//         }, icon: Icon(Icons.arrow_back)),
//       ),
//       body:   ListView.builder(
//
//         itemCount: orderdMeetings.length,
//
//         itemBuilder: (context, index) {
//           //     String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(meetingsData[index]["createdAt"]);
//           DateTime createdAt = DateTime.parse(orderdMeetings[index]["\$createdAt"]) .toLocal();
//           String formattedTime = DateFormat('["a hh : mm "]  dd - MM - yyyy').format(createdAt);
//           if(createdAt.year == DateTime.now().year &&
//               createdAt.month == DateTime.now().month &&
//               createdAt.day == DateTime.now().day)
//           {
//             print(createdAt.day);
//             dayName ="اليوم";
//
//           }
//           else
//           {
//             String formattedDayName = DateFormat('EEEE').format(createdAt);
//             switch (formattedDayName) {
//               case "Monday":
//                 dayName = "الأثنين";
//                 break;
//               case "Tuesday":
//                 dayName = "الثلاثاء";
//                 break;
//               case "Wednesday":
//                 dayName = "الأربعاء";
//                 break;
//               case "Thursday":
//                 dayName = "الخميس";
//                 break;
//               case "Friday":
//                 dayName = "الجمعة";
//                 break;
//               case "Saturday":
//                 dayName = "السبت";
//                 break;
//               case "Sunday":
//                 dayName = "الأحد";
//                 break;
//               default:
//                 dayName = "غير معلوم";
//             }
//
//           }
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             child: Card(
//               color: Colors.blueGrey,
//               elevation: 5,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: ListTile(
//                 contentPadding: EdgeInsets.all(15),
//                 title: Center(
//                   child: Text(
//                     orderdMeetings[index]["Type"],
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
//                   ),
//                 ),
//                 subtitle: Center(
//                   child: Text(
//                     "$formattedTime - [ $dayName ]",
//                     style: TextStyle(fontSize: 14, color: Colors.white),
//                   ),
//                 ),
//
//               ),
//             ),
//           );
//         },)
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helper/constants.dart';



class AttendanceDaysForStudent extends StatefulWidget {
  final List<dynamic> meetings;

  const AttendanceDaysForStudent(this.meetings, {super.key});

  @override
  State<AttendanceDaysForStudent> createState() => _AttendanceDaysForStudentState();
}

class _AttendanceDaysForStudentState extends State<AttendanceDaysForStudent> {
  List<dynamic> orderdMeetings = [];
  List<dynamic> displayedMeetings = [];
  final ScrollController _scrollController = ScrollController();
  int currentPage = 0;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    
    // Debug output for received meetings data
    print("=== DEBUG: AttendanceDaysForStudent initState ===");
    print("DEBUG: Received meetings: ${widget.meetings}");
    print("DEBUG: Meetings type: ${widget.meetings.runtimeType}");
    print("DEBUG: Meetings length: ${widget.meetings.length}");
    if (widget.meetings.isNotEmpty) {
      print("DEBUG: First meeting: ${widget.meetings.first}");
      print("DEBUG: Reversing meetings and loading items...");
    }
    
    if (widget.meetings.isNotEmpty) {
      orderdMeetings = widget.meetings.reversed.toList();
      _loadMoreItems();
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          _loadMoreItems();
        }
      });
    }
  }

  void _loadMoreItems() {
    setState(() {
      int nextPage = currentPage + 1;
      int startIndex = currentPage * itemsPerPage;
      int endIndex = nextPage * itemsPerPage;
      if (startIndex < orderdMeetings.length) {
        displayedMeetings.addAll(orderdMeetings.sublist(
            startIndex, endIndex > orderdMeetings.length ? orderdMeetings.length : endIndex));
        currentPage = nextPage;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String dayName = "";

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text("جميع أيام الحضور",style: TextStyle(fontSize: Constants.deviceWidth/20),),
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back,size: Constants.arrowBackSize,)),
        ),
        body: ListView.builder(
          controller: _scrollController,
          itemCount: displayedMeetings.length + 1,
          itemBuilder: (context, index) {
            if (index == displayedMeetings.length) {
              return _buildProgressIndicator();
            } else {
              DateTime createdAt = DateTime.parse(displayedMeetings[index]["\$createdAt"]).toLocal();
              String formattedTime = DateFormat('["a hh : mm "]  dd - MM - yyyy').format(createdAt);
              if (createdAt.year == DateTime.now().year &&
                  createdAt.month == DateTime.now().month &&
                  createdAt.day == DateTime.now().day) {
                dayName = "اليوم";
              } else {
                String formattedDayName = DateFormat('EEEE').format(createdAt);
                switch (formattedDayName) {
                  case "Monday":
                    dayName = "الأثنين";
                    break;
                  case "Tuesday":
                    dayName = "الثلاثاء";
                    break;
                  case "Wednesday":
                    dayName = "الأربعاء";
                    break;
                  case "Thursday":
                    dayName = "الخميس";
                    break;
                  case "Friday":
                    dayName = "الجمعة";
                    break;
                  case "Saturday":
                    dayName = "السبت";
                    break;
                  case "Sunday":
                    dayName = "الأحد";
                    break;
                  default:
                    dayName = "غير معلوم";
                }
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
                      child: Text(
                        displayedMeetings[index]["Type"],
                        style: TextStyle(fontSize: Constants.deviceWidth/20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    subtitle: Center(
                      child: Text(
                        "$formattedTime - [ $dayName ]",
                        style: TextStyle(fontSize: Constants.deviceWidth/28, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ));
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Opacity(
          opacity: displayedMeetings.length < orderdMeetings.length ? 1.0 : 0.0,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}