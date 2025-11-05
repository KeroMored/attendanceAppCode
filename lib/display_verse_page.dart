// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../helper/bible_verse_service.dart';
import '../helper/constants.dart';

class DisplayVersePage extends StatelessWidget {
  const DisplayVersePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(
          'آية اليوم',
          style: TextStyle(
            fontSize: Constants.deviceWidth / 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
                  leading: MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: Constants.deviceWidth * 0.06,
            ),
          ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<String>(
          future: BibleVerseService.getTodayVerse(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueGrey,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('حدث خطأ في تحميل الآية'),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_quote,
                          size: 40,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          snapshot.data!,
                          style: TextStyle(
                            fontSize: Constants.deviceWidth / 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}