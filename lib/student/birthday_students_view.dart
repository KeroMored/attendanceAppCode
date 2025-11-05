import 'dart:io';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helper/appwrite_services.dart';
import '../helper/connectivity_service.dart';
import '../helper/constants.dart';
import '../student/student_detailsage.dart';

class BirthdayStudentsView extends StatefulWidget {
  const BirthdayStudentsView({super.key});

  @override
  State<BirthdayStudentsView> createState() => _BirthdayStudentsViewState();
}

class _BirthdayStudentsViewState extends State<BirthdayStudentsView> {
  List<Map<String, dynamic>> studentData = [];
  bool isLoading = false;
  bool isExporting = false;
  bool hasMoreData = true;
  final int pageSize = 10;
  late ConnectivityService _connectivityService;
  int? _selectedMonth;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _selectedMonth = DateTime.now().month;
    _scrollController.addListener(_onScroll);
    _connectivityService.checkConnectivity(context, _loadStudents());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMoreData) {
        _loadStudents();
      }
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return monthNames[month - 1];
  }

  Future<void> _loadStudents() async {
    if (isLoading || !hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    try {
      final databases = GetIt.I<appwrite.Databases>();
      
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.studentsCollectionId,
        queries: [
          appwrite.Query.equal('classId', Constants.classId),
          appwrite.Query.equal('birthMonth', _selectedMonth),
          appwrite.Query.notEqual('birthMonth', 0),
          appwrite.Query.isNotNull('birthMonth'),
          appwrite.Query.orderAsc('birthDay'),
          appwrite.Query.limit(pageSize),
          if (studentData.isNotEmpty)
            appwrite.Query.cursorAfter(studentData.last['\$id']),
        ],
      );

      if (documents.documents.isEmpty) {
        setState(() {
          hasMoreData = false;
          isLoading = false;
        });
      } else {
        setState(() {
          studentData.addAll(documents.documents.map((doc) => doc.data).toList());
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMonthChanged(int? month) {
    if (month != _selectedMonth) {
      setState(() {
        _selectedMonth = month;
        studentData.clear();
        hasMoreData = true;
      });
      _loadStudents();
    }
  }

  Future<void> createBirthdayExcel(BuildContext context) async {
    if (_selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اختر شهراً أولاً'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() {
      isExporting = true;
    });

    try {
      // Request permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final res = await Permission.storage.request();
          if (!res.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('رجاء السماح بالوصول إلى التخزين لحفظ الملف'),
              backgroundColor: Colors.red,
            ));
            return;
          }
        }
      }

      // Fetch all students for selected month (paginated)
      final databases = GetIt.I<appwrite.Databases>();
      List<Map<String, dynamic>> students = [];
      int offset = 0;
      const int limit = 500;

      while (true) {
        final documents = await databases.listDocuments(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.studentsCollectionId,
          queries: [
            appwrite.Query.equal('classId', Constants.classId),
            appwrite.Query.equal('birthMonth', _selectedMonth),
            appwrite.Query.orderAsc('birthDay'),
            appwrite.Query.limit(limit),
            appwrite.Query.offset(offset),
          ],
        );

        if (documents.documents.isEmpty) break;

        students.addAll(documents.documents.map((d) => d.data).toList());
        offset += limit;
      }

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('لا توجد طلاب لديهم أعياد ميلاد في ${_getMonthName(_selectedMonth!)}'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Create Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      var header = ['رقم', 'الاسم', 'تاريخ الميلاد'];

      // Cell styles: center align header and data cells
      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle centerStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      for (int i = 0; i < header.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(header[i]);
        cell.cellStyle = headerStyle;
      }

      sheet.setRowHeight(0, 26);
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 18);

      int counter = 1;
      for (int r = 0; r < students.length; r++) {
        final s = students[r];
        final day = s['birthDay'] ?? '';
        final month = s['birthMonth'] ?? '';
        final year = s['birthYear'] ?? '';
        String birth = '';
        if (day != '' && month != '') {
          birth = '$day/$month' + (year != '' ? '/$year' : '');
        }

        final row = [counter++, s['name'] ?? '', birth];
        for (int c = 0; c < row.length; c++) {
          final dataCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
          dataCell.value = TextCellValue('${row[c]}');
          dataCell.cellStyle = centerStyle;
        }
      }

      // Save file to Downloads
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            final path = ext.path.replaceAll(RegExp(r'/Android/data/.*'), '/Download');
            directory = Directory(path);
          }
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) throw Exception('Cannot access Downloads folder');
      if (!(await directory.exists())) await directory.create(recursive: true);

      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-\.]'), '_');
      final fileName = 'birthdays_${Constants.className}_${_selectedMonth}_${timestamp}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      final bytes = excel.encode()!;
      await file.writeAsBytes(bytes);

      // Trigger media scan (native implementation required)
   
    // ✅ Trigger MediaScanner to show file in Recents
    const platform = MethodChannel('com.example.channel');
    await platform.invokeMethod('scanFile', {
      'path': filePath,
      'mimeType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم حفظ الملف: $fileName'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      print('Error exporting birthdays excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('خطأ عند إنشاء ملف الإكسل'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        centerTitle: true,
        title: const Text('أعياد الميلاد',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedMonth,
              hint: const Text('اختر الشهر'),
              items: List.generate(12, (index) => index + 1).map((month) {
                return DropdownMenuItem<int>(
                  value: month,
                  child: Text(
                    _getMonthName(month),
                    style: TextStyle(fontSize: Constants.deviceWidth / 22, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: _onMonthChanged,
            ),
          ),
          Expanded(
            child: studentData.isEmpty && !isLoading
                ? Center(
                    child: Text(
                      'لا يوجد أعياد ميلاد في هذا الشهر',
                      style: TextStyle(
                        fontSize: Constants.deviceWidth / 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: studentData.length + (hasMoreData ? 1 : 0),
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      if (index == studentData.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Colors.blue,),
                          ),
                        );
                      }

                      final student = studentData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                        
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueGrey,
                              Colors.blueGrey.shade800,
                              
                              
                              ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                       // margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailsPage(
                                  studentId: student['\$id'] ?? '',
                                ),
                              ),
                            );
                          },
                          title: Text(
                            student['name'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Constants.deviceWidth / 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            '${student['birthDay'] ?? 0}/${student['birthMonth'] ?? 0}/${student['birthYear'] ?? 0000}',
                            style: TextStyle(
                              fontSize: Constants.deviceWidth / 30,
                              color: Colors.white,
                                                            fontWeight: FontWeight.w900,

                            ),
                          ),
                          trailing: Icon(
                            Icons.cake,
                            color: Colors.white,
                            size: Constants.deviceWidth / 15,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isExporting
            ? null
            : () async {
                final month = _selectedMonth ?? DateTime.now().month;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تنزيل ملف اكسل'),
                    content: Text('هل تريد تنزيل ملف اكسل بأعياد الميلاد لشهر ${_getMonthName(month)} ؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('لا')),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('نعم')),
                    ],
                  ),
                );

                if (confirm == true) {
                  await createBirthdayExcel(context);
                }
              },
        child: isExporting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.file_download ,size: 20,color: Colors.blueGrey,),

        backgroundColor: Colors.white,
      ),
    );
  }
}