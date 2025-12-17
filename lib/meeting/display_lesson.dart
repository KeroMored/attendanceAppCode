// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:get_it/get_it.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../helper/appwrite_services.dart';
import '../helper/styles.dart';
import 'add_lesson_data.dart';

class DisplayLesson extends StatefulWidget {
  final String meetingId;
  const DisplayLesson({super.key, required this.meetingId});

  @override
  State<DisplayLesson> createState() => _DisplayLessonState();
}

class _DisplayLessonState extends State<DisplayLesson> {
  List<Map<String, dynamic>> _lessonItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    try {
      setState(() => _isLoading = true);
      final databases = GetIt.I<appwrite.Databases>();
      
      final documents = await databases.listDocuments(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.lessonsCollectionId,
        queries: [
          appwrite.Query.equal('meetingId', widget.meetingId),
          appwrite.Query.orderDesc('createdAt'),
        ],
      );

      setState(() {
        _lessonItems = documents.documents
            .map((d) => Map<String, dynamic>.from(d.data))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading lesson data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل بيانات الدرس: $e')),
        );
      }
    }
  }

  Future<void> _deleteLessonItem(Map<String, dynamic> item) async {
    try {
      final databases = GetIt.I<appwrite.Databases>();
      final storage = GetIt.I<appwrite.Storage>();
      
      // Delete metadata document
      await databases.deleteDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.lessonsCollectionId,
        documentId: item['\$id'],
      );
      
      // Delete file from storage if exists
      final fileId = item['fileId'];
      if (fileId != null && (fileId as String).isNotEmpty) {
        try {
          await storage.deleteFile(
            bucketId: AppwriteServices.bucketId,
            fileId: fileId,
          );
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
      
      // Reload data
      await _loadLessonData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العنصر بنجاح')),
        );
      }
    } catch (e) {
      print('Error deleting lesson item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف العنصر: $e')),
        );
      }
    }
  }

  Widget _buildGroupedContent() {
    // Group items by type for better display
    final textItems = _lessonItems.where((item) => item['type'] == 'text').toList();
    final imageItems = _lessonItems.where((item) => item['type'] == 'image').toList();
    final fileItems = _lessonItems.where((item) => item['type'] == 'pdf' || item['type'] == 'file').toList();

    return Column(
      children: [
        // Text items
        ...textItems.map((item) => _buildTextItem(item)),
        
        // Image grid
        if (imageItems.isNotEmpty) _buildImageGrid(imageItems),
        
        // File items
        ...fileItems.map((item) => _buildFileItem(item)),
      ],
    );
  }

  Widget _buildTextItem(Map<String, dynamic> item) {
    final text = (item['text'] ?? '').toString();
    final createdAt = (item['createdAt'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'نص',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(item),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_quote, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'محتوى نصي',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'تم الإضافة: ${_formatDateTime(createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<Map<String, dynamic>> imageItems) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الصور (${imageItems.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Image grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Build rows of 3 images each
                for (int i = 0; i < imageItems.length; i += 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        for (int j = i; j < i + 3 && j < imageItems.length; j++) ...[
                          Expanded(child: _buildImageThumbnail(imageItems[j], j)),
                          if (j < i + 2 && j < imageItems.length - 1) const SizedBox(width: 8),
                        ],
                        // Fill remaining space if less than 3 images in row
                        for (int k = 0; k < 3 - (imageItems.length - i).clamp(0, 3); k++)
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'اضغط على أي صورة للعرض بالحجم الكامل',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> item, int index) {
    final fileId = (item['fileId'] ?? '').toString();
    
    // Get all image items for the gallery
    final allImages = _lessonItems.where((item) => item['type'] == 'image').toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageGallery(
              images: allImages,
              initialIndex: allImages.indexOf(item),
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Hero(
            tag: 'image_$fileId',
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${AppwriteServices.endPointId}/storage/buckets/${AppwriteServices.bucketId}/files/$fileId/view?project=${AppwriteServices.projectId}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueGrey,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 24),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showDeleteDialog(item),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString();
    final fileName = (item['fileName'] ?? '').toString();
    final fileId = (item['fileId'] ?? '').toString();
    final createdAt = (item['createdAt'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (type == 'pdf' ? Colors.red : Colors.blue).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  type == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                  color: type == 'pdf' ? Colors.red : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTypeTitle(type, fileName),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(item),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (type == 'pdf') {
                      _openPdfViewer(fileId, fileName);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فتح الملف: $fileName')),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (type == 'pdf' ? Colors.red : Colors.blue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            type == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                            color: type == 'pdf' ? Colors.red : Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.touch_app, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'اضغط للعرض',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'تم الإضافة: ${_formatDateTime(createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPdfViewer(String fileId, String fileName) {
    final pdfUrl = '${AppwriteServices.endPointId}/storage/buckets/${AppwriteServices.bucketId}/files/$fileId/view?project=${AppwriteServices.projectId}';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewer(
          pdfUrl: pdfUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا العنصر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLessonItem(item);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  String _getTypeTitle(String type, String fileName) {
    switch (type) {
      case 'text':
        return 'نص';
      case 'image':
        return 'صورة: $fileName';
      case 'pdf':
        return 'ملف PDF: $fileName';
      default:
        return 'ملف: $fileName';
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: Text(
          'محتوى الدرس',
          style: Styles.textStyleSmall.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLessonData(meetingId: widget.meetingId),
            ),
          );
          // Reload data when returning from add lesson page
          if (result == true || result == null) {
            _loadLessonData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            )
          : _lessonItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد محتوى للدرس بعد',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على + لإضافة نصوص أو ملفات',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLessonData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildGroupedContent(),
                  ),
                ),
    );
  }
}

class FullScreenImageGallery extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} من ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مشاركة الصورة')),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final item = widget.images[index];
          final fileId = (item['fileId'] ?? '').toString();

          return Center(
            child: Hero(
              tag: 'image_$fileId',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  '${AppwriteServices.endPointId}/storage/buckets/${AppwriteServices.bucketId}/files/$fileId/view?project=${AppwriteServices.projectId}',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل الصورة...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white.withOpacity(0.6),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'فشل تحميل الصورة',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.zoom_in,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اسحب للتكبير والتصغير',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.swipe,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اسحب للانتقال بين الصور',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PdfViewer({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  bool _isLoading = true;
  String? _localPath;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndViewPdf();
  }

  Future<void> _downloadAndViewPdf() async {
    try {
      // Download the PDF file temporarily
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_pdf.pdf');
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('فشل تحميل الملف');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الملف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: Text(
          widget.fileName.isNotEmpty ? widget.fileName : 'ملف PDF',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مشاركة الملف')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'جاري تحميل الملف...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _localPath == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'فشل تحميل الملف',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _downloadAndViewPdf,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : PDFView(
                  filePath: _localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: 0,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation: false,
                  onRender: (pages) {
                    setState(() => _totalPages = pages!);
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في عرض الملف: $error')),
                    );
                  },
                  onPageError: (page, error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في الصفحة $page: $error')),
                    );
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    // PDF view created
                  },
                  onPageChanged: (int? page, int? total) {
                    setState(() {
                      _currentPage = page ?? 0;
                      _totalPages = total ?? 0;
                    });
                  },
                ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String fileName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fileName.isNotEmpty ? fileName : 'صورة',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Add share functionality if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مشاركة الصورة')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تحميل الصورة...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.white.withOpacity(0.6),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'فشل تحميل الصورة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('العودة'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.zoom_in,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'اسحب للتكبير والتصغير',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}