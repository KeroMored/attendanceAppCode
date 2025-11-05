import 'package:flutter/material.dart';

import 'constants.dart';

class SpecialButton extends StatefulWidget {

 final String label;
 final   VoidCallback onPressed;
 final String imagePath;
  const SpecialButton({super.key, required this.label, required this.onPressed, required this.imagePath});

  @override
  State<SpecialButton> createState() => _SpecialButtonState();
}

class _SpecialButtonState extends State<SpecialButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Constants.deviceWidth/1.1,
      child:
      ElevatedButton(

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          elevation: 5,
        ),
        onPressed:widget. onPressed,
        child: ListTile(

          trailing: AspectRatio(

              aspectRatio: 1,
              child: Container(

                  color: Colors.white,
                  child: Image.asset(

                      fit: BoxFit.fill,
                      widget.imagePath))),
          //Icon(icon,color: Colors.white,size: Constants.deviceWidth/20,),
          title: Center(
            child: Text(
              textAlign: TextAlign.center,
              widget.label,
              style: TextStyle(

                fontSize: Constants.deviceHeight/40,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );


 }
}
