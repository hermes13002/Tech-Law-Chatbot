import 'package:law_app/constants/imports.dart';

class CustomTextfield extends StatelessWidget {
  final String text;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool obscureText;
  final Widget? suffixIcon;
  const CustomTextfield({super.key, required this.text, this.controller, this.validator, this.onChanged, required this.obscureText, this.suffixIcon, this.onFieldSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: whiteColor,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: whiteColor),
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: text,
        hintStyle: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: whiteColorShade),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: tfieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: tfieldColor),
        ),
        enabled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r), 
          borderSide: BorderSide(color: tfieldColor)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r), 
          borderSide: BorderSide(color: whiteColor, width: 2)
        ),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}