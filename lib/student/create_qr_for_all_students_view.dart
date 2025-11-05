import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../helper/constants.dart';
import '../helper/appwrite_services.dart';

class CreateQrForAllStudentsView extends StatefulWidget {
  const CreateQrForAllStudentsView({super.key});
  
  @override
  _CreateQrForAllStudentsViewState createState() => _CreateQrForAllStudentsViewState();
}

class _CreateQrForAllStudentsViewState extends State<CreateQrForAllStudentsView> {
  bool isLoading = false;

  // Helper function to parse birth date string into day, month, year
  Map<String, int> _parseBirthDate(String birthdayDate) {
    if (birthdayDate.isEmpty) {
      return {'birthDay': 0, 'birthMonth': 0, 'birthYear': 0};
    }
    
    try {
      // Try different date formats
      
      // Format 1: dd/MM/yyyy
      if (birthdayDate.contains('/')) {
        List<String> parts = birthdayDate.split('/');
        if (parts.length == 3) {
          int day = int.tryParse(parts[0]) ?? 0;
          int month = int.tryParse(parts[1]) ?? 0;
          int year = int.tryParse(parts[2]) ?? 0;
          return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
        }
      }
            // Format 1: dd/MM/yyyy
      if (birthdayDate.contains('\\')) {
        List<String> parts = birthdayDate.split('\\');
        if (parts.length == 3) {
          int day = int.tryParse(parts[0]) ?? 0;
          int month = int.tryParse(parts[1]) ?? 0;
          int year = int.tryParse(parts[2]) ?? 0;
          return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
        }
      }
      
      // Format 2: dd-MM-yyyy
      if (birthdayDate.contains('-')) {
        List<String> parts = birthdayDate.split('-');
        if (parts.length == 3) {
          // Check if it's yyyy-MM-dd format
          if (parts[0].length == 4) {
            int day = int.tryParse(parts[2]) ?? 0;
            int month = int.tryParse(parts[1]) ?? 0;
            int year = int.tryParse(parts[0]) ?? 0;
            return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
          } else {
            // dd-MM-yyyy format
            int day = int.tryParse(parts[0]) ?? 0;
            int month = int.tryParse(parts[1]) ?? 0;
            int year = int.tryParse(parts[2]) ?? 0;
            return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
          }
        }
      }
      
      // Format 3: dd.MM.yyyy
      if (birthdayDate.contains('.')) {
        List<String> parts = birthdayDate.split('.');
        if (parts.length == 3) {
          int day = int.tryParse(parts[0]) ?? 0;
          int month = int.tryParse(parts[1]) ?? 0;
          int year = int.tryParse(parts[2]) ?? 0;
          return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
        }
      }
      
      // If no separator, try to parse as ddMMyyyy
      if (birthdayDate.length == 8) {
        int day = int.tryParse(birthdayDate.substring(0, 2)) ?? 0;
        int month = int.tryParse(birthdayDate.substring(2, 4)) ?? 0;
        int year = int.tryParse(birthdayDate.substring(4, 8)) ?? 0;
        return {'birthDay': day, 'birthMonth': month, 'birthYear': year};
      }
      
    } catch (e) {
      print('Error parsing birth date: $birthdayDate - $e');
    }
    
    // Return defaults if parsing fails
    return {'birthDay': 0, 'birthMonth': 0, 'birthYear': 0};
  }



