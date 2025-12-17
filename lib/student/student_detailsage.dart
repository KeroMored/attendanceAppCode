import 'package:appwrite/appwrite.dart' as appwrite;

import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';  // Removed for iOS build

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';
import 'edit_student_view.dart';
import 'students_page_view.dart';
import 'attendance_days_for_student.dart'; // Add this import

class StudentDetailsPage extends StatefulWidget {
  final String studentId;

  const StudentDetailsPage({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  Map<dynamic, dynamic>? studentData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // print(Constants.deviceHeight);
    // print(Constants.deviceWidth);
    _assignStudentData();
  }

  Future<void> _assignStudentData() async {
    final data = await getStudentData(widget.studentId);
    if (data != null) {
      setState(() {
        studentData = data;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> getStudentData(String studentId) async {
    try {
      final databases = GetIt.I<appwrite.Databases>();
      final document = await databases.getDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        documentId: studentId,
        // queries: [
        //   appwrite.Query.equal('classId', Constants.classId),
        //
        // ]
      );
      return document.data;
    } on appwrite.AppwriteException {
      return null;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final databases = GetIt.I<appwrite.Databases>();
    try {
      await databases.deleteDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.studentsCollectionId,
          documentId: studentId);
      scaffoldContext.showSnackBar(
        SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            content: Center(
                child: Text(
              'تم حذف البيانات',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ))),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => StudentsPageView(),
        ),
        (route) => false,
      );
    } on appwrite.AppwriteException {
      scaffoldContext.showSnackBar(SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
              child: Text(
            'لم يتم حذف البانات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ))));
    }
  }

  String _formatWhatsAppNumber(String input) {
    // Keep digits and '+' only initially
    String n = input.trim();
    // Remove all spaces, dashes, and parentheses
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Remove leading '+'
    if (n.startsWith('+')) n = n.substring(1);
    // Convert leading '00' international prefix to just country code
    if (n.startsWith('00')) n = n.substring(2);
    // Remove a single leading '0' for local numbers as requested
    if (n.startsWith('0')) n = n.substring(1);
    // Finally, strip any remaining non-digits to be safe
    n = n.replaceAll(RegExp(r'[^0-9]'), '');
    return n;
  }

  void openWhatsApp(String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      // Nothing to launch
      return;
    }
    final String whatsappUrl = "https://wa.me/$formatted";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  // Format birth date from separate fields
  String _formatBirthDate(Map<dynamic, dynamic> studentData) {
    try {
      int day = studentData['birthDay'] ?? 0;
      int month = studentData['birthMonth'] ?? 0;
      int year = studentData['birthYear'] ?? 0;

      if (day > 0 && month > 0 && year > 0) {
        return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year";
      } else if (studentData['birthdayDate'] != null &&
          studentData['birthdayDate'].toString().isNotEmpty) {
        // Fallback to old format if new fields are not available
        return studentData['birthdayDate'].toString();
      }
    } catch (e) {
      // If new fields are not available, fallback to old format
      if (studentData['birthdayDate'] != null) {
        return studentData['birthdayDate'].toString();
      }
    }

    return 'غير محدد';
  }

  // Open social media links
  Future<void> _openSocialMediaLink(String? link, String platform) async {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد رابط $platform')),
      );
      return;
    }

    String url = link;
    // Add https if not present
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      bool launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن فتح الرابط')),
      );
    }
  }

  Future<Uint8List> loadAdditionalImage() async {
    return await rootBundle
        .load(Constants.saintMaria) // Replace with your image path
        .then((byteData) => byteData.buffer.asUint8List());
  }

  Future<Uint8List> loadBackgroundImage() async {
    return await rootBundle
        .load(Constants.saintMaria) // Background image path
        .then((byteData) => byteData.buffer.asUint8List());
  }

  Future<Uint8List> loadFont() async {
    return await rootBundle
        .load("assets/NotoSansArabic_Condensed-Bold.ttf")
        .then((byteData) => byteData.buffer.asUint8List());
  }

