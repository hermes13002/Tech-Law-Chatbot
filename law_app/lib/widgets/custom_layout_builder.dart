import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomLayoutBuilder extends StatelessWidget {
  final double? padHorizontal;
  final double? padVertical;
  const CustomLayoutBuilder({super.key, required this.child, this.padHorizontal, this.padVertical});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: padHorizontal ?? 16.w,
                    vertical: padVertical ?? 8.h
                  ),
                  child: child
                ),
              ),
            );
          }
      ),
    );
  }
}