  Future<void> loadExcelDataForOldStudentsWhoseHaveIds(String filePath) async {
    var file = File(filePath);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<Map<String, dynamic>> studentRecords = [];

    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows;

      for (var i = 0; i < rows.length; i++) {
        var row = rows[i];

        // Skip the first row (header)
        if (i == 0) continue;

        if (row.isNotEmpty) {
          String name = _getStringValue(row[1]);
          String address = _getStringValue(row[3]);
          String region = _getStringValue(row[2]);
          String birthdayDate = _getStringValue(row[4]);
          String phone1 = _getStringValue(row[5]);
          String phone2 = _getStringValue(row[6]);
          String id = _getStringValue(row[7]);
          String abEle3traf = _getStringValue(row[8]);
          String notes = _getStringValue(row[9]);
          String faceBookLink = _getStringValue(row[10]);
          String tiktokLink = _getStringValue(row[11]);
          String instgramLink = _getStringValue(row[12]);

          // Parse birth date into separate fields
          Map<String, int> parsedBirthDate = _parseBirthDate(birthdayDate);

          studentRecords.add({
            'name': name,
            'address': address,
            'region': region,
            'birthDay': parsedBirthDate['birthDay'],
            'birthMonth': parsedBirthDate['birthMonth'],
            'birthYear': parsedBirthDate['birthYear'],
            'phone1': phone1,
            'phone2': phone2,
            '\$id': id,
            'abEle3traf': abEle3traf,
            'notes': notes,
            'faceBookLink': faceBookLink,
            'instgramLink': instgramLink,
            'tiktokLink': tiktokLink,
            'meetings': [], // Assuming meetings are initially empty
            'alhanCounter': 0,
            'qudasCounter': 0,
            'tasbhaCounter': 0,
            'madrasAhadCounter': 0,
            'ejtimaCounter': 0,
            'totalCounter': 0,
            'bonus': 0,
            'classId': Constants.classId,
            'password': generateUniquePassword(),
          });
        }
      }
    }
    await uploadToAppwriteWithCustomIds(studentRecords);
  }

  Future<void> pickFileForOldStudents() async {
    setState(() {
      isLoading = true;
    });
    String? filePath = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    ).then((result) => result?.files.single.path);

    if (filePath != null) {
      await loadExcelDataForOldStudentsWhoseHaveIds(filePath);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadExcelData(String filePath) async {
    var file = File(filePath);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<Map<String, dynamic>> studentRecords = [];

    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows;

      for (var i = 0; i < rows.length; i++) {
        var row = rows[i];

        // Skip the first row (header)
        if (i == 0) continue;

        if (row.isNotEmpty) {
          String name = _getStringValue(row[1]);
          String address = _getStringValue(row[3]);
          String region = _getStringValue(row[2]);
          String birthdayDate = _getStringValue(row[4]);
          String phone1 = _getStringValue(row[5]);
          String phone2 = _getStringValue(row[6]);
         String id = _getStringValue(row[7]);
          String abEle3traf = _getStringValue(row[8]);
          String notes = _getStringValue(row[9]);
          String faceBookLink = _getStringValue(row[10]);
          String tiktokLink = _getStringValue(row[11]);
          String instgramLink = _getStringValue(row[12]);
          
          // Parse birth date into separate fields
          Map<String, int> parsedBirthDate = _parseBirthDate(birthdayDate);
          
          studentRecords.add({
            'name': name,
            'address': address,
            'region': region,
            'birthDay': parsedBirthDate['birthDay'],
            'birthMonth': parsedBirthDate['birthMonth'],
            'birthYear': parsedBirthDate['birthYear'],
            'phone1': phone1,
            'phone2': phone2,
            '\$id': id,
            'meetings': [], 
              'abEle3traf': abEle3traf,
            'notes': notes,
            'faceBookLink': faceBookLink,
            'instgramLink': instgramLink,
            'tiktokLink': tiktokLink,// Assuming meetings are initially empty
            'alhanCounter': 0,
            'qudasCounter': 0,
            'tasbhaCounter': 0,
            'madrasAhadCounter': 0,
            'ejtimaCounter': 0,
            'totalCounter': 0,
            'bonus': 0,
            'classId': Constants.classId,
            'password': generateUniquePassword(),
          });
        }
      }
    }
    await uploadToAppwrite(studentRecords);
  }

  String _getStringValue(dynamic cell) {
    if (cell == null) return '';
    if (cell.value is String) return cell.value as String;
    if (cell.value is TextCellValue) return (cell.value as TextCellValue).value.toString();
    if (cell.value is int || cell.value is double) return cell.value.toString();

    // Check if the cell is a date and format it
    if (cell.value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(cell.value); // Change format as needed
    }

    return '';
  }

  Future<void> uploadToAppwrite(List<Map<String, dynamic>> studentRecords) async {
    final databases = GetIt.I<Databases>();
    int batchSize = 50; // Smaller batch size for better reliability
    int totalBatches = (studentRecords.length / batchSize).ceil();
    int successCount = 0;
    int errorCount = 0;
    List<String> failedRecords = [];

    // Show initial progress
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('بدء رفع ${studentRecords.length} سجل في $totalBatches مجموعة'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      int startIndex = batchIndex * batchSize;
      int endIndex = (startIndex + batchSize < studentRecords.length) 
          ? startIndex + batchSize 
          : studentRecords.length;
      
      List<Map<String, dynamic>> batch = studentRecords.sublist(startIndex, endIndex);
      
      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('معالجة المجموعة ${batchIndex + 1} من $totalBatches (${batch.length} سجل)'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }

      // Process each item in batch with retry logic
      for (var record in batch) {
        bool uploaded = false;
        int retryCount = 0;
        int maxRetries = 3;
        
        while (!uploaded && retryCount < maxRetries) {
          try {
            // Remove $id from data before uploading (in case it exists)
            Map<String, dynamic> dataWithoutId = Map.from(record);
            dataWithoutId.remove('\$id');
            
            await databases.createDocument(
              databaseId: AppwriteServices.databaseId,
              collectionId: AppwriteServices.studentsCollectionId,
              documentId: ID.unique(),
              data: dataWithoutId,
              permissions: [
                Permission.read(Role.any()),
                Permission.write(Role.any()),
              ],
            );
            successCount++;
            uploaded = true;
            
            // Small delay between individual uploads
            await Future.delayed(Duration(milliseconds: 100));
            
          } catch (e) {
            retryCount++;
            print('Attempt $retryCount failed for record ${record['name']}: $e');
            
            if (retryCount < maxRetries) {
              // Wait longer before retry
              await Future.delayed(Duration(milliseconds: 1000 * retryCount));
            } else {
              errorCount++;
              failedRecords.add('${record['name']}');
              print('Final failure for record ${record['name']} after $maxRetries attempts: $e');
            }
          }
        }
      }
      
      // Longer delay between batches
      if (batchIndex < totalBatches - 1) {
        await Future.delayed(Duration(seconds: 2));
      }
    }

    // Show final results
    if (mounted) {
      String message = 'تم رفع $successCount سجل بنجاح.';
      if (errorCount > 0) {
        message += ' فشل $errorCount سجل.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 5),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      
      // Show failed records if any
      if (failedRecords.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('السجلات التي فشل رفعها'),
            content: SingleChildScrollView(
              child: Text(failedRecords.join('\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('موافق'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> uploadToAppwriteWithCustomIds(List<Map<String, dynamic>> studentRecords) async {
    final databases = GetIt.I<Databases>();
    int batchSize = 50; // Smaller batch size for better reliability
    int totalBatches = (studentRecords.length / batchSize).ceil();
    int successCount = 0;
    int errorCount = 0;
    List<String> failedRecords = [];

    // Show initial progress
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('بدء رفع ${studentRecords.length} سجل في $totalBatches مجموعة'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      int startIndex = batchIndex * batchSize;
      int endIndex = (startIndex + batchSize < studentRecords.length) 
          ? startIndex + batchSize 
          : studentRecords.length;
      
      List<Map<String, dynamic>> batch = studentRecords.sublist(startIndex, endIndex);
      
      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('معالجة المجموعة ${batchIndex + 1} من $totalBatches (${batch.length} سجل)'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }

      // Process each item in batch with retry logic
      for (var record in batch) {
        bool uploaded = false;
        int retryCount = 0;
        int maxRetries = 3;
        
        while (!uploaded && retryCount < maxRetries) {
          try {
            String customId = record['\$id'] ?? ID.unique();
            // Remove $id from data before uploading
            Map<String, dynamic> dataWithoutId = Map.from(record);
            dataWithoutId.remove('\$id');
            
            await databases.createDocument(
              databaseId: AppwriteServices.databaseId,
              collectionId: AppwriteServices.studentsCollectionId,
              documentId: customId,
              data: dataWithoutId,
              permissions: [
                Permission.read(Role.any()),
                Permission.write(Role.any()),
              ],
            );
            successCount++;
            uploaded = true;
            
            // Small delay between individual uploads
            await Future.delayed(Duration(milliseconds: 100));
            
          } catch (e) {
            retryCount++;
            print('Attempt $retryCount failed for record ${record['name']} (ID: ${record['\$id']}): $e');
            
            if (retryCount < maxRetries) {
              // Wait longer before retry
              await Future.delayed(Duration(milliseconds: 1000 * retryCount));
            } else {
              errorCount++;
              failedRecords.add('${record['name']} (ID: ${record['\$id']})');
              print('Final failure for record ${record['name']} after $maxRetries attempts: $e');
            }
          }
        }
      }
      
      // Longer delay between batches
      if (batchIndex < totalBatches - 1) {
        await Future.delayed(Duration(seconds: 2));
      }
    }

    // Show final results
    if (mounted) {
      String message = 'تم رفع $successCount سجل بنجاح.';
      if (errorCount > 0) {
        message += ' فشل $errorCount سجل.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 5),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      
      // Show failed records if any
      if (failedRecords.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('السجلات التي فشل رفعها'),
            content: SingleChildScrollView(
              child: Text(failedRecords.join('\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('موافق'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> pickFile() async {
    setState(() {
      isLoading = true;
    });
    String? filePath = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    ).then((result) => result?.files.single.path);

    if (filePath != null) {
      await loadExcelData(filePath);
    }

    setState(() {
      isLoading = false;
    });
  }
  Set<String> usedPasswords = {};
  String generateUniquePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random random = Random();
    String password;

    do {
      password = List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
    } while (usedPasswords.contains(password));

    usedPasswords.add(password); // Add generated password to set
    return password;
  }


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة أكثر من مخدوم', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
         leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back,size: Constants.arrowBackSize,color: Colors.white,),
        ),
      ),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('جارِ المعالجة...', style: TextStyle(fontSize: 16)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MaterialButton(
                    height: 100,
                    color: Colors.green,
                    onPressed: pickFile,
                    child: Text(
                      'ادراج شيت Excel (QR جديد)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(height: 20),
                  MaterialButton(
                    height: 100,
                    color: Colors.blue,
                    onPressed: pickFileForOldStudents,
                    child: Text(
                      'ادراج شيت Excel (QR موجود مسبقا)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}