// import 'package:flutter/material.dart';
//
// class AssociateMethods
// {
//   showSnackBarMsg(String msg, BuildContext cxt)
//   {
//     var snackBar = SnackBar(
//       content:
//       Text(msg,style: TextStyle(color: Colors.black),),
//       backgroundColor: Colors.white,
//       duration: Duration(milliseconds: 600),
//       shape: const Border.symmetric(horizontal: 100,),
//     );
//     ScaffoldMessenger.of(cxt).showSnackBar(snackBar);
//
//   }
// }
import 'package:flutter/material.dart';

class AssociateMethods {
  void showSnackBarMsg(String msg, BuildContext cxt) {
    // Create a snackbar with custom styling
    final snackBar = SnackBar(
      content: Text(
        msg,
        style: TextStyle(
          color: Colors.black, // Text color
          fontSize: 14, // Smaller font size for a sleek look
          fontWeight: FontWeight.w500, // Semi-bold text
        ),
      ),
      backgroundColor: Colors.white, // Slightly transparent black background
      duration: Duration(seconds: 2), // Duration of the snackbar display
      behavior: SnackBarBehavior.floating, // Makes the snackbar float
      elevation: 6, // Elevation to create a shadow effect
      margin: EdgeInsets.only(
        bottom: 80, // Positioning it higher for a floating effect
        left: 16,
        right: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Rounded corners for a clean look
      ),
    );

    ScaffoldMessenger.of(cxt).showSnackBar(snackBar);
  }
}
