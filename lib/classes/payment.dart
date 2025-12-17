import 'package:attendance/helper/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home_page.dart';

class Payment extends StatefulWidget {
  final String paymentStatus;
  const Payment({super.key, required this.paymentStatus});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final String _paymentUrl = "https://ipn.eg/S/keromored/instapay/3urxKb";
  void openWhatsApp(String phoneNumber) async {
    final String whatsappUrl = "https://wa.me/$phoneNumber";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      // Handle WhatsApp launch error
      debugPrint('WhatsApp launch error: ${e.toString()}');
    }
  }
  @override
  void initState() {
    super.initState();
    // Initialize payment status checking
    _checkPaymentStatus();
  }

  void _checkPaymentStatus() {
    // Check if payment status is valid
    if (widget.paymentStatus.isNotEmpty) {
      // Payment status received successfully
      debugPrint('Payment status: ${widget.paymentStatus}');
    }
  }

  void _launchURL() async {
    try {
      bool launched = await launchUrl(Uri.parse(_paymentUrl));
      if (!launched) {
        throw 'Could not launch $_paymentUrl';
      }
    } catch (e) {
      // Handle URL launch error
      debugPrint('Payment URL launch error: ${e.toString()}');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            (widget.paymentStatus == PaymentStatus.unpaid.toString().split('.').last )?
            Text(": you should pay to continue"):
            Text(": you have one week to pay "),
            ElevatedButton(

              style: ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                padding:WidgetStatePropertyAll(EdgeInsets.all(15)) ,
                  elevation: WidgetStatePropertyAll(5),
                  backgroundColor: WidgetStatePropertyAll(Colors.blueGrey)),
              onPressed: _launchURL,
              child: Text("الدفع عن طريق انستاباى ", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: MediaQuery.of(context).size.width/20),),
            ),

            (widget.paymentStatus != PaymentStatus.unpaid.toString().split('.').last )?

            TextButton(onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Homepage()),
              );
            }, child: Text("استمرار ",style: TextStyle(decoration: TextDecoration.underline,fontSize: MediaQuery.of(context).size.width/15,color: Colors.black),
            )):
                Container(),
            Spacer(),
            GestureDetector(
              onTap: () {
                openWhatsApp("1222703436");
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Created By: Kero Mored",style: TextStyle(fontStyle: FontStyle.italic,fontSize: Constants.deviceWidth/25),),

                  Text(

                    "للتواصل واتساب",
                    style: TextStyle(decoration: TextDecoration.underline,fontStyle: FontStyle.italic,fontSize: Constants.deviceWidth/25),
                  ),

                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
