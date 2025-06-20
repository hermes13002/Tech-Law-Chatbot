import 'dart:async';
import 'dart:developer' as dev;
import 'package:law_app/constants/imports.dart';
import 'package:law_app/modules/chat/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  List<Map<String, dynamic>> chatHistory = [];
  List<String> chatTopics = [];
  String? userId;
  String? userDisplay;
  String currentTopic = "";

  Timer? _typingTimer;
  bool _isTypingStopped = false;

  @override
  void initState() {
    super.initState();
    _initUserIdAndHistory();
    
  }

  Future<void> _initUserIdAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId == null) {
      final response = await get(
        Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/user_id"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        userId = data['user_id'];
        await prefs.setString('userId', userId!);
      } else {
        userId = "anonymous";
      }
    }
    await _fetchChatHistory();
    await _loadChatForTopic(currentTopic);
  }

  Future<void> _fetchChatHistory() async {
    if (userId == null) return;

    final response = await get(
      Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/chat_history?user_id=$userId"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> topics = [];
      if (data['chats'] != null) {
        data['chats'].forEach((topic, history) {
          topics.add(topic);
        });
      }
      setState(() {
        chatTopics = topics;
      });
    } else {
      setState(() {
        chatTopics = [];
      });
    }
  }

  Future<void> _loadChatForTopic(String topic) async {
    if (userId == null) return;
    final response = await get(
      Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/chat_history?user_id=$userId"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final chats = data['chats'] ?? {};
      final history = chats[topic] as List<dynamic>? ?? [];
      setState(() {
        currentTopic = topic;
        _messages.clear();
        for (var msg in history) {
          _messages.add(
            MessageModel(
              fullText: msg['content'] ?? '',
              isUser: msg['role'] == 'user',
              displayedText: msg['content'] ?? '',
              isTyping: false,
            ),
          );
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String text) async {
     if (text.trim().isEmpty || _isLoading) return;
    setState(() {
      _messages.add(MessageModel(
        fullText: text,
        isUser: true,
        displayedText: text
      ));
      _textController.clear();
      _isLoading = true;
      _isTypingStopped = false;
    });

    _scrollToBottom();

    try {
      final reply = await queryLegalModel(text);

      final botMessage = MessageModel(
        fullText: reply,
        isUser: false,
        displayedText: "",
        isTyping: true,
      );

      setState(() {
        _messages.add(botMessage);
      });

      _scrollToBottom();
      _startTyping(botMessage);
      dev.log("userId: $userId");
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
    const duration = Duration(milliseconds: 5);

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(duration, (timer) {
      if (_isTypingStopped) {
        timer.cancel();
        setState(() {
          message.isTyping = false;
          _isLoading = false;
        });
        return;
      }
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

  void _stopTyping() {
    setState(() {
      _isTypingStopped = true;
      _isLoading = false;
    });
    _typingTimer?.cancel();
    // Optionally, finish displaying the full message immediately:
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      setState(() {
        _messages.last.displayedText = _messages.last.fullText;
        _messages.last.isTyping = false;
      });
    }
  }

  Future<String> queryLegalModel(String query) async {
    final prefs = await SharedPreferences.getInstance();
    userId ??= prefs.getString('userId') ?? "anonymous";

    String topic = currentTopic.isNotEmpty ? currentTopic : "general_law";

    final response = await post(
      Uri.parse("https://tech-law-chatbot-backend-api.onrender.com/chat"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "message": query,
        "user_id": userId,
        "topic": topic,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final reply = data['reply'];
      return reply ?? "No reply.";
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
    _typingTimer?.cancel();
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
            icon: Icon(Icons.menu , color: whiteColor, size: 23.sp),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: 230.w,
        backgroundColor: const Color.fromRGBO(44, 49, 55, 1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(30.h),
              Center(child: Image.asset('assets/logo.png', width: 50.sp, )),

              Gap(20.h),
              Row(
                spacing: 5.w,
                children: [
                  Icon(Icons.person, color: Colors.white, size: 15.sp),

                  Flexible(
                    child: Text(
                      "User ID: $userId",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              
              Gap(10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chat History', style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white),),

                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white, size: 15.sp,),
                    onPressed: () async {
                      await _fetchChatHistory();
                      ScaffoldMessenger.of(context).showSnackBar(snackBarWidget("Chat history refreshed."));
                    },
                  ),
                ],
              ),
              // Divider(endIndent: 180.sp,),

              Flexible(
                child: chatTopics.isEmpty
                ? Text("No chat history.", style: TextStyle(color: Colors.white70))
                : ListView.builder(
                  itemCount: chatTopics.length,
                  itemBuilder: (context, index) {
                    final topic = chatTopics[index];
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await _loadChatForTopic(topic);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              topic.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.white, size: 15.sp),
                            onPressed: () async {
                              // await _clearChatHistory(topic);
                              ScaffoldMessenger.of(context).showSnackBar(snackBarWidget("Chat history cleared."));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        )
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
                        enabled: !_isLoading,
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
                        icon: Icon(
                          _isLoading ? Icons.stop : Icons.send,
                          color: whiteColor,
                          size: 17.sp,
                        ),
                        onPressed: _isLoading
                          ? _stopTyping
                          : () => _sendMessage(_textController.text),
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
  String displayedText;
  bool isTyping;

  MessageModel({
    required this.fullText,
    required this.isUser,
    this.displayedText = "",
    this.isTyping = false,
  });
}
