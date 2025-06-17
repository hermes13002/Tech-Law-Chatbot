import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:law_app/modules/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LegalChatbotApp());
}

class LegalChatbotApp extends StatelessWidget {
  const LegalChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tech Law Chatbot',
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor),
              ),
              child: child!,
            );
          },
          home: child,
        );
      },
      child: SplashScreen(),
    );
  }
}

