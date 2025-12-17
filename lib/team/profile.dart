import 'package:flutter/material.dart';

import '../helper/constants.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});
  
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
          child: Text(
            'الحساب',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ],
    );
  }
}