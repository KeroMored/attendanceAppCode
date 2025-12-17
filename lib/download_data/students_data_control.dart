import 'dart:io';
import 'dart:math' as math;

import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' as root_bundle;
import 'package:url_launcher/url_launcher.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';


import 'package:flutter/services.dart';
class StudentsDataControl extends StatefulWidget {
  const StudentsDataControl({super.key});

  @override
  State<StudentsDataControl> createState() => _StudentsDataControlState();
}

class _StudentsDataControlState extends State<StudentsDataControl> {
  List<Map<String, dynamic>> studentData = [];
  bool isLoading = false;
  bool isPdfLoading = false;
  bool isExcelLoading = false; 
   bool isExcelForMonthLoading = false;

  bool isPasswordPdfLoading = false;

  Future<void> getAllData(int num) async {
    studentData.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.blueGrey,
      duration: Duration(seconds: 3),
      content: Row(
        children: [
          Container(
              color: Colors.white,
              child: Icon(Icons.info, color: Colors.blueGrey, size: 20)),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              'يتم تجهيز الملف',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    ));

    int offset = 0; // Initialize offset for pagination
    const int limit = 500; // Set a limit for the number of documents per request

    try {
      final databases = GetIt.I<appwrite.Databases>();

      while (true) {
        final documents = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.studentsCollectionId,
          queries: [
            appwrite.Query.equal('classId', Constants.classId),
          num == 1?
            appwrite.Query.orderAsc("name"):
            appwrite.Query.orderDesc("\$createdAt"),
            appwrite.Query.limit(limit),
            appwrite.Query.offset(offset),
          ],
        );

        if (documents.documents.isEmpty) {
          break; // Exit loop if no more documents are available
        }

        studentData.addAll(documents.documents.map((doc) => doc.data).toList());
        offset += limit; // Increment offset for the next batch
      }
    } on appwrite.AppwriteException catch (e) {
      print('Error fetching data: ${e.message}');
    } finally {
      
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<void> _requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      // Permission granted
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('إذن الوصول للبيانات مغلق'),
      ));
    }
  }

  Future<Uint8List> loadAdditionalImage() async {
    return await root_bundle.rootBundle
        .load(Constants.saintMaria) // Replace with your image path
        .then((byteData) => byteData.buffer.asUint8List());
  }

  Future<void> _downloadPDF(List<Map<String, dynamic>> studentData) async {
    setState(() {
      isPdfLoading = true;
    });

    try {
      await Permission.storage.request();
      await getAllData(2); // Ensure this fetches data correctly

      if (await Permission.storage.isGranted) {
        final pdf = pw.Document();
        final Uint8List fontData = await loadFont();
        final ttf = pw.Font.ttf(fontData.buffer.asByteData());
        final logoImage = await loadAdditionalImage();
        final backgroundImage = await loadAdditionalImage();

        // Process students in groups of 6 (2x3 layout)
        for (int i = 0; i < studentData.length; i += 6) {
          final List<Map<String, dynamic>> pageStudents = studentData.skip(i).take(6).toList();
          
          // Generate QR codes for this page's students
          final List<Uint8List> qrCodes = [];
          for (var student in pageStudents) {
            final qrData = student['\$id'];
            final pngData = await _generateQRCodeImage(qrData);
            qrCodes.add(pngData);
          }
          
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Padding(
                  padding: pw.EdgeInsets.all(10),
                  child: pw.Column(
                    children: [
                      // Page header
                      pw.Container(
                        margin: pw.EdgeInsets.only(bottom: 15),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Image(pw.MemoryImage(logoImage), width: 40, height: 40),
                            pw.SizedBox(width: 10),
                            // pw.Text(
                            //   "بطاقات حضور رقمية - كنيسة العذراء مريم بالصاغة",
                            //   style: pw.TextStyle(
                            //     fontSize: 16,
                            //     font: ttf,
                            //     fontWeight: pw.FontWeight.bold,
                            //     color: PdfColors.black,
                            //   ),
                            //   textDirection: pw.TextDirection.rtl,
                            // ),
                          ],
                        ),
                      ),
                      
                      // Students grid (2 columns x 3 rows)
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            // First row (2 students)
                            pw.Expanded(
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (pageStudents.length > 0)
                                    _buildStudentCard(pageStudents[0], qrCodes[0], ttf, backgroundImage, logoImage),
                                  if (pageStudents.length > 1)
                                    _buildStudentCard(pageStudents[1], qrCodes[1], ttf, backgroundImage, logoImage),
                                ],
                              ),
                            ),
                            
                            pw.SizedBox(height: 10),
                            
                            // Second row (2 students)
                            pw.Expanded(
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (pageStudents.length > 2)
                                    _buildStudentCard(pageStudents[2], qrCodes[2], ttf, backgroundImage, logoImage),
                                  if (pageStudents.length > 3)
                                    _buildStudentCard(pageStudents[3], qrCodes[3], ttf, backgroundImage, logoImage),
                                ],
                              ),
                            ),
                            
                            pw.SizedBox(height: 10),
                            
                            // Third row (2 students)
                            pw.Expanded(
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (pageStudents.length > 4)
                                    _buildStudentCard(pageStudents[4], qrCodes[4], ttf, backgroundImage, logoImage),
                                  if (pageStudents.length > 5)
                                    _buildStudentCard(pageStudents[5], qrCodes[5], ttf, backgroundImage, logoImage),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Page footer
                      pw.Container(
                        margin: pw.EdgeInsets.only(top: 10),
                        child: pw.Text(
                          "صفحة ${(i ~/ 6) + 1} من ${((studentData.length - 1) ~/ 6) + 1}",
                          style: pw.TextStyle(
                            fontSize: 10,
                            font: ttf,
                            color: PdfColors.grey600,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('إذن الوصول للملفات مغلق')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في تحميل PDF'),
        ),
      );
    } finally {
      setState(() {
        isPdfLoading = false;
      });
    }
  }

  // Helper method to build individual student card
  pw.Widget _buildStudentCard(Map<String, dynamic> student, Uint8List qrCode, pw.Font ttf, Uint8List backgroundImage, Uint8List logoImage) {
    return pw.Container(
      width: 180,
      height: 220,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(15),
        border: pw.Border.all(color: PdfColors.grey300, width: 2),
      ),
      child: pw.Stack(
        children: [
          // Background image with low opacity
          pw.Positioned.fill(
            child: pw.ClipRRect(
              horizontalRadius: 13,
              verticalRadius: 13,
              child: pw.Opacity(
                opacity: 0.1,
                child: pw.Image(
                  pw.MemoryImage(backgroundImage), 
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          ),
          // Content overlay
          pw.Positioned.fill(
            child: pw.Padding(
              padding: pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Header section
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(pw.MemoryImage(logoImage), width: 30, height: 30),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              child: pw.Text(
                                student["name"], 
                                style: pw.TextStyle(
                                  fontSize: 12, 
                                  font: ttf, 
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ), 
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              child: pw.Text(
                                "كنيسة العذراء مريم بالصاغة", 
                                style: pw.TextStyle(
                                  fontSize: 8, 
                                  font: ttf,
                                  color: PdfColors.grey700,
                                ), 
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // QR Code section
                  pw.Container(
                    padding: pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Image(pw.MemoryImage(qrCode), width: 100, height: 100),
                  ),
                  
                  // Footer section
                  pw.Container(
                    child: pw.Text(
                      "بطاقة حضور رقمية", 
                      style: pw.TextStyle(
                        fontSize: 8, 
                        font: ttf,
                        color: PdfColors.black,
                      ), 
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ignore: unused_element
  Future<void> _downloadPDFForAnalysis(List<Map<String, dynamic>> studentData) async {
    setState(() {
      isPdfLoading = true;
    });

    try {
      await Permission.storage.request();
      await getAllData(2); // Ensure this fetches data correctly

      if (await Permission.storage.isGranted) {
        final pdf = pw.Document();
        final Uint8List fontData = await loadFont();
        final ttf = pw.Font.ttf(fontData.buffer.asByteData());

        for (var student in studentData) {
          final logoImage = await loadAdditionalImage();
          final backgroundImage = await loadAdditionalImage();
          
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Container(
                    width: 300,
                    height: 420,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(15),
                      border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    ),
                    child: pw.Stack(
                      children: [
                        // Background image with low opacity
                        pw.Positioned.fill(
                          child: pw.ClipRRect(
                            horizontalRadius: 13,
                            verticalRadius: 13,
                            child: pw.Opacity(
                              opacity: 0.08,
                              child: pw.Image(
                                pw.MemoryImage(backgroundImage), 
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Content overlay
                        pw.Positioned.fill(
                          child: pw.Padding(
                            padding: pw.EdgeInsets.all(20),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                // Header section
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Image(pw.MemoryImage(logoImage), width: 50, height: 50),
                                    pw.SizedBox(width: 10),
                                    pw.Expanded(
                                      child: pw.Column(
                                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                                        children: [
                                          pw.Container(
                                            child: pw.Text(
                                              student["name"], 
                                              style: pw.TextStyle(
                                                fontSize: 20, 
                                                font: ttf, 
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.black,
                                              ), 
                                              textDirection: pw.TextDirection.rtl,
                                            ),
                                          ),
                                          pw.SizedBox(height: 5),
                                          pw.Container(
                                            child: pw.Text(
                                              "تقرير الحضور", 
                                              style: pw.TextStyle(
                                                fontSize: 14, 
                                                font: ttf,
                                                color: PdfColors.grey700,
                                              ), 
                                              textDirection: pw.TextDirection.rtl,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                pw.SizedBox(height: 20),
                                
                                // Statistics section with background
                                pw.Container(
                                  width: double.infinity,
                                  padding: pw.EdgeInsets.all(15),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    borderRadius: pw.BorderRadius.circular(10),
                                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                                    children: [
                                      pw.Text("الحضور الكلي : ${student['totalCounter']}", style: pw.TextStyle(fontSize: 14, font: ttf, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 8),
                                      pw.Text("الألحان : ${student['alhanCounter']}", style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("القداس : ${student['qudasCounter']}", style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("التسبحة : ${student['tasbhaCounter']}", style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("مدارس أحد : ${student['madrasAhadCounter'] ?? 0}", style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("اجتماع : ${student['ejtimaCounter'] ?? 0}", style: pw.TextStyle(fontSize: 12, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 10),
                                      pw.Container(height: 1, color: PdfColors.grey400),
                                      pw.SizedBox(height: 10),
                                      pw.Text("عملات الألحان: ${student['alhanCounter']} × 5 = ${student['alhanCounter']*5}", style: pw.TextStyle(fontSize: 11, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("عملات القداس: ${student['qudasCounter']} × 10 = ${student['qudasCounter']*10}", style: pw.TextStyle(fontSize: 11, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("عملات التسبحة: ${student['tasbhaCounter']} × 8 = ${student['tasbhaCounter']*8}", style: pw.TextStyle(fontSize: 11, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("عملات مدارس أحد: ${student['madrasAhadCounter'] ?? 0} × 3 = ${(student['madrasAhadCounter'] ?? 0)*3}", style: pw.TextStyle(fontSize: 11, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 5),
                                      pw.Text("عملات الاجتماع: ${student['ejtimaCounter'] ?? 0} × 2 = ${(student['ejtimaCounter'] ?? 0)*2}", style: pw.TextStyle(fontSize: 11, font: ttf), textDirection: pw.TextDirection.rtl),
                                      pw.SizedBox(height: 10),
                                      pw.Container(height: 2, color: PdfColors.grey600),
                                      pw.SizedBox(height: 10),
                                      pw.Text("إجمالي العملات: ${student['alhanCounter']*5 + student['qudasCounter']*10 + student['tasbhaCounter']*8 + (student['madrasAhadCounter'] ?? 0)*3 + (student['ejtimaCounter'] ?? 0)*2}", style: pw.TextStyle(fontSize: 14, font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.green800), textDirection: pw.TextDirection.rtl),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }


        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('إذن الوصول للملفات مغلق')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في تحميل PDF'),
        ),
      );
    } finally {
      setState(() {
        isPdfLoading = false;
      });
    }
  }


  Future<void> _downloadPDFForPasswords() async {
    setState(() {
      isPasswordPdfLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              color: Colors.white,
              child: Icon(Icons.info, color: Colors.blueGrey, size: 20),
            ),
            SizedBox(width: 5),
            Expanded(
              child: Text(
                'يتم تجهيز ملف كلمات المرور...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await Permission.storage.request();

      // Fetch current class students data specifically for passwords
      List<Map<String, dynamic>> classStudents = [];
      int offset = 0;
      const int limit = 500;

      final databases = GetIt.I<appwrite.Databases>();

      // Get all students from current class
      while (true) {
        final documents = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.studentsCollectionId,
          queries: [
            appwrite.Query.equal('classId', Constants.classId),
            appwrite.Query.orderAsc("\$createdAt"), // Order by name alphabetically
            appwrite.Query.limit(limit),
            appwrite.Query.offset(offset),
          ],
        );
                                                                    
        if (documents.documents.isEmpty) {
          break; // Exit loop if no more documents
        }

        classStudents.addAll(documents.documents.map((doc) => doc.data).toList());
        
        // Debug: Print first few students to check password field
        if (classStudents.isNotEmpty) {
          print('Sample student data:');
          for (int i = 0; i < math.min(3, classStudents.length); i++) {
            final student = classStudents[i];
            print('Student ${i + 1}: ${student["name"]} - Password: ${student["password"]}');
          }
        }
        
        offset += limit;
      }

      if (classStudents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text('لا توجد طلاب في هذا الصف لإنشاء ملف كلمات المرور'),
          ),
        );
        return;
      }

      if (await Permission.storage.isGranted) {
        final pdf = pw.Document();
        
        final Uint8List fontData = await loadFont();
        final ttf = pw.Font.ttf(fontData.buffer.asByteData());
        final logoImage = await loadAdditionalImage();

        // Create one page per student for clear individual presentation
        for (int i = 0; i < classStudents.length; i++) {
          final student = classStudents[i];
          
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Container(
                  padding: pw.EdgeInsets.all(30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      // Page header
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Image(pw.MemoryImage(logoImage), width: 60),
                          pw.SizedBox(width: 20),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                "كنيسة العذراء مريم بالصاغة",
                                style: pw.TextStyle(fontSize: 18, font: ttf, fontWeight: pw.FontWeight.bold),
                                textDirection: pw.TextDirection.rtl,
                              ),
                            
                            ],
                          ),
                        ],
                      ),
                      
                      pw.Spacer(),
                      
                      // Student card - centered and prominent
                      pw.Container(
                        width: 400,
                        padding: pw.EdgeInsets.all(30),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.indigo, width: 3),
                          borderRadius: pw.BorderRadius.circular(15),
                          color: PdfColors.grey100,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // Student number circle
                            pw.Container(
                              width: 60,
                              height: 60,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.indigo,
                                borderRadius: pw.BorderRadius.circular(30),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  "${i + 1}",
                                  style: pw.TextStyle(
                                    fontSize: 24, 
                                    font: ttf, 
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                            ),
                            
                            pw.SizedBox(height: 25),
                            
                            // Student name
                            pw.Text(
                              "الاسم: ${student["name"] ?? 'غير محدد'}",
                              style: pw.TextStyle(
                                fontSize: 20, 
                                font: ttf, 
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            
                            pw.SizedBox(height: 20),
                            
                            // Divider line
                            pw.Container(
                              width: 200,
                              height: 2,
                              color: PdfColors.indigo300,
                            ),
                            
                            pw.SizedBox(height: 20),
                            
                            // Student password
                            pw.Text(
                              "Password: ${student["password"] ?? 'غير محدد'}",
                              style: pw.TextStyle(
                                fontSize: 18, 
                                font: ttf,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red700,
                              ),
                              textDirection: pw.TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                      
                      pw.Spacer(),
                      
                      // Page footer
                      pw.Text(
                        "صفحة ${i + 1} من ${classStudents.length}",
                        style: pw.TextStyle(fontSize: 12, font: ttf, color: PdfColors.grey600),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'تم إنشاء ملف كلمات المرور بنجاح (${classStudents.length} طالب)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('إذن الوصول للملفات مغلق')),
        );
      }
    } catch (e) {
      print('Error in _downloadPDFForPasswords: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('خطأ في تحميل PDF للباسوردات: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        isPasswordPdfLoading = false;
      });
    }
  }

  Future<Uint8List> loadFont() async {
    return await root_bundle.rootBundle
        .load("assets/NotoSansArabic_Condensed-Bold.ttf")
        .then((byteData) => byteData.buffer.asUint8List());
  }

  Future<Uint8List> _generateQRCodeImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
    );
    final ByteData? pngBytes = await qrPainter.toImageData(300);
    return pngBytes!.buffer.asUint8List();
  }


Future<void> createExcel(BuildContext context) async {
  setState(() {
    isExcelLoading = true;
  });

  try {
    await _requestPermission();
    await getAllData(1);

    if (studentData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("لا توجد بيانات لإنشاء ملف Excel", style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    CellStyle cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    CellStyle headerCellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      bold: true,
      backgroundColorHex: ExcelColor.lightBlue,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
    );

    CellStyle nameStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    var headerRow = [
      'رقم',
      'الاسم',
      'العنوان',
      'المنطقة',
      'رقم الهاتف 1',
      'رقم الهاتف 2',
     "أب الاعتراف",
      'ملاحظات',
      'تاريخ الميلاد',
        
      'الحضور الكلي',
 
    ];
    
    for (int i = 0; i < headerRow.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headerRow[i]);
      cell.cellStyle = headerCellStyle;
    }

    sheetObject.setRowHeight(0, 30);
    // Set appropriate column widths
    sheetObject.setColumnWidth(0, 8);   // رقم
    sheetObject.setColumnWidth(1, 30);  // الاسم
    sheetObject.setColumnWidth(2, 35);  // رقم الهاتف
    sheetObject.setColumnWidth(3, 10);  // تاريخ الميلاد
    sheetObject.setColumnWidth(4, 15);  // العنوان
    sheetObject.setColumnWidth(5, 15);  // اسم الأب
    sheetObject.setColumnWidth(6, 30);  // هاتف الأب
    sheetObject.setColumnWidth(7, 50);  // اسم الأم
    sheetObject.setColumnWidth(8, 50);  // هاتف الأم


    int counter = 1;
    for (int rowIndex = 0; rowIndex < studentData.length; rowIndex++) {
      var dataRow = studentData[rowIndex];
      int totalCounter = dataRow['totalCounter'] is String
          ? int.tryParse(dataRow['totalCounter']) ?? 0
          : dataRow['totalCounter'] as int;
      
   
      var row = [
        counter++,
        dataRow['name'] ?? '',
        dataRow['address'] ?? '',
        dataRow['region'] ?? '',
        dataRow['phone1'] ?? '',
        dataRow['phone2'] ?? '',
        dataRow['abEle3traf'] ?? '',
        dataRow['notes'] ?? '',
        "${dataRow['birthDay'] ?? ''}/${dataRow['birthMonth'] ?? ''}/${dataRow['birthYear'] ?? ''}" ?? '',
        totalCounter,
     
      ];

      for (int i = 0; i < row.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex + 1));
        cell.value = TextCellValue("${row[i]}");
        // Use nameStyle for name and address fields, cellStyle for others
        cell.cellStyle = (i == 1 || i == 4) ? nameStyle : cellStyle;
      }
    }

    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          String downloadsPath = directory.path.replaceAll('/Android/data/com.example.attendance/files', '/Download');
          directory = Directory(downloadsPath);
        }
      }
    } else {
      directory = await getDownloadsDirectory();
    }

    if (directory != null && !(await directory.exists())) {
      await directory.create(recursive: true);
    }

    if (directory == null || !(await directory.exists())) {
      directory = await getExternalStorageDirectory();
    }

    if (directory == null) {
      throw Exception("Cannot access storage directory");
    }

    String timestamp = DateTime.now().toString().replaceAll(RegExp(r'[-:.]'), '_');
    String fileName = "داتا مخدومين العذراء الصاغة ${Constants.className} $timestamp.xlsx";
    String filePath = "${directory.path}/$fileName";

    File file = File(filePath);
    List<int> excelBytes = excel.encode()!;
    await file.writeAsBytes(excelBytes);

    // ✅ Trigger MediaScanner to show file in Recents
    const platform = MethodChannel('com.example.channel');
    await platform.invokeMethod('scanFile', {
      'path': filePath,
      'mimeType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      duration: Duration(seconds: 5),
      content: Row(
        children: [
          Container(
              color: Colors.white,
              child: Icon(Icons.check_box, color: Colors.green, size: 20)),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              'تم حفظ الملف بنجاح',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    ));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('خطأ في تحميل Excel'),
      ),
    );
  } finally {
    setState(() {
      isExcelLoading = false;
    });
  }
}


Future<void> createAttendanceExcel(BuildContext context, {int? selectedMonth, int? selectedYear}) async {
  setState(() {
    isExcelForMonthLoading = true;
  });

  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    await _requestPermission();
    await getAllData(1);

    if (studentData.isEmpty) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("لا توجد بيانات طلاب لإنشاء ملف الحضور", style: TextStyle(color: Colors.white)),
        ));
      }
      return;
    }

    final databases = GetIt.I<appwrite.Databases>();
    DateTime now = DateTime.now();
    int targetMonth = selectedMonth ?? now.month;
    int targetYear = selectedYear ?? now.year;

    DateTime startOfMonth = DateTime(targetYear, targetMonth, 1);
    DateTime endOfMonth = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);

    final meetingsResponse = await databases.listDocuments(
      databaseId: AppwriteServices.databaseId,
      collectionId: AppwriteServices.meetingsCollectionId,
      queries: [
        appwrite.Query.equal('classId', Constants.classId),
        appwrite.Query.greaterThanEqual('\$createdAt', startOfMonth.toIso8601String()),
        appwrite.Query.lessThanEqual('\$createdAt', endOfMonth.toIso8601String()),
        appwrite.Query.orderAsc('\$createdAt'),
        appwrite.Query.limit(100),
      ],
    );

    List<Map<String, dynamic>> meetings = meetingsResponse.documents.map((doc) => doc.data).toList();

    if (meetings.isEmpty) {
      String monthName = _getArabicMonthName(targetMonth);
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: Colors.orange,
          content: Text("لا توجد اجتماعات في شهر $monthName $targetYear", style: TextStyle(color: Colors.white)),
        ));
      }
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    CellStyle headerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bold: true,
      backgroundColorHex: ExcelColor.blue,
      textWrapping: TextWrapping.WrapText,
      fontSize: 12,
      fontColorHex: ExcelColor.white,
    );

    CellStyle cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    CellStyle nameStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue("اسم الطالب")
      ..cellStyle = headerStyle;

    for (int i = 0; i < meetings.length; i++) {
      DateTime meetingDate = DateTime.parse(meetings[i]['\$createdAt']);
      String formattedDate = '${meetingDate.day}/${meetingDate.month}';
      String meetingType = meetings[i]['Type'] ?? 'اجتماع';

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: 0))
        ..value = TextCellValue('$meetingType$formattedDate')
        ..cellStyle = headerStyle;
    }

    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: meetings.length + 1, rowIndex: 0))
      ..value = TextCellValue("إجمالي الحضور")
      ..cellStyle = headerStyle;

    sheetObject.setRowHeight(0, 40);
    sheetObject.setColumnWidth(0, 30);
    for (int i = 1; i <= meetings.length; i++) {
      sheetObject.setColumnWidth(i, 18);
    }
    sheetObject.setColumnWidth(meetings.length + 1, 20);

    for (int rowIndex = 0; rowIndex < studentData.length; rowIndex++) {
      var student = studentData[rowIndex];
      String studentId = student['\$id'];

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex + 1))
        ..value = TextCellValue(student['name'] ?? '')
        ..cellStyle = nameStyle;

      int totalAttendance = 0;

      for (int meetingIndex = 0; meetingIndex < meetings.length; meetingIndex++) {
        var meeting = meetings[meetingIndex];
        List<dynamic> attendees = meeting['students'] ?? [];

        bool attended = attendees.any((attendee) {
          if (attendee is String) return attendee == studentId;
          if (attendee is Map && attendee.containsKey('\$id')) return attendee['\$id'] == studentId;
          return false;
        });

        if (attended) totalAttendance++;

        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: meetingIndex + 1, rowIndex: rowIndex + 1))
          ..value = TextCellValue(attended ? '+' : '')
          ..cellStyle = cellStyle;
      }

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: meetings.length + 1, rowIndex: rowIndex + 1))
        ..value = TextCellValue(totalAttendance.toString())
        ..cellStyle = cellStyle;
    }

    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          String downloadsPath = directory.path.replaceAll('/Android/data/com.example.attendance/files', '/Download');
          directory = Directory(downloadsPath);
        }
      }
    } else {
      directory = await getDownloadsDirectory();
    }

    if (directory != null && !(await directory.exists())) {
      await directory.create(recursive: true);
    }

    if (directory == null || !(await directory.exists())) {
      directory = await getExternalStorageDirectory();
    }

    if (directory == null) throw Exception("Cannot access storage directory");

    String monthName = _getArabicMonthName(targetMonth);
    String timestamp = DateTime.now().toString().replaceAll(RegExp(r'[-:.]'), '_');
    String fileName = "حضور_${Constants.className}_${monthName}_${targetYear}_$timestamp.xlsx";
    File file = File("${directory.path}/$fileName");
    List<int> excelBytes = excel.encode()!;
    await file.writeAsBytes(excelBytes);

    // ✅ Trigger MediaScanner to show file in Recents
    const platform = MethodChannel('com.example.channel');
    await platform.invokeMethod('scanFile', {
      'path': file.path,
      'mimeType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    if (mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        duration: Duration(seconds: 7),
        content: Row(
          children: [
            Container(
                color: Colors.white,
                child: Icon(Icons.check_box, color: Colors.green, size: 20)),
            SizedBox(width: 5),
            Expanded(
              child: Text(
                'تم إنشاء ملف الحضور بنجاح لشهر $monthName ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
  
      ));
    }
  } catch (e) {
    print('Error creating attendance Excel: $e');
    if (mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('خطأ في إنشاء ملف الحضور: ${e.toString()}'),
      ));
    }
  } finally {
    if (mounted) {
      setState(() {
        isExcelForMonthLoading = false;
      });
    }
  }
}
  String _getArabicMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  Future<void> _showMonthSelectionDialog(BuildContext context) async {
    DateTime now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'اختر الشهر والسنة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year Selection
                    Text(
                      'السنة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedYear,

                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      items: List.generate(5, (index) {
                        int year = now.year - 2 + index; // 2 years back to 2 years forward
                        return DropdownMenuItem(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    
                    // Month Selection
                    Text(
                      'الشهر',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      items: List.generate(12, (index) {
                        int month = index + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                            _getArabicMonthName(month),
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Call the attendance Excel function with selected month and year
                    createAttendanceExcel(context, selectedMonth: selectedMonth, selectedYear: selectedYear);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'إنشاء التقرير',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final String _paymentUrl = "https://ipn.eg/S/keromored/instapay/3urxKb";

  void _launchURL() async {
    try {
      bool launched = await launchUrl(Uri.parse(_paymentUrl));
      if (!launched) {
        throw 'Could not launch $_paymentUrl';
      }
    } catch (e) {
    }
  }

  Future<void> resetData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final databases = GetIt.I<appwrite.Databases>();

      final meetings = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.meetingsCollectionId,
        queries: [
          appwrite.Query.limit(500),
          appwrite.Query.equal('classId', Constants.classId),
          
        ],
      );

      for (var meeting in meetings.documents) {
        await databases.deleteDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.meetingsCollectionId,
          documentId: meeting.$id,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم مسح جميع الاجتماعات لكل مخدوم', style: TextStyle(fontWeight: FontWeight.bold)),
      ));
    } on appwrite.AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('لم يتم المسح : ${e.message}'),
      ));
    }
    setState(() {
      isLoading = false;
    });
  }
  Future<void> resetDataForCounter() async {
    setState(() {
      isLoading = true;
    });
    try {
      final databases = GetIt.I<appwrite.Databases>();



      final users = await databases.listDocuments(

        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          appwrite.Query.limit(500),
          appwrite.Query.equal('classId', Constants.classId),
        ],
      );

      for (var user in users.documents) {
        await databases.updateDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.studentsCollectionId,
          documentId: user.$id,

          data: {
            'totalCounter': 0,
            'bonus': 0,
            'totalCoins': 0,
            'meetings': [],
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم مسح جميع مرات الحضور لكل مخدوم', style: TextStyle(fontWeight: FontWeight.bold)),
      ));
    } on appwrite.AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('لم يتم المسح : ${e.message}'),
      ));
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isPdfLoading ? null : () {
                      _downloadPDF(studentData);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.all(10),
                      color: isPdfLoading ? Colors.red[300] : Colors.red[700],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isPdfLoading 
                            ? SizedBox(
                                width: Constants.deviceWidth / 8,
                                height: Constants.deviceWidth / 8,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Image.asset(Constants.pdfImage, width: Constants.deviceWidth / 6, height: Constants.deviceWidth / 6),
                          SizedBox(height: 8),
                          Text(
                            isPdfLoading ? 'جارِ التحميل...' : 'تحميل داتا QR     pdf', 
                            style: TextStyle(color: Colors.white, fontSize: Constants.deviceWidth / 28),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: isExcelLoading ? null : () {
                      createExcel(context);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.all(10),
                      color: isExcelLoading ? Colors.green[300] : Colors.green,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isExcelLoading 
                            ? SizedBox(
                                width: Constants.deviceWidth / 8,
                                height: Constants.deviceWidth / 8,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Image.asset(Constants.excelImage, width: Constants.deviceWidth / 6, height: Constants.deviceWidth / 6),
                          SizedBox(height: 8),
                          Text(
                            isExcelLoading ? 'جارِ التحميل...' : 'الحضور الكلي excel', 
                            style: TextStyle(color: Colors.white, fontSize: Constants.deviceWidth / 28),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: isExcelForMonthLoading ? null : () {
                      _showMonthSelectionDialog(context);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.all(10),
                      color: isExcelForMonthLoading ? Colors.orange[300] : Colors.orange,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isExcelForMonthLoading 
                            ? SizedBox(
                                width: Constants.deviceWidth / 8,
                                height: Constants.deviceWidth / 8,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.calendar_month, size: Constants.deviceWidth / 6, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            isExcelForMonthLoading ? 'جارِ التحميل...' : ' شهر محدد   excel', 
                            style: TextStyle(color: Colors.white, fontSize: Constants.deviceWidth / 28),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            buildButton(context, "مسح الاجتماعات", () {
              AwesomeDialog(
                dialogBackgroundColor: Colors.white,
                context: context,
                dialogType: DialogType.noHeader,
                animType: AnimType.rightSlide,
                title: 'أتريد حذف جميع الاجتماعات؟',
                btnCancelText: "حذف",
                btnCancelOnPress: () async {
                  await resetData();
                },
              ).show();
            }, Icons.delete),
            SizedBox(height: 20),
            buildButton(context, "مسح عدد مرات الحضور", () {
              AwesomeDialog(
                dialogBackgroundColor: Colors.white,
                context: context,
                dialogType: DialogType.noHeader,
                animType: AnimType.rightSlide,
                title: 'أتريد حذف عدد مرات الحضور لكل مخدوم؟',
                btnCancelText: "حذف",
                btnCancelOnPress: () async {
                  await resetDataForCounter();
                },
              ).show();
            }, Icons.delete),
            SizedBox(height: 20),
            buildButton(context, "الدفع عن طريق انستاباى ", _launchURL, Icons.payment),
            SizedBox(height: 20),           
            (Constants.classId=="681f72c87215111b670e")?
            buildButton(context, "تحميل pdf بالباسوردات", (){
              _downloadPDFForPasswords();
            }, Icons.password_outlined, isLoading: isPasswordPdfLoading):Container(),
            //   buildButton(context, "تحميل pdf مفصل", (){
            //   _downloadPDFForAnalysis(studentData);
            // }, Icons.password_outlined, isLoading: isPasswordPdfLoading),
  //buildButton(context, "تحميل pdf بالباسوردات", ()async{
//await updateStudentMeetingCounters();            }, Icons.password_outlined, isLoading: isPasswordPdfLoading),
            //(Constants.classId=="681f72c87215111b670e")?
            // buildButton(context, "تحميل pdf بالعملات", () async {
            //   // Ensure we have fresh student data with meetings
           
            //     await getAllData(1);
            //     _downloadPDFForGetCoins(studentData);
              
              
            // }, Icons.monetization_on, isLoading: isPdfLoading):Container(),

         ],
        ),
      ),
    );
  }
  Widget buildButton(BuildContext context, String label, VoidCallback? onPressed, IconData icon, {bool isLoading = false}) {
    return SizedBox(
      width: Constants.deviceWidth / 1.1,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? Colors.indigo[300] : Colors.indigo,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        onPressed: isLoading ? null : onPressed,
        child: ListTile(
          trailing: isLoading 
            ? SizedBox(
                width: Constants.deviceWidth / 20,
                height: Constants.deviceWidth / 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: Colors.white, size: Constants.deviceWidth / 20),
          title: Center(
            child: Text(
              isLoading ? 'جارِ التحميل...' : label,
              style: TextStyle(
                fontSize: Constants.deviceHeight / 40,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}