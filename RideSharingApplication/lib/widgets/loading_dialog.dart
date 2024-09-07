import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String messageTxt;

  const LoadingDialog({super.key, required this.messageTxt});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 3,

            ),
            const SizedBox(width: 30),
            Expanded(
              child: Text(
                messageTxt,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
//
// class LoadingDialog extends StatelessWidget {
//   final String messageTxt;
//
//   const LoadingDialog({super.key, required this.messageTxt});
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       backgroundColor: Colors.white,
//       child: Container(
//         margin: const EdgeInsets.all(15),
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white70,
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               const SizedBox(width: 5,),
//
//               const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green),),
//
//               const SizedBox(width: 8,),
//
//               Text(
//                 messageTxt,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
