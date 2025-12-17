import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:get_it/get_it.dart';
import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'dart:typed_data';

class AddPlayerOfTheMonthPage extends StatefulWidget {
  final String classId;
  final String className;

  const AddPlayerOfTheMonthPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AddPlayerOfTheMonthPage> createState() => _AddPlayerOfTheMonthPageState();
}

class _AddPlayerOfTheMonthPageState extends State<AddPlayerOfTheMonthPage> {
  final TextEditingController _playerNameController = TextEditingController();
  bool _isLoading = false;
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _fileBytes = result.files.first.bytes;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPlayerOfTheMonth() async {
    if (_playerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال اسم الطالب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFile == null || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار صورة الطالب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = GetIt.I<appwrite.Storage>();

      // Create custom filename using student name and class
      final studentName = _playerNameController.text.trim();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _selectedFile!.name.split('.').last;
      final customFileName = '${widget.className}_${studentName}_player_of_month_$timestamp.$fileExtension';
      
      // Only upload image to storage - no database entry needed
      await storage.createFile(
        bucketId: AppwriteServices.studentImagesBucketId,
        fileId: appwrite.ID.unique(),
        file: appwrite.InputFile.fromBytes(
          bytes: _fileBytes!,
          filename: customFileName,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع صورة $studentName كلاعب الشهر بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form and go back
      _playerNameController.clear();
      setState(() {
        _selectedFile = null;
        _fileBytes = null;
      });
      
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع صورة الطالب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'إضافة طالب لاعب الشهر',
          style: TextStyle(
            fontSize: screenWidth / 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: "NotoSansArabic",
          ),
        ),
        backgroundColor: Colors.amber[600],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage(Constants.footballStadium),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: screenWidth * 0.15,
                        color: Colors.amber,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'فصل: ${widget.className}',
                        style: TextStyle(
                          fontSize: screenWidth / 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                          fontFamily: "NotoSansArabic",
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Student Name Input
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _playerNameController,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: "NotoSansArabic",
                      fontSize: screenWidth / 22,
                    ),
                    decoration: InputDecoration(
                      labelText: 'اسم الطالب',
                      labelStyle: TextStyle(
                        fontFamily: "NotoSansArabic",
                        color: Colors.blueGrey,
                      ),
                      hintText: 'أدخل اسم الطالب لاعب الشهر',
                      hintStyle: TextStyle(
                        fontFamily: "NotoSansArabic",
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Image Upload Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'صورة الطالب',
                        style: TextStyle(
                          fontSize: screenWidth / 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[700],
                          fontFamily: "NotoSansArabic",
                        ),
                      ),
                      SizedBox(height: 15),
                      
                      // Image Preview
                      Container(
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _fileBytes != null ? Colors.amber : Colors.grey[300]!,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _fileBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _fileBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: screenWidth * 0.15,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'اختر صورة الطالب',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontFamily: "NotoSansArabic",
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Pick Image Button
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.photo_library, color: Colors.white),
                        label: Text(
                          'اختار صورة',
                          style: TextStyle(
                            fontFamily: "NotoSansArabic",
                            fontSize: screenWidth / 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Upload Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _uploadPlayerOfTheMonth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'حفظ كلاعب الشهر',
                            style: TextStyle(
                              fontSize: screenWidth / 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "NotoSansArabic",
                            ),
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