import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // await dotenv.load();
  runApp(LegalChatbotApp());
}

class LegalChatbotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legal Chatbot',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> wakeServer() async {
    try {
      await http.get(Uri.parse("https://your-backend.onrender.com/ping"));
    } catch (e) {
      print("Ping failed: $e");
    }
  }

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
    final response = await http.post(
      Uri.parse("http://192.168.236.207:5000/chat"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"message": query}),
    );

    if (response.statusCode == 200) {
      final reply = json.decode(response.body)['reply'];
      print("Chatbot: $reply");
      return reply ?? "No reply from server.";
    } else {
      print("Error: ${response.body}");
      return "Error: ${response.body}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Legal Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(hintText: "Ask a legal question..."),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: isUser ? Icon(Icons.person) : Icon(Icons.gavel),
            backgroundColor: isUser ? Colors.blue : Colors.green,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? "You" : "Legal Assistant",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}