import 'package:flutter/material.dart';
import '../helper/constants.dart';

class SelectDateTime extends StatefulWidget {
  final DateTime initialDateTime;

  const SelectDateTime({super.key, required this.initialDateTime});

  @override
  State<SelectDateTime> createState() => _SelectDateTimeState();
}

class _SelectDateTimeState extends State<SelectDateTime> {
  late DateTime selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDateTime = widget.initialDateTime;
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'اختر التاريخ',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          selectedDateTime.hour,
          selectedDateTime.minute,
        );
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      helpText: 'اختر الوقت',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedDateTime = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "اختيار التاريخ والوقت",
          style: TextStyle(fontSize: Constants.deviceWidth / 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, size: Constants.arrowBackSize),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedDateTime);
            },
            child: Text(
              'تأكيد',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: Constants.deviceWidth / 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            
            // Current selected date and time display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueGrey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.shade100,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'التاريخ والوقت المحدد',
                    style: TextStyle(
                      fontSize: Constants.deviceWidth / 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blueGrey, size: Constants.deviceWidth / 20),
                      SizedBox(width: 10),
                      Text(
                        '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year}',
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.blueGrey, size: Constants.deviceWidth / 20),
                      SizedBox(width: 10),
                      Text(
                        '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: Constants.deviceWidth / 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Enhanced Calendar Display
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueGrey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.shade100,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      'التقويم الشهري',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Constants.deviceWidth / 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'اضغط لاختيار التاريخ من التقويم',
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 22,
                            color: Colors.blueGrey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _selectDate,
                          icon: Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: Constants.deviceWidth / 15,
                          ),
                          label: Text(
                            'فتح التقويم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Constants.deviceWidth / 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 25),
            
            // Time selection section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade100,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      'اختيار الوقت',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Constants.deviceWidth / 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'اضغط لاختيار وقت الاجتماع',
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 22,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _selectTime,
                          icon: Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: Constants.deviceWidth / 15,
                          ),
                          label: Text(
                            'اختيار الوقت',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Constants.deviceWidth / 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 25),
            
            // Reset to current time button
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedDateTime = DateTime.now();
                  });
                },
                icon: Icon(
                  Icons.refresh,
                  color: Colors.blueGrey,
                  size: Constants.deviceWidth / 18,
                ),
                label: Text(
                  'استخدام الوقت الحالي',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: Constants.deviceWidth / 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blueGrey, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Confirm button at bottom
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, selectedDateTime);
                },
                icon: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: Constants.deviceWidth / 15,
                ),
                label: Text(
                  'تأكيد الاختيار والعودة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Constants.deviceWidth / 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
