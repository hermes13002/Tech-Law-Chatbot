import 'dart:developer' as dev;
import 'package:law_app/constants/constant.dart';
import 'package:law_app/constants/imports.dart';
import 'package:law_app/widgets/custom_appbar.dart';
import 'package:law_app/widgets/custom_layout_builder.dart';
import 'package:law_app/widgets/custom_textfield.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  

  Future<void> _sendMessage(String text) async {
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(text: text, isUser: true));
      _textController.clear();
    });

    try {
      final response = await queryLegalModel(text);
      
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: ${e.toString()}", isUser: false));
        _isLoading = false;
      });
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
          SnackBar(content: Text("No reply from server.")),
        );
        return "No reply from server.";
      }
      return reply;
    } else {
      dev.log("Error: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
      );
      return "Error: ${response.body}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: bgColor,
      appBar: AppBarWidget(
        title: 'TECH LAW CHATBOT',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 80, 80, 80),
              darkColorShade,
            ],
            stops: [0.0, 0.75], // bgColor for 75%, white for the last 25%
          ),
        ),
        child: CustomLayoutBuilder(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _messages[index],
                ),
              ),
        
              if (_isLoading) LinearProgressIndicator(),
              Row(
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
                    )
                  ),
              
                  // button
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: tfieldColor,
                      shape: BoxShape.circle
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: whiteColor, size: 20.sp,),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                  color: tfieldColor,
                  borderRadius: BorderRadius.circular(12.r)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "You",
                      style: GoogleFonts.poppins(color: whiteColorShade, fontWeight: FontWeight.bold, fontSize: 12.5.sp),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      text,
                      style: GoogleFonts.poppins(color: whiteColor, fontWeight: FontWeight.w500, fontSize: 15.sp),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
          ]
        : [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7, // 70% of screen width
              ),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tfieldColor,
                  borderRadius: BorderRadius.circular(12.r)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Legal Assistant",
                      style: GoogleFonts.poppins(color: whiteColorShade, fontWeight: FontWeight.bold, fontSize: 12.5.sp),
                    ),
                    Text(
                      text,
                      style: GoogleFonts.poppins(color: whiteColor, fontWeight: FontWeight.w500, fontSize: 15.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ),
    );
  }
}