import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:law_app/constants/imports.dart';
import 'package:law_app/modules/chat/chat_view.dart';
import 'dart:developer' as dev;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    wakeServer();
    super.initState();
    Timer(
      const Duration(seconds: 5),
      () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const ChatScreen()
        )
      )
    );
  }

  Future<void> wakeServer() async {
    try {
      await http.get(Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/ping"));
    } catch (e) {
      dev.log("Ping failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromRGBO(0, 97, 255, 1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png'
              ).animate()
              .fadeIn(duration: 2000.ms, curve: Curves.easeInOut),
              
              Text(
                'TECH LAW CLUB, LASU',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2
                ),
              ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: Colors.lightBlueAccent)
              .animate()
              .then(delay: 1000.ms)
              .fadeIn(duration: 2000.ms, curve: Curves.easeInOut)
      
            ],
          )
        
        ),
      ),
    );
  }
}