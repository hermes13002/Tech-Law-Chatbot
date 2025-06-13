
import 'package:law_app/constants/constant.dart';
import 'package:law_app/constants/imports.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppBarWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // leading: InkWell(
      //   onTap: (){
      //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SectionScreen()));
      //   },
      //   child: const Padding(
      //     padding: EdgeInsets.only(left: 20),
      //     child: Icon(Icons.arrow_back_ios_new_rounded),
      //   )
      // ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18.sp,)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: const Color.fromARGB(255, 80, 80, 80),
      foregroundColor: pryColor,
      actions: [
        // Padding(
        //   padding: EdgeInsets.only(right: 20.w),
        //   child: InkWell(
        //     onTap: () {},
        //     child: Container(
        //       padding: const EdgeInsets.all(8),
        //       decoration: const BoxDecoration(
        //         color: Colors.lightBlueAccent,
        //         shape: BoxShape.circle,
        //       ),
        //       child: const Icon(Icons.contact_support_outlined, color: Colors.black,)
        //     )
        //   ),
        // ),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(50);
}