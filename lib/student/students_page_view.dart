import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:attendance/home_page.dart';
import 'package:attendance/download_data/students_data_control.dart';
import 'package:attendance/student/student_detailsage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';


class StudentsPageView extends StatefulWidget {
  const StudentsPageView({super.key});

  @override
  State<StudentsPageView> createState() => _StudentsPageViewState();
}

class _StudentsPageViewState extends State<StudentsPageView> {
  List<dynamic> meetings =[];
  List<Map<String, dynamic>> studentData = [];
  List<Map<String, dynamic>> _allSortedStudents = []; // Cache for sorted data
  int _currentPage = 0; // Track current page for sorted data
  bool isLoading = false;
  bool hasMoreData = true; // To track if there's more data to load
  String orderBy = 'name'; // Default order by name
  final int pageSize = 10; // Number of students to load per page
  String order = 'الأسم';
  late ConnectivityService _connectivityService;
  @override
  void initState() {
    super.initState();
   // _getStudentsData(orderBy);
        _connectivityService = ConnectivityService();
    _connectivityService.checkConnectivity(context, _getStudentsData(orderBy));

  }

  Future<void> _getStudentsData(String orderBy) async {
    if (isLoading || !hasMoreData) return; // Prevent multiple calls
    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      // For totalCounter (meetings.length), we need to fetch all data and sort manually
      if (orderBy == "totalCounter") {
        // Only fetch all data on the first load (when studentData is empty)
        if (studentData.isEmpty) {
          final documents = await databases.listDocuments(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            queries: [
              appwrite.Query.equal('classId', Constants.classId),
              appwrite.Query.limit(500), // Get all students
            ],
          );
          
          // Convert to list and sort by meetings length
          List<Map<String, dynamic>> allStudents = documents.documents.map((doc) => doc.data).toList();
          
          // Sort by meetings array length (descending order - highest attendance first)
          allStudents.sort((a, b) {
            List<dynamic> meetingsA = a["meetings"] ?? [];
            List<dynamic> meetingsB = b["meetings"] ?? [];
            return meetingsB.length.compareTo(meetingsA.length);
          });
          
          // Store all sorted students but only show first page
          _allSortedStudents = allStudents;
          _currentPage = 0;
          
          setState(() {
            studentData = _allSortedStudents.take(pageSize).toList();
            hasMoreData = _allSortedStudents.length > pageSize;
          });
        } else {
          // Load next page from cached sorted data
          _currentPage++;
          int startIndex = _currentPage * pageSize;
          int endIndex = startIndex + pageSize;
          
          if (startIndex < _allSortedStudents.length) {
            List<Map<String, dynamic>> nextPageData = _allSortedStudents.skip(startIndex).take(pageSize).toList();
            setState(() {
              studentData.addAll(nextPageData);
              hasMoreData = endIndex < _allSortedStudents.length;
            });
          } else {
            setState(() {
              hasMoreData = false;
            });
          }
        }
      } else {
        // For other sorting options, use normal pagination
        final documents = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.studentsCollectionId,
          queries: [
            appwrite.Query.equal('classId', Constants.classId),
            appwrite.Query.limit(pageSize),
            appwrite.Query.orderAsc(orderBy), // Use appwrite.Query to avoid conflict
            if (studentData.isNotEmpty)
              appwrite.Query.cursorAfter(studentData.last['\$id']),
          ],
        );

        if (documents.documents.isEmpty) {
          hasMoreData = false; // No more data to load
        } else {
          studentData.addAll(documents.documents.map((doc) => doc.data).toList());
        }
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
                      'لا يمكن الوصول إلى الخادم. تحقق من اتصال الإنترنت',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: Constants.deviceWidth / 22
                      ),
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: () {
                  _connectivityService.checkConnectivity(context, _getStudentsData(orderBy));
                },
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
                'خطأ في تحميل البيانات: ${e.message ?? 'خطأ غير معروف'}',
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
              'خطأ غير متوقع في تحميل البيانات',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  void _updateOrderBy(String newOrderBy) {
    setState(() {
      switch (newOrderBy) {
        case "الأسم":
          orderBy = "name";
          break;
        case "العنوان":
          orderBy = "address";
          break;
        case "المنطقة":
          orderBy = "region";
          break;
        case "الحضور الكلي":
          orderBy = "totalCounter";
          break;
        default:
          orderBy = "name";
          break;
      }
      order = newOrderBy;
      studentData.clear();
      _allSortedStudents.clear(); // Clear cached sorted data
      _currentPage = 0; // Reset page counter
      hasMoreData = true;
      _getStudentsData(orderBy);
    });
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: (isLoading || (Constants.isUser))
          ? null
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "download",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsDataControl(),));
            },
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.download, color: Colors.white),
          ),
         // SizedBox(height: 10),
          // FloatingActionButton(
          //   heroTag: "update_counters",
          //   onPressed: () {
          //     _updateStudentMeetingCounters();
          //   },
          //   backgroundColor: Colors.green,
          //   child: Icon(Icons.update, color: Colors.white),
          //   tooltip: 'جمع ايام الحضور',
          // ),
        ],
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: Constants.arrowBackSize),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Homepage()),
                (route) => false,
          ),
        ),
centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 1,),

            ( order != "الحضور الكلي")?
          //  (order!="حضور القداس"&&  order != "حضور الألحان" && order != "حضور التسبحة"&& order != "الحضور الكلي")?

            GestureDetector(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(orderBy, order),
                );
              },
              child: Row(
                children: [
                  Text("بحث",style: TextStyle(fontSize: Constants.deviceWidth/16),),
                  Icon(Icons.search,size: Constants.deviceWidth/16,),
                  // IconButton(
                  //   icon: Icon(Icons.search),
                  //   onPressed: () {
                  //
                  //   },
                  // ),
                ],
              ),
            ):Container(),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: DropdownButton<String>(

                dropdownColor: Colors.white,
                value: order,
                alignment: Alignment.center,

                icon: Icon(Icons.sort,size: Constants.arrowBackSize,),
                items: <String>[
                  //'المنطقة',
               //   'الأسم','المنطقة',  'العنوان', 'حضور الألحان', 'حضور القداس', "حضور التسبحة","الحضور الكلي"
                  'الأسم','المنطقة',  'العنوان',"الحضور الكلي"
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    alignment: Alignment.centerRight,
                    value: value,
                    child: Text("[ $value ]", style: TextStyle(fontSize: Constants.deviceHeight/40)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateOrderBy(newValue);
                  }
                },
              ),
            ),

          ],
        )
       // centerTitle: true,
       //  actions: [
       //
       //
       //
       //  ],
      ),
      body: isLoading && studentData.isEmpty
          ? Center(child: SpinKitWaveSpinner(color: Colors.blueGrey))
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
                            _getStudentsData(orderBy)
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
              : Stack(
            children: [
              Container(
                  decoration: BoxDecoration(image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(Constants.backgroundImage,)),

                  )
              ),
              NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
              if (!isLoading &&
                  hasMoreData &&
                  scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                _getStudentsData(orderBy); // Load more data
              }
              return false;
                      },
                      child: ListView.builder(
              itemCount: studentData.length,
              itemBuilder: (context, index) {
                meetings = studentData[index]["meetings"]??[];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(15),
                      title: Text(
                        studentData[index]["name"],
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      subtitle: Text(
                        "${studentData[index]["region"]} - ${studentData[index]["address"]}",
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 20,
                          color: Colors.black,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // trailing: (orderBy == "alhanCounter" || orderBy == "qudasCounter" || orderBy == "tasbhaCounter"|| orderBy == "totalCounter")
                      //     ? Text(
                      //   studentData[index]["$orderBy"].toString(),
                      //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      // )
                      trailing: ( orderBy == "totalCounter")
                          ? Text("${meetings.length}",

                      //  studentData[index]["meetings"].toString(),
                        //studentData[index]["$orderBy"].toString(),
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      )
                          : null,
                      onTap: () async{
                        await _connectivityService.checkConnectivityWithoutActions(context);
                        if(_connectivityService.isConnected) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => StudentDetailsPage(studentId: studentData[index]['\$id']),
                        )
                        );
                        } else {
                          // Handle offline case
                        }
                      },
                    ),
                  ),
                );
              },
                      ),
                    ),
            ],
          ),
    );
  }

  // ignore: unused_element
  Future<void> _updateStudentMeetingCounters() async {
    print("=== DEBUG: Starting meeting counter update ===");
    
    try {
      setState(() {
        isLoading = true;
      });

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("جاري تحديث العدادات..."),
              ],
            ),
          );
        },
      );

      print("DEBUG: Fetching all students...");
      // Get all students
      final databases = GetIt.I<appwrite.Databases>();
      final studentsResponse = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          appwrite.Query.equal('classId', Constants.classId),
          appwrite.Query.limit(1000), // Get all students
        ],
      );

      print("DEBUG: Found ${studentsResponse.documents.length} students");

      // Process each student
      for (var studentDoc in studentsResponse.documents) {
        print("\n--- DEBUG: Processing student ${studentDoc.data['name']} (${studentDoc.$id}) ---");
        
        int alhanCounter = 0;
        int qudasCounter = 0; 
        int tasbhaCounter = 0;
        int madrasAhadCounter = 0;
        int ejtimaCounter = 0;
        int totalCounter = 0;
        List<dynamic> meetings = studentDoc.data['meetings']?? [];
        try {
          print("DEBUG: Querying meetings for student ${studentDoc.$id}...");
          for (var meeting in meetings) {
            
         
          // Query meetings where this student attended (reverse lookup)
          final meetingResponse = await databases.getDocument(
            documentId: meeting['\$id'],
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.meetingsCollectionId,
        
          );
         String meetingType = meetingResponse.data['Type'];
     if (meetingType.isNotEmpty) {
              totalCounter++;

              if (meetingType.contains('تسبحة')) {
                tasbhaCounter++;
                print("DEBUG: Counted as تسبحة");
              } else if (meetingType.contains('قداس')) {
                qudasCounter++;
                print("DEBUG: Counted as قداس");  
              } else if (meetingType.contains('حصة الألحان')) {
                alhanCounter++;
                print("DEBUG: Counted as حصة الألحان");
              } else if (meetingType.contains('مدارس أحد')) {
                madrasAhadCounter++;
                print("DEBUG: Counted as مدارس أحد");
              } else if (meetingType.contains('اجتماع')) {
                ejtimaCounter++;
                print("DEBUG: Counted as اجتماع");
              }
            }


 }
       //   print("DEBUG: Found ${meetingsResponse.documents.length} meetings for student ${studentDoc.data['name']}");

          // Count meetings by type
       

          print("DEBUG: Final counts for ${studentDoc.data['name']}: الألحان=$alhanCounter, القداس=$qudasCounter, التسبحة=$tasbhaCounter, مدارس أحد=$madrasAhadCounter, اجتماع=$ejtimaCounter, الإجمالي=$totalCounter");

          // Update student counters
          await databases.updateDocument(
            databaseId: AppwriteServices.databaseId,
            collectionId: AppwriteServices.studentsCollectionId,
            documentId: studentDoc.$id,
            data: {
              'alhanCounter': alhanCounter,
              'qudasCounter': qudasCounter,
              'tasbhaCounter': tasbhaCounter,
              'madrasAhadCounter': madrasAhadCounter,
              'ejtimaCounter': ejtimaCounter,
              'totalCounter': totalCounter,
            },
          );

          print("DEBUG: Successfully updated counters for ${studentDoc.data['name']}");

        } catch (e) {
          print("ERROR: Failed to update student ${studentDoc.data['name']}: $e");
        }
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تحديث عدادات الحضور بنجاح لجميع الطلاب"),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the student list
      await _getStudentsData(orderBy);

    } catch (e) {
      print("ERROR: Failed to update meeting counters: $e");
      
      // Close loading dialog if open
      Navigator.of(context, rootNavigator: true).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في تحديث العدادات: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    print("=== DEBUG: Meeting counter update completed ===");
  }

}

