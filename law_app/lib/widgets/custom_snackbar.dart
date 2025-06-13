import 'package:flutter/material.dart';

class SnackbarWidget extends StatelessWidget {
  final Widget content;
  const SnackbarWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return SnackBar(
      content: content,
      backgroundColor: Color.fromRGBO(255, 165, 0, 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}