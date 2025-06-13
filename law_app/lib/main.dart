import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:law_app/modules/splash/splash_view.dart';

void main() async {
  runApp(LegalChatbotApp());
}

class LegalChatbotApp extends StatelessWidget {
  const LegalChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Quiz-ter App',
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      }
    );
  }
}

