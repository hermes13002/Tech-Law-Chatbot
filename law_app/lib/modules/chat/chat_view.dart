import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:law_app/constants/imports.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;


  Future<void> _sendMessage(String text) async {
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(text: text, isUser: true));
      _textController.clear();
    });

    _scrollToBottom();

    try {
      final response = await queryLegalModel(text);
      
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: ${e.toString()}", isUser: false));
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  Future<String> queryLegalModel(String query) async {
    final response = await post(
      Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/chat"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"message": query}),
    );

    if (response.statusCode == 200) {
      final reply = json.decode(response.body)['reply'];
      dev.log("Chatbot: $reply");

      if (reply == null || reply.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          snackBarWidget("No reply from server")
        );
        return "No reply from server.";
      }
      return reply;
    } else {
      dev.log("Error: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarWidget("Error: ${response.body}")
      );
      return "Error: ${response.body}";
    }
  }

  void _scrollToBottom() {
    // Wait for the next frame to ensure the message is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose(); // <-- Dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: bgColor,
      appBar: AppBar(
        title: Image.asset('assets/logo.png', width: 30.sp, ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(44, 49, 55, 1),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromRGBO(44, 49, 55, 1),
              const Color.fromRGBO(44, 49, 55, 1),
            ],
            stops: [0.0, 0.75], // bgColor for 75%, white for the last 25%
          ),
        ),
        child: CustomLayoutBuilder(
          padHorizontal: 0.w, padVertical: 0.h,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _messages[index],
                ),
              ),
        
              if (_isLoading) LinearProgressIndicator(),
              Container(
                height: 60.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w,),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 74, 83, 94),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(24.r), topLeft: Radius.circular(24.r))
                ),
                child: Row(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // textfield
                    Expanded(
                      child: CustomTextfield(
                        text: 'Ask a legal question...',
                        controller: _textController,
                        onFieldSubmitted: _sendMessage,
                        obscureText: false,
                        maxLines: 20,
                        minLines: 1,
                      )
                    ),
                
                    // button
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: pryColor,
                        shape: BoxShape.circle
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: whiteColor, size: 20.sp,),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SnackBar snackBarWidget(String text) {
    return SnackBar(
      content: Text(text, style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white),),
      backgroundColor: pryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      duration: Duration(seconds: 3),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, // Align user right, assistant left
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r), bottomLeft: Radius.circular(12.r))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text(
                    //   "You",
                    //   style: GoogleFonts.spaceGrotesk(color: whiteColorShade, fontWeight: FontWeight.bold, fontSize: 12.5.sp),
                    //   textAlign: TextAlign.right,
                    // ),
                    Text(
                      text,
                      style: GoogleFonts.poppins(color: whiteColor, fontWeight: FontWeight.w300, fontSize: 12.sp),
                      textAlign: TextAlign.right,
                    ),
                  ],
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
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r), bottomRight: Radius.circular(12.r))
                    ),
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Legal Assistant",
                          style: GoogleFonts.spaceGrotesk(color: whiteColorShade, fontWeight: FontWeight.bold, fontSize: 12.5.sp),
                        ),
                        Text(
                          text,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.poppins(color: whiteColor, fontWeight: FontWeight.w300, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.copy_rounded, color: whiteColorShade, size: 18.sp),
                  tooltip: "Copy",
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      snackBarWidget("Copied to clipboard")
                    );
                  },
                ),
              ],
            ),

            
          ],
      ),
    );
  }

  SnackBar snackBarWidget(String text) {
    return SnackBar(
      content: Text(text, style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white),),
      backgroundColor: pryColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: 70.h, right: 8.w, left: 8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      duration: Duration(seconds: 2),
    );
  }
}