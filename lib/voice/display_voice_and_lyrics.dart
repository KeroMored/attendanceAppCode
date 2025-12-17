import 'dart:async';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class DisplayVoiceAndLyrics extends StatefulWidget {
  final String voiceId;
  final String voiceName;
  const DisplayVoiceAndLyrics({super.key, required this.voiceId, required this.voiceName,});

  @override
  _DisplayVoiceAndLyricsState createState() => _DisplayVoiceAndLyricsState();
}

class _DisplayVoiceAndLyricsState extends State<DisplayVoiceAndLyrics> {
  Map<String,dynamic> documentData ={};
  late AudioPlayer _audioPlayer;
  bool isLoading = true;
  bool inPlayMode = false;
  bool playAnother = false;
  String? _localFilePath;
  String? error;
  String desc ="";
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _positionSubscription;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    _fetchVoiceNote();
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        inPlayMode = false; // Set inPlayMode to false when playback finishes
      });
      print("Playback completed.");
    });
  }

  Future<void> _fetchVoiceNote() async {
    try {
      final storage = GetIt.I<Storage>();
      final databases = GetIt.I<Databases>();
      final bytes = await storage.getFileView(
        bucketId: AppwriteServices.bucketId,
        fileId: widget.voiceId,
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/voice_note_${widget.voiceId}.mp3';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final voiceDescription =   await  databases.getDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.fielsDataCollectionId,
          documentId: widget.voiceId);
      documentData =voiceDescription.data;
      print("Downloaded audio file saved at: $filePath");
      setState(() {
        _localFilePath = filePath;
        isLoading = false;
      });
    } on AppwriteException catch (e) {
      print('Error fetching voice note: ${e.message}');
      setState(() {
        error = e.message;
        isLoading = false;
      });
    } catch (e) {
      print('Unexpected error: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _playVoiceNote() async {
    if (_localFilePath != null) {
      try {
        if (!inPlayMode) {
          await _audioPlayer.play(DeviceFileSource(_localFilePath!));
          setState(() {
            inPlayMode = true;
          });
        } else {
          await _audioPlayer.pause();
          setState(() {
            inPlayMode = false;
          });
        }
        print("Playback started.");
      } catch (e) {
        print("Error during playback: $e");
      }
    } else {
      print("No local file available to play.");
    }
  }


  @override
  void dispose() {
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(widget.voiceName,style: TextStyle(
            fontSize: Constants.deviceWidth/22   ,
            color: Colors.white,fontWeight: FontWeight.bold),),
        centerTitle: true,
        leading: IconButton(onPressed: () {
Navigator.pop(context);
}, icon: Icon(Icons.arrow_back,color: Colors.white,size:  Constants.arrowBackSize)),

      ),
      body: (isLoading == true || _localFilePath == null)
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : error != null
          ? Center(child: Text('Error: $error'))
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Center(child: Text(

                          documentData["description"]==""?"لم يتم إضافة كلمات اللحن":documentData["description"],

                          style: TextStyle(fontSize: Constants.deviceWidth/18),)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              color: Colors.blueGrey,
              child: SizedBox(
                height: Constants.deviceHeight/4.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Slider(
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey,
                            value: _currentPosition.inSeconds.toDouble(),
                            min: 0,
                            max: _totalDuration.inSeconds.toDouble(),
                            onChanged: (double value) {
                              setState(() {
                                _currentPosition = Duration(seconds: value.toInt());
                              });
                            },
                            onChangeEnd: (double value) async {
                              final position = Duration(seconds: value.toInt());
                              await _audioPlayer.seek(position);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_currentPosition),style: TextStyle(
                                color: Colors.white,
                              fontSize:  Constants.deviceWidth/25,

                              ),),
                              Text(_formatDuration(_totalDuration),style: TextStyle(
                                fontSize:  Constants.deviceWidth/25,
                                color: Colors.white,
                              ),),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(   decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          //   shape: BoxShape.circle
                        ),
                          child: IconButton(
                            icon: Icon(Icons.forward_10),
                            iconSize: Constants.deviceWidth/12,
                            color: Colors.blueGrey,

                            onPressed: () {
                              int s = (_currentPosition.inSeconds.toInt() - 10);
                              _audioPlayer.seek(Duration(seconds: s < 0 ? 0 : s));
                            },
                          ),
                        ),
                        Container(   decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          //   shape: BoxShape.circle
                        ),
                          child: IconButton(
                            icon: inPlayMode ? Icon(Icons.pause_circle_outline_outlined) : Icon(Icons.play_circle_outlined),
                            iconSize: Constants.deviceWidth/10,
                            color: Colors.blueGrey,
                            onPressed: _playVoiceNote,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            //   shape: BoxShape.circle
                          ),
                          child: IconButton(
                            icon: Icon(Icons.replay_10),
                            iconSize: Constants.deviceWidth/12,
                            color: Colors.blueGrey,

                            onPressed: () {
                              int s = (_currentPosition.inSeconds.toInt() + 10);
                              _audioPlayer.seek(Duration(seconds: s > _totalDuration.inSeconds ? _totalDuration.inSeconds : s));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}