class CustomSearchDelegate extends SearchDelegate<void> {
  final String searchBy;
  final String searchByInArabic;

  CustomSearchDelegate(this.searchBy, this.searchByInArabic);

  @override
  String get searchFieldLabel => 'بحث ب$searchByInArabic ...';
  @override
  TextStyle get searchFieldStyle =>
      TextStyle(fontSize: Constants.deviceWidth / 22, overflow: TextOverflow.ellipsis);
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        toolbarHeight: MediaQuery.of(context).size.height/12,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.black),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(
      color: Colors.white70,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _searchStudents(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No results found',
                    style: TextStyle(color: Colors.black)));
          } else {
            return _buildStudentList(snapshot.data!);
          }
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
    );
  }

  Future<List<Map<String, dynamic>>> _searchStudents(String query) async {
    List<Map<String, dynamic>> studentsList = [];
    try {
      final databases = GetIt.I<appwrite.Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          appwrite.Query.equal('classId', Constants.classId),

          appwrite.Query.search(searchBy, query),
          // appwrite.Query.search('address', query),
        ],
      );

      studentsList = documents.documents.map((doc) => doc.data).toList();
    } on appwrite.AppwriteException catch (e) {
      print('Error searching students: $e');
    }
    return studentsList;
  }

  Widget _buildStudentList(List<Map<String, dynamic>> filteredStudents) {
    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];

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
              title: Text(
                student["name"],
                style: TextStyle(
                    fontSize:  Constants.deviceWidth / 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              subtitle: Text(
                "${student["region"]} - ${student["address"]}",
                style: TextStyle(fontSize: Constants.deviceWidth / 20, color: Colors.white),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => StudentDetailsPage(
                    studentId: student["\$id"],
                  ),
                ));
              },
            ),
          ),
        );
      },
    );
  }
}