  Future<void> _downloadPDF() async {
    // Request permissions
    await Permission.storage.request();
    // Check if permission is granted
    if (await Permission.storage.isGranted && studentData != null) {
      final pdf = pw.Document();

      // Load the custom font
      final Uint8List fontData = await loadFont();
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      // Generate QR code as an image
      final qrData = studentData!["\$id"];
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
      );

      // Convert QR code to PNG image
      final ByteData? pngBytes = await qrPainter.toImageData(300);
      final Uint8List pngData = pngBytes!.buffer.asUint8List();
      final logoImage = await loadAdditionalImage();
      final backgroundImage = await loadBackgroundImage();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 280,
                height: 380,
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
                        padding: pw.EdgeInsets.all(20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            // Header section
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Image(pw.MemoryImage(logoImage),
                                    width: 50, height: 50),
                                pw.SizedBox(width: 10),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    children: [
                                      pw.Container(
                                        child: pw.Text(
                                          studentData!["name"],
                                          style: pw.TextStyle(
                                            fontSize: 18,
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
                                            fontSize: 14,
                                            font: ttf,
                                            color: PdfColors.grey700,
                                          ),
                                          textDirection: pw.TextDirection.rtl,
                                        ),
                                      ),
                                      pw.SizedBox(height: 3),
                                      // pw.Container(
                                      //   child: pw.Text(
                                      //     "حصة الألحان",
                                      //     style: pw.TextStyle(
                                      //       fontSize: 12,
                                      //       font: ttf,
                                      //       color: PdfColors.grey600,
                                      //     ),
                                      //     textDirection: pw.TextDirection.rtl,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // QR Code section
                            pw.Container(
                              padding: pw.EdgeInsets.all(15),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(10),
                                border: pw.Border.all(
                                    color: PdfColors.grey300, width: 1),
                              ),
                              child: pw.Image(pw.MemoryImage(pngData),
                                  width: 180, height: 180),
                            ),

                            // Footer section
                            pw.Container(
                              child: pw.Text(
                                "بطاقة حضور رقمية",
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  font: ttf,
                                  color: PdfColors.grey600,
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
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());

      // Show a message indicating the file was saved
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('PDF saved to: $path')),
      // );
    } else {
      // Show a message if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اذن الوصول للملفات مغلق')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(
        MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    double sizedBoxHeight = MediaQuery.of(context).size.height / 200;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white, size: Constants.arrowBackSize),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SpinKitWaveSpinner(
                  color: Colors.blueGrey,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // InkWell(
                                //   onTap: () {
                                //
                                //       Navigator.push(
                                //         context,
                                //         MaterialPageRoute(
                                //           builder: (context) => EditStudentView(studentId: widget.StudentID), // Pass the student ID
                                //         ),
                                //       );
                                //
                                //   },
                                //   child: Text('تعديل',style: TextStyle(color: Colors.black54,decoration: TextDecoration.underline,fontWeight: FontWeight.w700,fontSize: 16,decorationColor: Colors.black),),
                                // ),
                                if (!Constants.isUser)
                                  IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditStudentView(
                                              studentId: studentData!['\$id'],
                                              name: studentData!['name'],
                                              birthdayDate: _formatBirthDate(
                                                  studentData!),
                                              phone1: studentData!['phone1'],
                                              phone2: studentData!['phone2'],
                                              meetings:
                                                  studentData!['meetings'],
                                              address: studentData!['address'],
                                              region: studentData!["region"],
                                              notes: studentData!['notes'],
                                              abEle3traf:
                                                  studentData!['abEle3traf'],
                                              faceBookLink:
                                                  studentData!['faceBookLink'],
                                              instgramLink:
                                                  studentData!['instgramLink'],
                                              tiktokLink:
                                                  studentData!['tiktokLink'],
                                            ), // Pass the student ID
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.edit))
                                else
                                  SizedBox(
                                    height: sizedBoxHeight,
                                  )
                              ],
                            ),

                            Text("- الاسم : ${studentData!['name']}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: Constants.deviceWidth / 18)
                                //Styles.textStyleSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Divider(
                              height: 1,
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            if (!Constants.isUser)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "- العنوان : ${studentData!['region']} - ${studentData!['address']}",
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: Constants.deviceWidth / 20),
                                  ),
                                  SizedBox(height: sizedBoxHeight / 2),
                                  Divider(
                                    height: 1,
                                  ),
                                  SizedBox(height: sizedBoxHeight / 2),
                                ],
                              ),

                            Text("- الفصل : ${Constants.className}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: Constants.deviceWidth / 20)
                                //Styles.textStyleSmall,
                                ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Divider(
                              height: 1,
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Text(
                                "- تاريخ الميلاد : ${_formatBirthDate(studentData!)}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: Constants.deviceWidth / 20)
                                //Styles.textStyleSmall,
                                ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Divider(
                              height: 1,
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Text(
                              "- أب الاعتراف : ${studentData!['abEle3traf'] ?? 'لا يوجد'}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: Constants.deviceWidth / 20),
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Divider(
                              height: 1,
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            // Display additional attributes

                            Text(
                              "- ملاحظات : ${studentData!['notes'] ?? 'لا يوجد'}",
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: Constants.deviceWidth / 20),
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Divider(
                              height: 1,
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            // Social Media Links Section
                            Text(
                              "- وسائل التواصل الاجتماعي :",
                              style: TextStyle(
                                  fontSize: Constants.deviceWidth / 24,
                            ),
                            ),
                            SizedBox(height: sizedBoxHeight / 1.5),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Facebook Link
                                if (studentData!['faceBookLink'] != null &&
                                    studentData!['faceBookLink']
                                        .toString()
                                        .isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _openSocialMediaLink(
                                        studentData!['faceBookLink'],
                                        'Facebook'),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      margin: EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Colors.blue,
                                          Colors.blueAccent,
                                        ]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Facebook',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),

                                // Instagram Link
                                if (studentData!['instgramLink'] != null &&
                                    studentData!['instgramLink']
                                        .toString()
                                        .isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _openSocialMediaLink(
                                        studentData!['instgramLink'],
                                        'Instagram'),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      margin: EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Colors.orange,
                                          Colors.purple,
                                        ]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Instagram',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),

                                // TikTok Link
                                if (studentData!['tiktokLink'] != null &&
                                    studentData!['tiktokLink']
                                        .toString()
                                        .isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _openSocialMediaLink(
                                        studentData!['tiktokLink'], 'TikTok'),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      margin: EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('TikTok',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: sizedBoxHeight / 2),
                            Divider(
                              height: 1,
                            ),
                            SizedBox(height: sizedBoxHeight / 2),

                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text("- ${studentData!['phone1']}",
                                          style: TextStyle(
                                              fontSize:
                                                  Constants.deviceWidth / 20)
                                          //Styles.textStyleSmall,
                                          ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.call, color: Colors.blue),
                                      onPressed: () {
                                        _makePhoneCall(
                                          studentData!['phone1'],
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(MdiIcons.whatsapp,
                                          color: Colors.green),
                                      onPressed: () {
                                        openWhatsApp(studentData!['phone1']);
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: sizedBoxHeight / 2),
                                Divider(
                                  height: 1,
                                ),
                                SizedBox(height: sizedBoxHeight / 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text("- ${studentData!['phone2']}",
                                          style: TextStyle(
                                              fontSize:
                                                  Constants.deviceWidth / 20)
                                          //Styles.textStyleSmall,
                                          ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.call, color: Colors.blue),
                                      onPressed: () {
                                        _makePhoneCall(studentData!['phone2']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(MdiIcons.whatsapp,
                                          color: Colors.green),
                                      onPressed: () {
                                        openWhatsApp(studentData!['phone2']);
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: sizedBoxHeight / 2),
                                Divider(
                                  height: 1,
                                ),
                                SizedBox(height: sizedBoxHeight / 2),
                              ],
                            ),

                            Center(
                              child: QrImageView(
                                data: studentData!['\$id'],
                                version: QrVersions.auto,
                                size: Constants.deviceWidth / 2,
                              ),
                            ),
                            GestureDetector(
                                onTap: () {
                                  // Debug: Print student data and meetings when "جميع أيام الحضور" is pressed
                                  print(
                                      "=== DEBUG: Student Details - جميع أيام الحضور pressed ===");
                                  print(
                                      "DEBUG: Student ID: ${studentData!['\$id']}");
                                  print(
                                      "DEBUG: Student name: ${studentData!['name']}");
                                  print(
                                      "DEBUG: Student meetings field: ${studentData!['meetings']}");
                                  print(
                                      "DEBUG: Student meetings type: ${studentData!['meetings'].runtimeType}");
                                  if (studentData!['meetings'] is List) {
                                    print(
                                        "DEBUG: Meetings list length: ${studentData!['meetings'].length}");
                                    for (int i = 0;
                                        i < studentData!['meetings'].length;
                                        i++) {
                                      print(
                                          "DEBUG: Meeting $i: ${studentData!['meetings'][i]}");
                                    }
                                  }
                                  print(
                                      "=== DEBUG: Navigating to AttendanceDaysForStudent ===");
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AttendanceDaysForStudent(
                                          studentData!['meetings'],
                                        ),
                                      ));
                                },
                                child: Center(
                                  child: Text(
                                    "جميع أيام الحضور",
                                    style: TextStyle(
                                        fontSize: Constants.deviceWidth / 18,
                                        decoration: TextDecoration.underline),
                                  ),
                                )),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (!Constants.isUser)
                                  IconButton(
                                      onPressed: () {
                                        AwesomeDialog(
                                          dialogBackgroundColor: Colors.white,
                                          context: context,
                                          dialogType: DialogType.noHeader,
                                          animType: AnimType.rightSlide,
                                          title: 'أتريد حذف هذه البيانات؟',
                                          //        desc: 'Dialog description here.............',
                                          btnCancelText: "حذف",
                                          btnCancelOnPress: () async {
                                            await deleteStudent(
                                                studentData!["\$id"]);
                                          },
                                        ).show();
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.black,
                                      ))
                                else
                                  SizedBox(
                                    height: sizedBoxHeight,
                                  )
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
      floatingActionButton: (isLoading || (Constants.isUser))
          ? null
          : FloatingActionButton(
              //    onPressed: (){},
              backgroundColor: Colors.blueGrey,

              onPressed: _downloadPDF,
              child: Icon(
                Icons.download,
                color: Colors.white,
              ),
            ),
    );
  }
}
