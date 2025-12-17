import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';

class UpdatePlayerImages extends StatefulWidget {
  const UpdatePlayerImages({super.key});
  
  @override
  State<UpdatePlayerImages> createState() => _UpdatePlayerImagesState();
}

class _UpdatePlayerImagesState extends State<UpdatePlayerImages> {
  bool isLoading = false;
  String status = '';
  int updatedCount = 0;
  int totalCount = 0;

  // Map of player names to their image URLs
  final Map<String, String> playerImageUrls = {
    // Goalkeepers
    'كورتوا': 'https://www.afronews24.com/wp-content/uploads/2023/08/%D8%AA%D9%8A%D8%A8%D9%88-%D9%83%D9%88%D8%B1%D8%AA%D9%88%D8%A7-scaled.webp',
    'تشيزنى': 'https://alawla.tv/uploads/posts/2024-09/1727200963.jpg',
    'اليسون بيكر': 'https://manhowa.com/wp-content/uploads/2022/11/%D8%A3%D9%84%D9%8A%D8%B3%D9%88%D9%86-%D8%A8%D9%8A%D9%83%D8%B1-Alisson-Becker%E2%80%8F.jpg',
    'ايدرسون': 'https://www.alyaum.com/uploads/images/2025/04/23/2564405.png',
    'الشناوى': 'https://sotelkora.com/wp-content/uploads/2024/04/73801.jpg',
    'عواد': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKBA6oua3QOzpO5uVS9mMdUJbECa9_X5etzg&s',
    
    // Center Backs
    'روديجر': 'https://www.al-watan.com/watanqatar/uploads/images/2023/04/11/89316.jpg',
    'كوبارسى': 'https://semedia.filgoal.com/Photos/Person/Medium/238743.png',
    'اروخو': 'https://www.elaosboa.com/wp-content/uploads/2022/09/elaosboa32519.jpg',
    'ميلتاو': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQfaeqG8f9GUTCYuHP6FPk_3-mqIrR24wpkbw&s',
    'فاندايك': 'https://semedia.filgoal.com/Photos/Person/Medium/22300.png',
    'ماركينوس': 'https://img.a.transfermarkt.technology/portrait/big/181767-1693900097.jpg?lm=1',
    'اكى': 'https://semedia.filgoal.com/Photos/Person/Medium/20421.png',
    'جفارديول': 'https://semedia.filgoal.com/Photos/Person/Medium/135045.png',
    'ياسر ابراهيم': 'https://semedia.filgoal.com/Photos/Person/Medium/22404.png',
    'حسام عبد المجيد': 'https://semedia.filgoal.com/Photos/Person/Medium/167538.png',
    
    // Right Backs
    'ارنولد': 'https://img.btolat.com/2025/6/18/news/373366/medium.jpg',
    'كارفخال': 'https://nrd.almawq3.com/wp-content/uploads/2024/10/444.jpg',
    'حكيمى': 'https://s.france24.com/media/display/35ab7288-5b88-11ee-a7d3-005056bf30b7/w:1280/p:1x1/78fa6287445e16cd82ce35d01673b0e155fbb0a2.jpg',
    'كوندى': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyADUnSNE2RsS3xK_ZbbkaSl7ZQxyxgKQpFA&s',
    'محمد هانى': 'https://semedia.filgoal.com/Photos/Person/Medium/24055.png',
    'عمر جابر': 'https://semedia.filgoal.com/Photos/Person/Medium/10185.png',
    
    // Left Backs
    'بالدى': 'https://semedia.filgoal.com/Photos/Person/Medium/221165.png',
    'روبيرتسون': 'https://fmcdn.alqaheranews.net/fab378d0-481e-11f0-8d1a-8d1151b68cda-file-1749795834073-787516473?&w=700&compress=80&gravity=face',
    'ديفيز': 'https://assets.bundesliga.com/contender/2024/11/bvb_fcb_2425_davies_1920.jpg?crop=285px,0px,1350px,1080px&fit=540,540',
    'كوكوريا': 'https://semedia.filgoal.com/Photos/Person/Medium/117379.png',
    'معلول': 'https://www.maspero.eg/image/750/450/2024/03/17102713980.jpg',
    'بنتايك': 'https://semedia.filgoal.com/Photos/Person/Medium/236006.png',
    
    // Midfielders
    'بيدرى': 'https://assets.goal.com/images/v3/bltfff171aa41869b23/bltfff171aa41869b23.jpg?auto=webp&format=pjpg&width=3840&quality=60',
    'جافى': 'https://www.algomhor.com/UploadCache/libfiles/18/3/600x338o/179.jpeg',
    'كامفينجا': 'https://cdn1-m.alittihad.ae/store/archive/image/2024/9/21/64063677-27dd-4bd3-a034-617a184bbc31.jpg',
    'فالفيردى': 'https://semedia.filgoal.com/Photos/Person/Medium/115454.png',
    'ماك اليستر': 'https://semedia.filgoal.com/Photos/Person/Medium/188380.png',
    'كيمتش': 'https://tarkesa.com/wp-content/uploads/2024/06/images-80.jpeg',
    'كوفاسيتش': 'https://semedia.filgoal.com/Photos/Person/Medium/17912.png',
    'دى بايول': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSF9zw5KUMq9yzN-6SIpwt8Gw0hlNxlGsusjhZivkzlMJWYlPUPFvcb0r-wz53kFaakfvA&usqp=CAU',
    'مودريتش': 'https://lukamodric-ar.com/storage/2024/07/%D9%84%D9%88%D9%83%D8%A7-%D9%85%D9%88%D8%AF%D8%B1%D9%8A%D8%AA%D8%B4-2.png',
    'أمام عاشور': 'https://misrconnect.com/storage/profiles/October2024/xzoiszyL7A6NSDN83NXT.png',
    'أحمد حمدى': 'https://alahalygate.com/wp-content/uploads/2025/01/%D8%A3%D8%AD%D9%85%D8%AF-%D8%AD%D9%85%D8%AF%D9%89.jpg',
    
    // Attacking Midfielders
    'ميسى': 'https://www.alyaum.com/uploads/images/2025/07/08/2620377.jpeg',
    'بلنجهام': 'https://img.a.transfermarkt.technology/portrait/big/581678-1748102891.jpg?lm=1',
    'دى بروين': 'https://www.mancity.com/meta/media/kk0ed2xm/kdb.jpg?width=1620',
    'سون': 'https://semedia.filgoal.com/Photos/Person/Medium/22558.png',
    'برونو فرنارديز': 'https://semedia.filgoal.com/Photos/Person/Medium/21619.png',
    'مجدى افشه': 'https://semedia.filgoal.com/Photos/Person/Medium/29049.png',
    'عبدالله سعيد': 'https://semedia.filgoal.com/Photos/Person/Medium/2948.png',
    
    // Wingers
    'صلاح': 'https://cnn-arabic-images.cnn.io/cloudinary/image/upload/w_1920,c_scale,q_auto/cnnarabic/2023/03/14/images/235334.jpg',
    'لامين': 'https://www.365scores.com/ar/news/magazine/wp-content/uploads/2025/05/photo_5859380001261079820_y-780x470.jpg',
    'ساكا': 'https://semedia.filgoal.com/Photos/Person/Medium/132101.png',
    'ديمبلى': 'https://cnn-arabic-images.cnn.io/cloudinary/image/upload/w_1920,c_scale,q_auto/cnnarabic/2024/04/17/images/266069.jpg',
    'رودريجو': 'https://www.akhbarkora.com/content/uploads/2025/07/06/b1b79a622b.jpg',
    'شيكابالا': 'https://mediaaws.almasryalyoum.com/news/medium/2024/08/11/2460411_0.jpg',
    'طاهر محمد': 'https://semedia.filgoal.com/Photos/Person/Medium/22552.png',
    'ڤينسيوس': 'https://maroc2030.medradio.ma/wp-content/uploads/sites/3/2024/08/20240827_171707.jpg',
    'رافينيا': 'https://roayahnews.com/wp-content/uploads/2025/02/raphinha.png',
    'فودين': 'https://semedia.filgoal.com/Photos/Person/Medium/102677.png',
    'كومان': 'https://semedia.filgoal.com/Photos/Person/Medium/23841.png',
    'لويس دياز': 'https://semedia.filgoal.com/Photos/Person/Medium/130988.png',
    'ترزيجيه': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSogMQm7tUNfCXqSF_Wn1rdQBeKCh5eEgF6-viZeh4EqnFa2gfjGyOUDvmMSf07FRZiPHo&usqp=CAU',
    'ابراهيم عادل': 'https://semedia.filgoal.com/Photos/Person/Medium/133777.png',
    
    // Strikers
    'كريستيانو': 'https://assets.kooora.com/images/v3/kooora_719100_1/2018-07-05-06865052_epa.jpg?quality=60&auto=webp&format=pjpg&width=1400',
    'امبابى': 'https://sabanew.net/upload/thumbs/168665372915138167.jpeg',
    'ليفاندوفسكي': 'https://s.hs-data.com/bilder/spieler/gross/119750.jpg?fallback=png',
    'هارى كين': 'https://m.media-amazon.com/images/M/MV5BN2EzNjA0Y2YtMTJmMy00OTI3LTkwMmItOGQ5YzE3NDU5Y2Y3XkEyXkFqcGc@._V1_.jpg',
    'هالاند': 'https://www.aljazeera.com/wp-content/uploads/2025/01/GettyImages-2191496062-1737106022.jpg?resize=1800%2C1800',
    'الفاريز': 'https://s.hs-data.com/bilder/spieler/gross/445514.jpg',
    'ناصر منسى': 'https://www.shorouknews.com/uploadedimages/Sections/Sports/original/naser-mansy-2025-8.jpg',
    'وسام ابوعلي': 'https://semedia.filgoal.com/Photos/Person/Medium/239697.png',
  };

