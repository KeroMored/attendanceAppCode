// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helper/constants.dart';

class TeacherProfilePage extends StatelessWidget {
  final Map<String, dynamic> teacherData;

  const TeacherProfilePage({super.key, required this.teacherData});

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
  
  @override
  Widget build(BuildContext context) {


    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(
          'بيانات الخادم',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Avatar and Name Section
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        teacherData['name'],
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildRoleBadge(teacherData['role'] ?? 'user'),
                      
                      if (teacherData['teacherPassword'] != null && teacherData['teacherPassword'].isNotEmpty) ... [
                        SizedBox(height: 16),
                        _buildPasswordCard(teacherData['teacherPassword']!),
                      ]
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Information Cards
              _buildInfoCard(
                'رقم الهاتف الأول',
                teacherData['phoneNumber1'] ?? 'غير محدد',
                Icons.phone,
                isPhone: true,
              ),
              if (teacherData['phoneNumber2'] != null && teacherData['phoneNumber2'].isNotEmpty)
                _buildInfoCard(
                  'رقم الهاتف الثاني', 
                  teacherData['phoneNumber2']!,
                  Icons.phone_android,
                  isPhone: true,
                ),
              _buildInfoCard(
                'العنوان',
                teacherData['address'] ?? 'غير محدد',
                Icons.location_on,
              ),
              if (teacherData['students'] != null && teacherData['students'].isNotEmpty)
                _buildInfoCard(
                  'الطلاب',
                  teacherData['students']!,
                  Icons.people,
                  isMultiLine: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(String password) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key, size: 18, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            password,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor = Colors.blueGrey;
    String displayName = 'خادم'; // Default to user
    
    switch (role) {
      case 'admin':
        badgeColor = Colors.blue;
        displayName = 'مشرف';
        break;
      case 'superAdmin':
        badgeColor = Colors.deepPurple;
        displayName = 'ادمن';
        break;
      case 'user':
        badgeColor = Colors.blueGrey;
        displayName = 'خادم';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayName,
        style: TextStyle(
          fontSize: Constants.deviceWidth / 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {bool isPhone = false, bool isMultiLine = false}) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMultiLine ? 14 : 18,
                    color: isPhone ? Colors.blue : Colors.black87,
                    decoration: isPhone ? TextDecoration.underline : TextDecoration.none,
                  ),
                  textAlign: isMultiLine ? TextAlign.justify : TextAlign.start,
                ),
if (isPhone)
                Row(
                  children: [

                    IconButton(onPressed: (){
                    _makePhoneCall(value);
                    }, icon: Icon(Icons.call, size: 16, color: Colors.blue),),
                     IconButton(
                                      icon: Icon(MdiIcons.whatsapp,
                                          color: Colors.green),
                                      onPressed: () {
                                        openWhatsApp(value);
                                      },
                                    ),
                
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}