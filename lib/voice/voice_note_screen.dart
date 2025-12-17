import 'dart:async';

import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:attendance/voice/display_voice_notes.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
//import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter_sound/flutter_sound.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import '../helper/styles.dart';

class VoiceNoteScreen extends StatefulWidget {
  const VoiceNoteScreen({super.key});
  
  @override
  _VoiceNoteScreenState createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  //final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;

  bool _isLoading = false;
   final AudioPlayer _audioPlayer = AudioPlayer();


  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  GlobalKey<FormState> formState = GlobalKey();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _positionSubscription;

  @override
  void initState() {
    super.initState();
   // _player.openPlayer();
  }

  Future<void> _startRecording() async {
    _stopPlaying();
    if (await Permission.microphone.request().isGranted) {
      await _recorder.openRecorder();
      await _recorder.startRecorder(
        toFile: 'voice_note.aac',
      );
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    _filePath = await _recorder.stopRecorder();
    await _recorder.closeRecorder();
  // _filePath = await _recorder.stopRecorder();
  //   await _recorder.closeRecorder();

    setState(() {
      _isRecording = false;
    });
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
        _isPlaying = false; // Set inPlayMode to false when playback finishes
      });
      print("Playback completed.");
    });
  }

  Future<void> _playRecording() async {
    if (_filePath != null) {
      // await _player.startPlayer(
      //   fromURI: _filePath,
      //   codec: Codec.aacADTS,
      //   whenFinished: () {
      //     setState(() {
      //       _isPlaying = false;
      //     });
      //   },
      // );

      await _audioPlayer.play(UrlSource(_filePath!));
      setState(() {
        _isPlaying = true;
      });
    }
  }


  Future<void> _stopPlaying() async {
   // await _player.stopPlayer();
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _recorder.closeRecorder();
  //  _player.closePlayer();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _nameController.dispose();
    _descController.dispose();
  }


  Future<void> _uploadToAppwrite(String filePath, String txt,String desc) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final storage = GetIt.I<appwrite.Storage>();
      final databases = GetIt.I<appwrite.Databases>();

    final file=  await storage.createFile(
        bucketId: AppwriteServices.bucketId,
        fileId: appwrite.ID.unique(),
        file: appwrite.InputFile.fromPath(
          path: filePath,
          filename: txt,
        ),
      );
    await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.fielsDataCollectionId,
        documentId: file.$id,
        data: {
          "description": desc,
          "classId":Constants.classId ,

        });

      _nameController.clear();
      _descController.clear();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => DisplayVoiceNotes(),), (route) => false,);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content:

      Center(child: Text("تم إضافة اللحن ",))));


    } on AppwriteServices catch (e) {
      print('Error uploading file: $e');
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
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
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ElevatedButton(
              onPressed: () {
                if (formState.currentState!.validate()) {
                  if (_filePath != null) {
                    _stopPlaying();
                    _stopRecording();
                    _uploadToAppwrite(_filePath!, _nameController.text,_descController.text);
                  }
                  else{
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.white,
                        content: Center(child: Text("يجب تسجيل اللحن اولا",),)));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.blueGrey,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text(
                "حفظ",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
        title: Text('إضافة الألحان',style: TextStyle(fontSize: Constants.deviceWidth/20),),
      ),
      body:_isLoading?  Center(
        child:  Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
            color: Colors.white,
          ),

          child: SpinKitWaveSpinner(
            color: Colors.blueGrey,
          ),
        ),
      )  : Form(
        key: formState,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(

                  child: TextFormField(
                    style:Styles.textStyleSmall,

                    onTapOutside: (p) {
                      FocusScope.of(context).unfocus();
                    },
                    controller: _nameController,
                    maxLines: 1,
                    decoration: InputDecoration(
                    labelStyle:    Styles.textStyleSmall,

                      fillColor: Colors.white,
                      filled: true,
                      labelText: 'اسم اللحن..',
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0), // Adjust padding

                    ),
                    autovalidateMode:AutovalidateMode.onUnfocus ,
                    validator: (value) {
                      if (value == null||value.isEmpty) {
                        return "يجب كتابة اسم اللحن";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: Styles.textStyleSmall,
                  onTapOutside: (p) {
                    FocusScope.of(context).unfocus();
                  },
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelStyle: Styles.textStyleSmall,

                    labelText: 'كلمات اللحن...',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _isRecording ? 'يتم التسجيل...' : '',
                  style: Styles.textStyleSmall.copyWith(color: Colors.white),
                ),
                Container(
                  child: _isRecording ? SpinKitPulse(color: Colors.white) : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: _isRecording ? Colors.green : Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(fontSize: Constants.deviceWidth/15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //(_filePath != null&&_isRecording)?'انهاء التسجيل ':'إعادة تسجيل اللحن':
                      Text(
                        (_filePath==null && _isRecording==false)? 'بدء التسجيل ':

                        _isRecording ? 'انهاء التسجيل ' : 'إعادة تسجيل اللحن '
                     ,
                        style: TextStyle(
                          color: _isRecording ? Colors.white : Colors.black,
                        ),
                      ),
                      Icon(
                        Icons.mic,
                        size: Constants.deviceWidth/15,
                        color: _isRecording ? Colors.white : Colors.black,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                if (_filePath != null&&_isRecording==false)
                  // ElevatedButton(
                  //   onPressed: _isPlaying ? _stopPlaying : _playRecording,
                  //   style: ElevatedButton.styleFrom(
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //     backgroundColor: _isPlaying ? Colors.red : Colors.white,
                  //     padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  //     textStyle: TextStyle(fontSize: 18),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Text(
                  //         _isPlaying ? 'ايقاف التشغيل ' : 'تشغيل التسجيل ',
                  //         style: TextStyle(
                  //           color: _isPlaying ? Colors.white : Colors.black,
                  //         ),
                  //       ),
                  //       Icon(
                  //         _isPlaying ? Icons.stop : Icons.play_arrow,
                  //         color: _isPlaying ? Colors.white : Colors.black,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                         Card(
                  color: Colors.white,
                  child: SizedBox(
                    height: Constants.deviceHeight/4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Slider(
                                activeColor: Colors.blueGrey,
                                inactiveColor: Colors.black26,
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
                                    color: Colors.blueGrey,
                                  ),),
                                  Text(_formatDuration(_totalDuration),style: TextStyle(
                                    color: Colors.blueGrey,
                                  ),),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(    decoration: BoxDecoration(                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(10),
                              //   shape: BoxShape.circle
                            ),

                              child: IconButton(
                                icon: Icon(Icons.forward_10),
                                iconSize: Constants.deviceWidth/10,            color: Colors.white,

                                onPressed: () {
                                  int s = (_currentPosition.inSeconds.toInt() - 10);
                                  _audioPlayer.seek(Duration(seconds: s < 0 ? 0 : s));
                                },
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(10)
                             //   shape: BoxShape.circle
                              ),
                              child: IconButton(
                                icon: _isPlaying ? Icon(Icons.pause_circle_outline_outlined) : Icon(Icons.play_circle_outlined),
                                iconSize: Constants.deviceWidth/8,
                                color: Colors.white,
                                onPressed:!_isPlaying? _playRecording:_stopPlaying,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(                              color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(10),
                                //   shape: BoxShape.circle
                              ),
                              child: IconButton(
                                icon: Icon(Icons.replay_10),
                                iconSize: Constants.deviceWidth/10,
                                color: Colors.white,

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
        ),
      ),
    );
  }
}
