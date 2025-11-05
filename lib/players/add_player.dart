import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import '../helper/appwrite_services.dart';
import 'update_player_images.dart';

class AddPlayer extends StatefulWidget {
  const AddPlayer({super.key});

  @override
  State<AddPlayer> createState() => _AddPlayerState();
}

class _AddPlayerState extends State<AddPlayer> {
  final List<Map<String, dynamic>> players = [
    // Goalkeepers
    {'nameOfPlayer': 'كورتوا', 'price': 70},
    {'nameOfPlayer': 'تشيزنى', 'price': 70},
    {'nameOfPlayer': 'اليسون بيكر', 'price': 50},
    {'nameOfPlayer': 'ايدرسون', 'price': 40},
    {'nameOfPlayer': 'الشناوى', 'price': 20},
    {'nameOfPlayer': 'عواد', 'price': 20},

    // Defenders
    {'nameOfPlayer': 'روديجر', 'price': 65},
    {'nameOfPlayer': 'كوبارسى', 'price': 65},
    {'nameOfPlayer': 'اروخو', 'price': 60},
    {'nameOfPlayer': 'ميلتاو', 'price': 60},
    {'nameOfPlayer': 'فاندايك', 'price': 50},
    {'nameOfPlayer': 'ماركينوس', 'price': 40},
    {'nameOfPlayer': 'اكى', 'price': 30},
    {'nameOfPlayer': 'جفارديول', 'price': 40},
    {'nameOfPlayer': 'ياسر ابراهيم', 'price': 20},
    {'nameOfPlayer': 'حسام عبد المجيد', 'price': 20},

    // Right Backs
    {'nameOfPlayer': 'ارنولد', 'price': 60},
    {'nameOfPlayer': 'كارفخال', 'price': 50},
    {'nameOfPlayer': 'حكيمى', 'price': 40},
    {'nameOfPlayer': 'كوندى', 'price': 50},
    {'nameOfPlayer': 'محمد هانى', 'price': 20},
    {'nameOfPlayer': 'عمر جابر', 'price': 20},

    // Left Backs
    {'nameOfPlayer': 'بالدى', 'price': 60},
    {'nameOfPlayer': 'روبيرتسون', 'price': 60},
    {'nameOfPlayer': 'ديفيز', 'price': 50},
    {'nameOfPlayer': 'كوكوريا', 'price': 40},
    {'nameOfPlayer': 'معلول', 'price': 20},
    {'nameOfPlayer': 'بنتايك', 'price': 20},

    // Midfielders
    {'nameOfPlayer': 'بيدرى', 'price': 80},
    {'nameOfPlayer': 'جافى', 'price': 70},
    {'nameOfPlayer': 'كامفينجا', 'price': 60},
    {'nameOfPlayer': 'فالفيردى', 'price': 80},
    {'nameOfPlayer': 'ماك اليستر', 'price': 60},
    {'nameOfPlayer': 'كيمتش', 'price': 70},
    {'nameOfPlayer': 'كوفاسيتش', 'price': 40},
    {'nameOfPlayer': 'دى بايول', 'price': 50},
    {'nameOfPlayer': 'مودريتش', 'price': 70},
    {'nameOfPlayer': 'أمام عاشور', 'price': 20},
    {'nameOfPlayer': 'أحمد حمدى', 'price': 20},

    // Playmakers
    {'nameOfPlayer': 'ميسى', 'price': 85},
    {'nameOfPlayer': 'بلنجهام', 'price': 85},
    {'nameOfPlayer': 'دى بروين', 'price': 70},
    {'nameOfPlayer': 'سون', 'price': 60},
    {'nameOfPlayer': 'برونو فرنارديز', 'price': 60},
    {'nameOfPlayer': 'مجدى افشه', 'price': 20},
    {'nameOfPlayer': 'عبدالله سعيد', 'price': 20},

    // Right Wingers
    {'nameOfPlayer': 'صلاح', 'price': 90},
    {'nameOfPlayer': 'لامين', 'price': 90},
    {'nameOfPlayer': 'ساكا', 'price': 70},
    {'nameOfPlayer': 'ديمبلى', 'price': 80},
    {'nameOfPlayer': 'رودريجو', 'price': 60},
    {'nameOfPlayer': 'شيكابالا', 'price': 20},
    {'nameOfPlayer': 'طاهر محمد', 'price': 20},

    // Left Wingers
    {'nameOfPlayer': 'ڤينسيوس', 'price': 90},
    {'nameOfPlayer': 'رافينيا', 'price': 90},
    {'nameOfPlayer': 'فودين', 'price': 80},
    {'nameOfPlayer': 'كومان', 'price': 80},
    {'nameOfPlayer': 'لويس دياز', 'price': 70},
    {'nameOfPlayer': 'ترزيجيه', 'price': 20},
    {'nameOfPlayer': 'ابراهيم عادل', 'price': 20},

    // Forwards
    {'nameOfPlayer': 'كريستيانو', 'price': 100},
    {'nameOfPlayer': 'امبابى', 'price': 90},
    {'nameOfPlayer': 'ليفاندوفسكي', 'price': 90},
    {'nameOfPlayer': 'هارى كين', 'price': 80},
    {'nameOfPlayer': 'هالاند', 'price': 80},
    {'nameOfPlayer': 'الفاريز', 'price': 70},
    {'nameOfPlayer': 'ناصر منسى', 'price': 20},
    {'nameOfPlayer': 'وسام ابوعلي', 'price': 20},
  ];

  bool isLoading = false;

  Future<void> addPlayers() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();

      for (var player in players) {
        await databases.createDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.playersOfStudentCollectionId,
          documentId: 'unique()', // Use unique() to generate a unique document ID
          data: {
            'nameOfPlayer': player['nameOfPlayer'],
            'price': player['price'],
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Players added successfully!'),
        backgroundColor: Colors.green,
      ));

    } on appwrite.AppwriteException catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding players: ${e.message}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة لاعبين'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator() // Show loading indicator
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: addPlayers,
                    child: Text('إضافة لاعبين'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdatePlayerImages(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      'تحديث صور اللاعبين',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}