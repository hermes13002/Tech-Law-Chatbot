import 'dart:async';
// import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:law_app/constants/imports.dart';
import 'package:law_app/modules/auth/login_view.dart';
import 'package:law_app/modules/chat/chat_view.dart';
import 'package:law_app/services/api_service.dart';
import 'dart:developer' as dev;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    // wakeServer();
    
    // Check authentication after 3 seconds to allow animation to play
    Timer(
      const Duration(seconds: 3),
      () => _checkAuthAndNavigate(),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final isAuthenticated = await _apiService.isAuthenticated();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAuthenticated 
              ? const ChatScreen() 
              : const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      dev.log("Auth check failed: $e");
      // Default to login screen on error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // Future<void> wakeServer() async {
  //   try {
  //     await http.get(Uri.parse("https://tlc-shelf-api.globeapp.dev/ping"));
  //   } catch (e) {
  //     dev.log("Ping failed: $e");
  //   }
  // }

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