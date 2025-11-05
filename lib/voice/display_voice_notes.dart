

import 'package:appwrite/appwrite.dart';
import 'package:attendance/home_page.dart';
import 'package:attendance/voice/display_voice_and_lyrics.dart';
import 'package:attendance/voice/voice_note_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';

class DisplayVoiceNotes extends StatefulWidget {
  const DisplayVoiceNotes({super.key});

  @override
  State<DisplayVoiceNotes> createState() => _DisplayVoiceNotesState();
}

class _DisplayVoiceNotesState extends State<DisplayVoiceNotes> {
  bool isLoading = false;
  bool isLoadingMore = false;
  Map<dynamic, dynamic> filesMap = {};
  late ConnectivityService _connectivityService;
  int currentPage = 0;
  int totalItems = 0;
  final int itemsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.checkConnectivity(context, getRecords());
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> getRecords({int page = 0}) async {
    setState(() {
      if (page == 0) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {

      final database = GetIt.I<Databases>(); // Assuming you have a Database instance
      final responseData = await database.listDocuments(
        databaseId: AppwriteServices.databaseId,

        collectionId: AppwriteServices.fielsDataCollectionId,
        queries: [
          Query.equal('classId', Constants.classId), // Query for classId
        ],
      );

      // Extract file IDs from the retrieved documents
      final fileIds = responseData.documents.map((doc) => doc.$id).toList();

      final storage = GetIt.I<Storage>();
      final responseFiles = await storage.listFiles(
        bucketId: AppwriteServices.bucketId,
        queries: [
          Query.orderDesc("\$createdAt"),
          Query.limit(itemsPerPage),
          Query.offset(page * itemsPerPage),
          Query.equal('\$id', fileIds), // Filter files by the retrieved file IDs
        ],
      );

      setState(() {
        filesMap.addEntries(
          responseFiles.files.map((file) => MapEntry(file.$id, file.name)),
        );
        totalItems = responseFiles.total;
      });
    } on AppwriteException catch (e) {
      print('Error: ${e.message}');
    }

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
  }
  // Future<void> getRecords({int page = 0}) async {
  //   setState(() {
  //     if (page == 0) {
  //       isLoading = true;
  //     } else {
  //       isLoadingMore = true;
  //     }
  //   });
  //
  //   try {
  //     final storage = GetIt.I<Storage>();
  //     final response = await storage.listFiles(
  //       bucketId: AppwriteServices.bucketId,
  //       queries: [
  //         Query.orderDesc("\$createdAt"),
  //         Query.limit(itemsPerPage),
  //         Query.offset(page * itemsPerPage),
  //       ],
  //     );
  //
  //     setState(() {
  //       filesMap.addEntries(
  //         response.files.map((file) => MapEntry(file.$id, file.name)),
  //       );
  //       totalItems = response.total;
  //     });
  //   } on AppwriteException catch (e) {
  //     print('Error: ${e.message}');
  //   }
  //
  //   setState(() {
  //     isLoading = false;
  //     isLoadingMore = false;
  //   });
  // }

  Future<void> _delVoiceData(String fileId) async {
    filesMap.clear();
    try {
      final storage = GetIt.I<Storage>();
      await storage.deleteFile(
        fileId: fileId,
        bucketId: AppwriteServices.bucketId,
      );
      getRecords();
    } on AppwriteException catch (e) {
      print(e);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoadingMore) {
      int nextPage = currentPage + 1;
      if (filesMap.length < totalItems) {
        setState(() {
          currentPage = nextPage;
        });
        getRecords(page: nextPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton:
      (!Constants.isUser)?
      FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceNoteScreen(),));
        },
        child: Container(
          decoration: BoxDecoration(
              color: Colors.blueGrey,
              border: Border.all(width: 2, color: Colors.blueGrey),
              borderRadius: BorderRadius.circular(5)),
          child: Icon(Icons.mic, color: Colors.white, size: 35,),
        ),
      ): null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('الألحان', style: TextStyle(color: Colors.black,fontSize: Constants.deviceWidth/18),),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Homepage(),), (route) => false,);
          },
          icon: Icon(Icons.arrow_back, color: Colors.black,size: Constants.arrowBackSize),
        ),
      ),
      body: isLoading
          ? Center(
        child: SpinKitWaveSpinner(
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
                  backgroundColor: WidgetStatePropertyAll(Colors.blueGrey)
              ),
              onPressed: () async {
                _connectivityService.isConnected
                    ? await _connectivityService.checkConnectivity(context, getRecords())
                    : _connectivityService.checkConnectivityWithoutActions(context);
              },
              icon: Icon(Icons.refresh, color: Colors.white, size: Constants.deviceWidth/15,),
            ),
            Text("إعادة المحاولة", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),)
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
              ListView.builder(
                      controller: _scrollController,
                      itemCount: filesMap.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
              if (index == filesMap.length) {
                return Center(
                  child: SpinKitWaveSpinner(
                    color: Colors.blueGrey,
                  ),
                );
              }

              String fileId = filesMap.keys.elementAt(index);
              String fileName = filesMap[fileId]!;
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
                      title: Center(
                        child: Text(
                          fileName,
                          style: TextStyle(fontSize: Constants.deviceWidth/18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      onTap: () async {
                        await _connectivityService.checkConnectivityWithoutActions(context);
                        if (_connectivityService.isConnected == true) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => DisplayVoiceAndLyrics(voiceId: fileId, voiceName: fileName,),
                          ));
                        }
                      },
                      onLongPress:
                          (!Constants.isUser)?
                          () {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.noHeader,
                          animType: AnimType.rightSlide,
                          title: 'أتريد حذف لحن $fileName؟',
                          btnCancelText: "حذف",
                          btnCancelOnPress: () async {
                            await _delVoiceData(fileId);
                          },
                        ).show();
                      }:
                          (){

                          }
                  ),
                ),
              );
                      },
                    ),
            ],
          ),
    );
  }
}