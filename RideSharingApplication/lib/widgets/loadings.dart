import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String messageTxt;

  const LoadingDialog({required this.messageTxt, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(messageTxt),
        ],
      ),
    );
  }
}
