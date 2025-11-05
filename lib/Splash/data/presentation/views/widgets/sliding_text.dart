
import 'package:flutter/material.dart';

import '../../../../../helper/constants.dart';


class SlidingText extends StatelessWidget {
  const SlidingText({
    super.key,
    required this.slidingAnimation,
  });

  final Animation<Offset> slidingAnimation;

  @override
  Widget build(BuildContext context) {
    Constants.setSize(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

    double screenWidth= MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: slidingAnimation,
      builder: (context,_) {
        return SlideTransition(
            position:slidingAnimation ,
            child: Column(
              children: [
                SizedBox(height: 10,),
               // Text("خدمات العذراء الصضاغة",textAlign: TextAlign.center,style: TextStyle(fontSize: screenWidth/18,fontFamily: "NotoSansArabic",fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                Text("كنيسة السيدة العذراء مريم بالصاغة",textAlign: TextAlign.center,style: TextStyle(fontSize: screenWidth/18,fontFamily: "NotoSansArabic",fontWeight: FontWeight.bold,color: Colors.blueGrey),),
              ],
            ));
      },
    );
  }
}
