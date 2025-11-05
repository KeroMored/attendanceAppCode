

import 'package:flutter/material.dart';

import '../helper/constants.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage(Constants.footballStadium),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the player image
              Expanded(
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(1000)),
                    image: DecorationImage(

                      fit: BoxFit.fill,
                      image: AssetImage(Constants.golden,)),
                          
                  )
                            ),
              ),
              // Instructions text
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "نظام المواظبة\n احضر 12 اجتماع\n  كن لاعب الشهر \n احصل على جوائز\n  مين هيفوز بالحذاء الذهبي في نهاية المواظبة؟!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}