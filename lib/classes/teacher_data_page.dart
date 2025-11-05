// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/teacher_model.dart';

class TeacherDataPage extends StatefulWidget {
  final TeacherModel teacher;
  final String generatedPassword;
  final String adminPassword;

  const TeacherDataPage({
    Key? key,
    required this.teacher,
    required this.generatedPassword,
    required this.adminPassword,
  }) : super(key: key);

  @override
  State<TeacherDataPage> createState() => _TeacherDataPageState();
}

class _TeacherDataPageState extends State<TeacherDataPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getShareText() {
    return '''
🎉 تم إنشاء حساب جديد بنجاح!

👤 اسم الخادم: ${widget.teacher.name}
📱 رقم الهاتف: ${widget.teacher.phoneNumber1 ?? 'غير محدد'}
🏠 العنوان: ${widget.teacher.address ?? 'غير محدد'}
👔 الدور: ${widget.teacher.role.displayName}

🔐 معلومات تسجيل الدخول:
• كلمة مرور الخادم: ${widget.generatedPassword}
• كلمة مرور الإدارة: ${widget.adminPassword}

⚠️ احتفظ بهذه المعلومات في مكان آمن

    ''';
  }

  Future<void> _shareToApps() async {
    try {
      await Share.share(
        _getShareText(),
        subject: 'بيانات الخادم الجديد - ${widget.teacher.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المشاركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _getShareText()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ البيانات للحافظة'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getRoleColor() {
    switch (widget.teacher.role) {
      case TeacherRole.admin:
        return Colors.orange;
      case TeacherRole.superAdmin:
        return Colors.red;
      case TeacherRole.user:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.teacher.role) {
      case TeacherRole.admin:
        return Icons.admin_panel_settings;
      case TeacherRole.superAdmin:
        return Icons.security;
      case TeacherRole.user:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'بيانات الخادم الجديد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _copyToClipboard,
            tooltip: 'نسخ البيانات',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'تم إنشاء الحساب بنجاح!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'مرحباً بك ${widget.teacher.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                                    const SizedBox(height: 16),

    const Text(
                    'مشاركة البيانات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
              
                      Expanded(
                        child: _buildShareButton(
                          onPressed: _shareToApps,
                          icon: Icons.share,
                          label: 'مشاركة',
                          color: Colors.blue,
                          enabled: true,
                        ),
                      ),
                    ],
                  ),

        

                  const SizedBox(height: 24),

                  // Teacher Information Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRoleColor().withOpacity(0.1),
                                  border: Border.all(
                                    color: _getRoleColor(),
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  _getRoleIcon(),
                                  size: 30,
                                  color: _getRoleColor(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.teacher.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor().withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.teacher.role.displayName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _getRoleColor(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Contact Information
                          _buildInfoRow(
                            Icons.phone,
                            'رقم الهاتف الأول',
                            widget.teacher.phoneNumber1 ?? 'غير محدد',
                            Colors.green,
                          ),
                          if (widget.teacher.phoneNumber2?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.phone_android,
                              'رقم الهاتف الثاني',
                              widget.teacher.phoneNumber2!,
                              Colors.blue,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.location_on,
                            'العنوان',
                            widget.teacher.address ?? 'غير محدد',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Information Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.red,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'معلومات تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildPasswordRow(
                            'كلمة مرور الخادم',
                            widget.generatedPassword,
                            Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordRow(
                            'كلمة مرور الإدارة',
                            widget.adminPassword,
                            Colors.purple,
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'احتفظ بهذه المعلومات في مكان آمن',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Share Buttons
              
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow(String label, String password, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  password,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: password));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم نسخ $label'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.copy,
              color: color,
              size: 18,
            ),
            tooltip: 'نسخ',
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey[300],
        foregroundColor: enabled ? Colors.white : Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: enabled ? 4 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}