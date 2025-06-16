// import 'dart:async';

import 'package:flutter/services.dart';
import 'package:law_app/constants/imports.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final replyText = text;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: isUser
            ? [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      replyText,
                      style: GoogleFonts.poppins(
                          color: whiteColor,
                          fontWeight: FontWeight.w300,
                          fontSize: 12.sp),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ]
            : [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: Container(
                        padding: EdgeInsets.only(left: 8, right: 8, top: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(44, 49, 55, 1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.r),
                            topRight: Radius.circular(12.r),
                            bottomRight: Radius.circular(12.r),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Legal Assistant",
                              style: GoogleFonts.spaceGrotesk(
                                  color: whiteColorShade,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5.sp),
                            ),
                            SizedBox(height: 5),
                            Text(
                              replyText,
                              textAlign: TextAlign.justify,
                              style: GoogleFonts.poppins(
                                  color: whiteColor,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: whiteColorShade, size: 18.sp),
                      tooltip: "Copy",
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: replyText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: pryColor,
                            content: Text("Copied to clipboard",
                              style: GoogleFonts.poppins(
                                color: whiteColorShade,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5.sp
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
      ),
    );
  }
}
