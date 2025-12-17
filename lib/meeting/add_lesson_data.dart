
// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helper/appwrite_services.dart';
import '../helper/constants.dart';

class AddLessonData extends StatefulWidget {
  final String meetingId;
  const AddLessonData({super.key, required this.meetingId});

  @override
  State<AddLessonData> createState() => _AddLessonDataState();
}

class _AddLessonDataState extends State<AddLessonData> {
  final TextEditingController _textController = TextEditingController();
  bool _isUploading = false;
  String _uploadStatus = '';
  List<Map<String, dynamic>> _lessonFiles = [];

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  String _getFileType(String extension) {
    final ext = extension.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    return 'file';
  }

  Future<void> _loadLessonData() async {
    try {
      final databases = GetIt.I<Databases>();
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.lessonsCollectionId,
        queries: [
          Query.equal('meetingId', widget.meetingId),
          Query.orderDesc('createdAt'),
        ],
      );

      setState(() {
        _lessonFiles = documents.documents.map((d) => Map<String, dynamic>.from(d.data)).toList();
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null) return;

      setState(() {
        _isUploading = true;
        _uploadStatus = 'اختيار الملفات...';
      });

      final storage = GetIt.I<Storage>();
      final databases = GetIt.I<Databases>();

      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        final filePath = file.path;
        if (filePath == null) continue;

        setState(() {
          _uploadStatus = 'رفع الملف ${i + 1} من ${result.files.length}: ${file.name}';
        });

        final inputFile = InputFile(path: filePath, filename: file.name);
        final upload = await storage.createFile(
          bucketId: AppwriteServices.bucketId,
          fileId: ID.unique(),
          file: inputFile,
        );

        setState(() {
          _uploadStatus = 'حفظ بيانات الملف ${i + 1} من ${result.files.length}...';
        });

        final Map<String, dynamic> data = {
          'meetingId': widget.meetingId,
          'fileId': upload.$id,
          'fileName': file.name,
          'fileType': file.extension ?? '',
          'type': _getFileType(file.extension ?? ''), // Add required type attribute
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'text': null,
          'classId': Constants.classId,
        };

        await databases.createDocument(
          databaseId: AppwriteServices.databaseId,
          collectionId: AppwriteServices.lessonsCollectionId,
          documentId: ID.unique(),
          data: data,
        );
      }

      setState(() {
        _uploadStatus = 'اكتملت عملية الرفع بنجاح!';
      });

      await _loadLessonData();
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الملفات بنجاح')),
        );
        Navigator.pop(context, true); // Return success to refresh parent
      }
    } catch (e) {
      print('File upload error: $e'); // Debug print
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الملفات: $e')),
        );
      }
    }
  }

  Future<void> _uploadText() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة النص أولاً')),
      );
      return;
    }
    
    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'حفظ النص...';
      });
      
      final databases = GetIt.I<Databases>();

      setState(() {
        _uploadStatus = 'إنشاء البيانات...';
      });

      final Map<String, dynamic> data = {
        'meetingId': widget.meetingId,
        'fileId': null,
        'fileName': null,
        'fileType': 'text',
        'type': 'text', // Add required type attribute
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'text': _textController.text.trim(),
        'classId': Constants.classId,
      };

      await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.lessonsCollectionId,
        documentId: ID.unique(),
        data: data,
      );

      setState(() {
        _uploadStatus = 'تم حفظ النص بنجاح!';
      });

      _textController.clear();
      await _loadLessonData();
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ النص بنجاح')),
        );
        Navigator.pop(context, true); // Return success to refresh parent
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ النص: $e')),
        );
      }
    }
  }

  Future<void> _deleteLessonItem(Map<String, dynamic> item) async {
    try {
      final databases = GetIt.I<Databases>();
      // delete metadata
      await databases.deleteDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.lessonsCollectionId,
        documentId: item['\$id'],
      );
      // delete file if any
      final fileId = item['fileId'];
      if (fileId != null && (fileId as String).isNotEmpty) {
        final storage = GetIt.I<Storage>();
        await storage.deleteFile(bucketId: AppwriteServices.bucketId, fileId: fileId);
      }
      await _loadLessonData();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اضافة بيانات الدرس'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFiles,
                    icon: _isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_isUploading ? 'جاري الرفع...' : 'رفع صور / PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUploading ? Colors.grey : Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadText,
                    icon: _isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.text_fields),
                    label: Text(_isUploading ? 'جاري الحفظ...' : 'حفظ نص'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUploading ? Colors.grey : Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Upload progress indicator
            if (_isUploading) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _uploadStatus.isNotEmpty ? _uploadStatus : 'جاري معالجة البيانات...',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      backgroundColor: Colors.blue[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الرجاء الانتظار حتى اكتمال العملية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'اكتب نص الدرس هنا...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _lessonFiles.isEmpty
                  ? const Center(child: Text('لا يوجد بيانات للدرس بعد'))
                  : ListView.builder(
                      itemCount: _lessonFiles.length,
                      itemBuilder: (context, index) {
                        final item = _lessonFiles[index];
                        final isText = (item['fileType'] == 'text');
                        return Card(
                          child: ListTile(
                            title: Text(item['fileName']?.toString() ?? (isText ? 'نص محفوظ' : 'ملف بدون اسم')),
                            subtitle: isText ? Text(item['text'] ?? '') : Text(item['fileType']?.toString() ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _isUploading ? null : () => _deleteLessonItem(item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
