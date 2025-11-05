
import 'package:appwrite/appwrite.dart';
import 'package:attendance/home_page.dart';
import 'package:attendance/notification/add_notification.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';

class DisplayNotifications extends StatefulWidget {
  const DisplayNotifications({super.key});

  @override
  State<DisplayNotifications> createState() => _DisplayNotificationsState();
}

class _DisplayNotificationsState extends State<DisplayNotifications> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String dayName = "";
  late ConnectivityService _connectivityService;

  // Pagination variables
  int page = 1;
  bool isLastPage = false;
  bool isFetching = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.checkConnectivity(context, getNotifications());
  }

  final databases = GetIt.I<Databases>();

  Future<void> _deleteNotification(String docId) async {
    try {
      await databases.deleteDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.notificationsCollectionId,
          documentId: docId);
      notifications.clear();
      page = 1;
      isLastPage = false;
      await getNotifications();
    } on AppwriteException catch (e) {
      print(e);
    }
  }

  Future<void> getNotifications() async {
    if (isFetching || isLastPage) return;

    setState(() {
      isFetching = true;
    });

    try {
      final response = await databases.listDocuments(
        queries: [
          Query.equal('classId', Constants.classId),

          Query.orderDesc("\$createdAt"),
          Query.limit(10),
          Query.offset((page - 1) * 10),
        ],
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.notificationsCollectionId,
      );

      final List<Map<String, dynamic>> fetchedNotifications =
      response.documents.map((doc) => doc.data).toList();

      if (fetchedNotifications.length < 10) {
        isLastPage = true;
      }

      notifications.addAll(fetchedNotifications);

      setState(() {
        isLoading = false;
        page++;
      });
    } on AppwriteException catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }

    setState(() {
      isFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton:
      (_connectivityService.isConnected &&
          (!Constants.isUser)



    )
          ? FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddNotification()));
        },
        child: Icon(
          Icons.add,
          color: Colors.blueGrey,
          size: 30,
        ),
      )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("ملاحظات",style: TextStyle(fontSize: Constants.deviceWidth/18),),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Homepage()),
                    (route) => false);
          },
          icon: Icon(Icons.arrow_back,size: Constants.arrowBackSize,),
        ),
      ),
      body: isLoading
          ? Center(
        child: SpinKitWaveSpinner(
          waveColor: Colors.blueGrey,
          color: Colors.blueGrey,
        ),
      )
          : _connectivityService.isConnected == false
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                style: ButtonStyle(
                    backgroundColor:
                    WidgetStatePropertyAll(Colors.blueGrey)),
                onPressed: () async {
                  _connectivityService.isConnected
                      ? await _connectivityService.checkConnectivity(
                      context, getNotifications())
                      : _connectivityService
                      .checkConnectivityWithoutActions(context);
                },
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: Constants.deviceWidth/15,
                )),
            Text(
              "إعادة المحاولة",
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold),
            )
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
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent &&
                  !isFetching &&
                  !isLastPage) {
                getNotifications();
              }
              return false;
                      },
                      child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                // Convert the parsed DateTime to local time
                DateTime createdAt = DateTime.parse(
                    notifications[index]["\$createdAt"])
                    .toLocal();
                String formattedTime =
                DateFormat('["a hh : mm "]  dd - MM - yyyy')
                    .format(createdAt);
                if (createdAt.year == DateTime.now().year &&
                    createdAt.month == DateTime.now().month &&
                    createdAt.day == DateTime.now().day) {
                  dayName = "اليوم";
                } else {
                  String formattedDayName =
                  DateFormat('EEEE').format(createdAt);
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(15),
                      title: Center(
                        child: Text(
                          notifications[index]["message"],
                          style: TextStyle(
                              fontSize: Constants.deviceWidth/20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      subtitle: Center(
                        child: Text(

                          "$formattedTime  [ $dayName ]",
                          style:
                          TextStyle(fontSize:  Constants.deviceWidth/30, color: Colors.black),
                        ),
                      ),
                      leading: Icon(
                        size: Constants.deviceWidth/15,
                        Icons.notifications_active,
                        color: Colors.deepOrangeAccent,
                      ),

                      onLongPress:
                          !Constants.isUser?
                          () {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.noHeader,
                          animType: AnimType.rightSlide,
                          title: 'أتريد حذف هذة الملاحظة؟',
                          btnCancelText: "حذف",
                          btnCancelOnPress: () {
                            _deleteNotification(
                                notifications[index]["\$id"]);
                          },
                        ).show();
                      }:
                          (){

                          }

                      ,
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
}