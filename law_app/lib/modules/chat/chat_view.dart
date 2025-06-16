import 'dart:async';
import 'dart:developer' as dev;
import 'package:law_app/constants/imports.dart';
import 'package:law_app/modules/chat/chat_message.dart';
import 'package:law_app/widgets/custom_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<MessageModel> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;


  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(MessageModel(fullText: text, isUser: true, displayedText: text));
      _textController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await queryLegalModel(text);

      final botMessage = MessageModel(
        fullText: response,
        isUser: false,
        displayedText: "",
        isTyping: true,
      );

      setState(() {
        _messages.add(botMessage);
      });

      _scrollToBottom();
      _startTyping(botMessage);
    } catch (e) {
      setState(() {
        _messages.add(MessageModel(
          fullText: "Error: ${e.toString()}",
          isUser: false,
          displayedText: "Error: ${e.toString()}",
        ));
        _isLoading = false;
      });
    }
  }

  void _startTyping(MessageModel message) {
    int index = 0;
    const duration = Duration(milliseconds: 10);

    Timer.periodic(duration, (timer) {
      if (index < message.fullText.length) {
        setState(() {
          message.displayedText += message.fullText[index];
        });
        index++;
      } else {
        timer.cancel();
        setState(() {
          message.isTyping = false;
          _isLoading = false;
        });
      }
    });
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
        snackBarWidget("Error: ${response.statusCode}\nContact developers")
      );
      return "Error: ${response.statusCode}\nContact developers";
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
    _scrollController.dispose();
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_open, color: whiteColor, size: 23.sp),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: CustomDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromRGBO(44, 49, 55, 1),
              const Color.fromRGBO(44, 49, 55, 1),
            ],
            stops: [0.0, 0.75],
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
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ChatMessage(
                      text: message.displayedText,
                      isUser: message.isUser,
                    );
                  }
                ),
              ),
        
              if (_isLoading) 
              LoadingAnimationWidget.waveDots(
                size: 50,
                color: pryColor
              ),
              Container(
                height: 50.h,
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
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: pryColor,
                        shape: BoxShape.circle
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: whiteColor, size: 17.sp,),
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

class MessageModel {
  final String fullText;
  final bool isUser;
  String displayedText; // mutable only for bot messages
  bool isTyping;

  MessageModel({
    required this.fullText,
    required this.isUser,
    this.displayedText = "",
    this.isTyping = false,
  });
}
