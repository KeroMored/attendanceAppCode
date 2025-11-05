import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get_it/get_it.dart';
import '../helper/constants.dart';
import '../helper/appwrite_services.dart';
import '../models/pray_model.dart';

class AddPrayPage extends StatefulWidget {
  const AddPrayPage({Key? key}) : super(key: key);

  @override
  State<AddPrayPage> createState() => _AddPrayPageState();
}

class _AddPrayPageState extends State<AddPrayPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _visible = true;
  bool _isLoading = false;

  Future<void> _savePray() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final databases = GetIt.I<Databases>();
      final pray = PrayModel(
        name: _nameController.text.trim(),
        date: _selectedDate,
        isVisible: _visible,
        classId: Constants.classId,
        createdBy: Constants.classId,
      );

      await databases.createDocument(
        databaseId: AppwriteServices.databaseId,
        collectionId: AppwriteServices.prayCollectionId,
        documentId: ID.unique(),
        data: pray.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الصلاة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الصلاة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة صلاة جديدة'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الصلاة',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال عنوان الصلاة';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
       
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePray,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('حفظ', style: TextStyle(fontSize: 18)),
                ),
              ),
        
            ],
          ),
        ),
      ),
    );
  }
}