import 'package:law_app/constants/imports.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromRGBO(44, 49, 55, 1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(30.h),
            Center(child: Image.asset('assets/logo.png', width: 50.sp, )),
            
            Gap(30.h),
            Text('Chat History', style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white),),
            Divider(endIndent: 180.sp,)


          ],
        ),
      )
    );
  }

  // Future<void> _clearChat() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final topicId = prefs.getString('topicId');
  //   if (topicId != null) {
  //     await post(
  //       Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/clear_history"),
  //       headers: {"Content-Type": "application/json"},
  //       body: json.encode({"topic_id": topicId}),
  //     );
  //     await prefs.remove('topicId');
  //   }
  //   setState(() {
  //     _messages.clear();
  //   });
  // }
}