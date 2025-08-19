import 'dart:async';
import 'dart:developer' as dev;
import 'package:law_app/constants/imports.dart';
import 'package:law_app/models/conversation.dart';
import 'package:law_app/models/message.dart';
import 'package:law_app/modules/auth/login_view.dart';
import 'package:law_app/modules/auth/profile_view.dart';
import 'package:law_app/modules/chat/chat_message.dart';
import 'package:law_app/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  
  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<MessageViewModel> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _currentConversationId;
  List<Conversation> _conversations = [];
  Map<String, dynamic>? _userData = {};

  Timer? _typingTimer;
  bool _isTypingStopped = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user data
      _userData = await _apiService.getUserData();
      dev.log("User data retrieved: ${_userData.toString()}");
      
      // Load conversations
      await _fetchConversations();
      
      // If a specific conversation was provided, load it
      if (widget.conversationId != null) {
        dev.log("Loading specific conversation: ${widget.conversationId}");
        await _loadConversation(widget.conversationId!);
      } 
      // Otherwise, if we have conversations, load the most recent one
      else if (_conversations.isNotEmpty) {
        dev.log("Loading most recent conversation: ${_conversations.first.id}");
        await _loadConversation(_conversations.first.id);
      } else {
        // No conversations yet, set up for a new conversation
        dev.log("No conversations found, setting up for new conversation");
        setState(() {
          _currentConversationId = null;
        });
      }
    } catch (e) {
      dev.log("Error initializing chat: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final result = await _apiService.getConversations();
      
      if (result.containsKey('error')) {
        dev.log("Error fetching conversations: ${result['error']}");
        return;
      }
      
      final List<dynamic> conversationsData = result['conversations'] ?? [];
      dev.log("Fetched ${conversationsData.length} conversations");
      
      final List<Conversation> conversations = [];
      for (var data in conversationsData) {
        try {
          conversations.add(Conversation.fromJson(data));
        } catch (e) {
          dev.log("Error parsing conversation: $e, data: $data");
        }
      }
      
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      dev.log("Error fetching conversations: $e");
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
      _messages.clear();
    });
    
    try {
      dev.log("Loading conversation messages for ID: $conversationId");
      final result = await _apiService.getConversationMessages(conversationId);
      
      if (result.containsKey('error')) {
        dev.log("Error loading conversation: ${result['error']}");
        return;
      }
      
      final List<dynamic> messagesData = result['messages'] ?? [];
      dev.log("Fetched ${messagesData.length} messages for conversation");
      
      final List<Message> messages = [];
      for (var data in messagesData) {
        try {
          messages.add(Message.fromJson(data));
        } catch (e) {
          dev.log("Error parsing message: $e, data: $data");
        }
      }
      
      setState(() {
        _currentConversationId = conversationId;
        _messages.clear();
        
        for (var msg in messages) {
          _messages.add(
            MessageViewModel(
              fullText: msg.content,
              isUser: msg.isUser,
              displayedText: msg.content,
              isTyping: false,
            ),
          );
        }
      });
      
      _scrollToBottom();
    } catch (e) {
      dev.log("Error loading conversation: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    
    setState(() {
      _messages.add(MessageViewModel(
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
      bool isNewConversation = _currentConversationId == null;
      dev.log("Sending message. New conversation: $isNewConversation, Conversation ID: ${_currentConversationId ?? 'null'}");
      
      final result = await _apiService.sendMessage(
        text,
        conversationId: _currentConversationId,
        createNewConversation: isNewConversation,
      );

      if (result.containsKey('error')) {
        dev.log("Error sending message: ${result['error']}");
        setState(() {
          _messages.add(MessageViewModel(
            fullText: "Error: ${result['error']}",
            isUser: false,
            displayedText: "Error: ${result['error']}",
          ));
          _isLoading = false;
        });
        return;
      }

      // If this is a new conversation, update the conversation ID and fetch conversations
      if (isNewConversation || result['conversationId'] != _currentConversationId) {
        String newId = result['conversationId']?.toString() ?? '';
        dev.log("New conversation created or ID changed. New ID: $newId");
        setState(() {
          _currentConversationId = newId;
        });
        await _fetchConversations();
      }

      final botMessage = MessageViewModel(
        fullText: result['response']?.toString() ?? "No response received",
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
      dev.log("Exception sending message: $e");
      setState(() {
        _messages.add(MessageViewModel(
          fullText: "Error: ${e.toString()}",
          isUser: false,
          displayedText: "Error: ${e.toString()}",
        ));
        _isLoading = false;
      });
    }
  }

  void _startTyping(MessageViewModel message) {
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

  void _startNewConversation() {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar("Started a new conversation")
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    await _apiService.clearAuthData();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
      appBar: AppBar(
        title: Image.asset('assets/logo.png', width: 30.sp),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(44, 49, 55, 1),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: whiteColor, size: 23.sp),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: whiteColor, size: 23.sp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
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
              Center(child: Image.asset('assets/logo.png', width: 50.sp)),
          
              Gap(20.h),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 15.sp),
                  Gap(5.w),
                  Flexible(
                    child: Column(
                      children: [ 
                        Text(
                          "User ID: ${_userData?['userId'] ?? 'User'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Gap(10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversations', 
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.white
                    ),
                  ),
                  Row(
                    children: [
                      // New conversation button
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.white, size: 15.sp),
                        onPressed: () {
                          Navigator.pop(context);
                          _startNewConversation();
                        },
                      ),
                      // Refresh button
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white, size: 15.sp),
                        onPressed: () async {
                          await _fetchConversations();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              _buildSnackBar("Conversations refreshed")
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
          
              Flexible(
                child: _conversations.isEmpty
                  ? Center(
                      child: Text(
                        "No conversations yet", 
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        final isActive = conversation.id == _currentConversationId;
                        
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _loadConversation(conversation.id);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isActive 
                                  ? pryColor.withOpacity(0.2) 
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: isActive ? pryColor : Colors.white70,
                                    size: 16.sp,
                                  ),
                                  Gap(8.w),
                                  Expanded(
                                    child: Text(
                                      conversation.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: isActive ? pryColor : Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),

              GestureDetector(
                onTap: _logout,
                child: Row(
                  spacing: 10.w,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white70, size: 15.sp),
                    Text(
                      "Logout",
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Gap(20.h),
            ],
          ),
        ),
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
                child: _messages.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white.withOpacity(0.5),
                            size: 50.sp,
                          ),
                          Gap(16.h),
                          Text(
                            "Start a conversation",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16.sp,
                            ),
                          ),
                          Gap(8.h),
                          Text(
                            "Ask a legal question to get started",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return ChatMessage(
                          text: message.displayedText,
                          isUser: message.isUser,
                        );
                      },
                    ),
              ),
        
              if (_isLoading) 
                LoadingAnimationWidget.waveDots(
                  size: 50,
                  color: pryColor
                ),
                
              Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 74, 83, 94),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24.r), 
                    topLeft: Radius.circular(24.r)
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text field
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
                
                    // Send/Stop button
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

  SnackBar _buildSnackBar(String text) {
    return SnackBar(
      content: Text(
        text, 
        style: GoogleFonts.poppins(
          fontSize: 13.sp, 
          fontWeight: FontWeight.w500, 
          color: Colors.white
        ),
      ),
      backgroundColor: pryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      duration: Duration(seconds: 3),
    );
  }
}

class MessageViewModel {
  final String fullText;
  final bool isUser;
  String displayedText;
  bool isTyping;

  MessageViewModel({
    required this.fullText,
    required this.isUser,
    this.displayedText = "",
    this.isTyping = false,
  });
}