  Future<void> updateAllPlayersWithImages() async {
    setState(() {
      isLoading = true;
      status = 'جاري البحث عن اللاعبين...';
      updatedCount = 0;
      totalCount = 0;
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      // First, get all players from the database
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.playersOfStudentCollectionId,
        queries: [
          appwrite.Query.limit(1000), // Get all players
        ],
      );

      totalCount = documents.documents.length;
      
      setState(() {
        status = 'تم العثور على $totalCount لاعب. جاري التحديث...';
      });

      // Update each player with their image URL
      for (var doc in documents.documents) {
        try {
          final playerData = doc.data;
          final playerName = playerData['nameOfPlayer'] ?? 
                           playerData['name'] ?? 
                           playerData['playerName'] ?? '';
          
          if (playerName.isNotEmpty && playerImageUrls.containsKey(playerName)) {
            // Check if player already has an image
        
            
            await databases.updateDocument(
              databaseId: AppwriteServices.databaseId,
              collectionId: AppwriteServices.playersOfStudentCollectionId,
              documentId: doc.$id,
              data: {
                'image': playerImageUrls[playerName]!,
              },
            );
            
            updatedCount++;
            setState(() {
              status = 'تم تحديث $updatedCount من $totalCount لاعب...';
            });
            
            print('✅ Updated $playerName with image URL');
            
            // Add small delay to avoid overwhelming the server
            await Future.delayed(Duration(milliseconds: 100));
            
          } else {
            print('⚠️ No image URL found for player: $playerName');
          }
        } catch (playerError) {
          print('❌ Error updating individual player: $playerError');
          // Continue with next player instead of stopping entire process
          continue;
        }
      }

      setState(() {
        status = 'تم تحديث $updatedCount لاعب من أصل $totalCount بنجاح!';
      });

    } on appwrite.AppwriteException catch (e) {
      setState(() {
        status = 'خطأ في Appwrite: ${e.message}';
      });
      print('AppwriteException: ${e.message}, Code: ${e.code}');
    } catch (e) {
      setState(() {
        status = 'حدث خطأ: $e';
      });
      print('General error updating players: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _testImageUrls(); // Debug: Test image URLs on startup
  }

  // Test method to verify image URLs (for debugging)
  void _testImageUrls() {
    print('Testing first few image URLs:');
    int count = 0;
    for (var entry in playerImageUrls.entries) {
      if (count >= 5) break; // Test only first 5
      print('Player: ${entry.key} -> URL: ${entry.value}');
      count++;
    }
    print('Total players with images: ${playerImageUrls.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحديث صور اللاعبين'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(
                color: Colors.blue,
              ),
            SizedBox(height: 20),
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            if (!isLoading)
              ElevatedButton(
                onPressed: updateAllPlayersWithImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'بدء تحديث صور اللاعبين',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            SizedBox(height: 20),
            Text(
              'سيتم تحديث ${playerImageUrls.length} لاعب بصورهم من Transfermarkt',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
