import 'dart:convert';
import 'dart:math';
// import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

final env = dotenv.DotEnv();

final jwtSecret = env['JWT_SECRET'];
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
final _rnd = Random.secure();
final _uuid = Uuid();

// Generate a unique conversation ID with 'conv_' prefix
String generateConversationId() {
  return 'conv_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';
}

// Generate a sequential message ID with 'msg_' prefix and zero-padding (msg_001, msg_002, etc.)
Future<String> generateSequentialMessageId(mongo.DbCollection messagesCollection, String conversationId) async {
  // Count existing messages in this conversation
  final count = await messagesCollection
      .count(mongo.where.eq('conversationId', conversationId));
  
  // Format with zero-padding (e.g., msg_001, msg_002, etc.)
  final paddedNumber = (count + 1).toString().padLeft(3, '0');
  return 'msg_$paddedNumber'; 
}

// Generate a random salt
String generateSalt([int length = 32]) {
  return List.generate(length, (index) => _chars[_rnd.nextInt(_chars.length)]).join();
}

// Hash password with salt using SHA-256
String hashPassword(String password, String salt) {
  var bytes = utf8.encode(password + salt);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

// Generate a unique user ID with 'usr_' prefix
String generateUserId() {
  return 'usr_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';
}

Response jsonResponse(Map data, {int status = 200}) =>
    Response(status, body: jsonEncode(data), headers: {'Content-Type': 'application/json'});

Middleware checkAuth() {
  return (Handler handler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return jsonResponse({"error": "Missing or invalid Authorization header"}, status: 401);
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(jwtSecret!));
        final updatedRequest = request.change(context: {'user': jwt.payload});
        return handler(updatedRequest);
      } catch (e) {
        return jsonResponse({"error": "Invalid token"}, status: 401);
      }
    };
  };
}

Future<void> main() async {

  final db = await mongo.Db.create(env['DB_URI'] ?? '');
  await db.open();
  final usersCollection = db.collection('users');
  final conversationsCollection = db.collection('conversations');
  final messagesCollection = db.collection('messages');
  print("Connected to MongoDB");

  // groq configuration
  final String groqApiKey = env['GROQ_API_KEY'] ?? '';
  final String groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  final publicRouter = Router();
  final privateRouter = Router();
  final chatRouter = Router();

  // public routes
  publicRouter.post('/register', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final name = body['name'];
    final email = body['email'];
    final password = body['password'];

    final existingUser = await usersCollection.findOne({"email": email});
    if (existingUser != null) {
      return jsonResponse({"error": "User already exists"}, status: 400);
    }

    // generate unique user ID, salt, and hash the password
    final userId = generateUserId();
    final salt = generateSalt();
    final hashedPassword = hashPassword(password, salt);

    await usersCollection.insertOne({
      "id": userId,
      "name": name,
      "email": email,
      "password": hashedPassword,
      "salt": salt,
      "created_at": DateTime.now().toIso8601String(),
    });

    return jsonResponse({
      "message": "Registration successful", 
      "userId": userId,
      "name": name,
      "email": email
    });
  });

  publicRouter.post('/login', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final email = body['email'];
    final password = body['password'];

    final user = await usersCollection.findOne({"email": email});
    if (user == null) {
      return jsonResponse({"error": "Invalid credentials"}, status: 401);
    }

    // Hash the provided password with the stored salt
    final hashedPassword = hashPassword(password, user['salt']);
    
    // Compare the hashed password with the stored hash
    if (hashedPassword != user['password']) {
      return jsonResponse({"error": "Invalid credentials"}, status: 401);
    }

    final jwt = JWT({
      "email": email,
      "userId": user['id'],
    });
    final token = jwt.sign(SecretKey(jwtSecret!), expiresIn: Duration(hours: 1));

    return jsonResponse({
        "message": "Login successful",
        "token": token,
        "email": email,
        "userId": user['id'],
    });
  });

  // protected route
  privateRouter.get('/profile', (Request req) async {
    final userData = req.context['user'] as Map<String, dynamic>;
    final email = userData['email'];

    final user = await usersCollection.findOne({"email": email});
    if (user == null) {
      return jsonResponse({"error": "User not found"}, status: 404);
    }
    
    // Remove sensitive fields
    final responseData = Map<String, dynamic>.from(user);
    responseData.addAll({'message': 'Profile gotten successfully'});
    responseData.remove('_id');
    responseData.remove('password');
    responseData.remove('salt');
    
    return jsonResponse(responseData);
  });

  final RegExp htmlTags = RegExp(r'<[^>]+>');
  final RegExp boldMarkdown = RegExp(r'\*\*(.*?)\*\*');
  final RegExp italicMarkdown = RegExp(r'\*(.*?)\*');
  final RegExp codeMarkdown = RegExp(r'`(.*?)`');
  final RegExp headersMarkdown = RegExp(r'#+ ');
  final RegExp listMarkers = RegExp(r'\n\s*[\*\-\+]\s+');
  final RegExp numberedLists = RegExp(r'\n\s*\d+\.\s+');

  // method to clean reply
  String stripMarkdownAndHtml(String text) {
    return text
      .replaceAll(htmlTags, '')
      .replaceAllMapped(boldMarkdown, (match) => match.group(1) ?? '')
      .replaceAllMapped(italicMarkdown, (match) => match.group(1) ?? '')
      .replaceAllMapped(codeMarkdown, (match) => match.group(1) ?? '')
      .replaceAll(headersMarkdown, '')
      .replaceAll(listMarkers, '\n- ')
      .replaceAll(numberedLists, '\n1. ')
      .trim();
  }

  const String systemPrompt = 
    "You are a highly knowledgeable legal assistant trained in various areas of law including "
    "contract law, constitutional law, tort law, property law, and criminal law. You only respond "
    "to questions that are clearly legal in nature. If a question is outside your legal scope—such "
    "as questions about general knowledge, personal advice, or other unrelated topics—you must "
    "respond politely that you only assist with legal questions.";

  // method to handle user request from Groq API
  Future<Map<String, dynamic>> handleGroqRequest(String userMessage) async {
    final response = await http.post(
      Uri.parse(groqApiUrl),
      headers: {
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userMessage}
        ],
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "temperature": 0.7,
        "max_tokens": 2048,
        "top_p": 1,
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      String reply = data['choices'][0]['message']['content'];

      // clean the reply for markdown, escape characters
      reply = stripMarkdownAndHtml(reply);
      
      return {
        "response": reply,
        "is_legal_response": !reply.toLowerCase().contains("only assist with legal questions")
      };
    }  else {
      return {
        "error": "Groq API error",
        "details": response.body
      };
    }
  }

  chatRouter.post('/chat', (Request request) async {
    // verify authentication first
    final authHeader = request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({"error": "Unauthorized"}, status: 401);
    }

    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final userId = userData['userId'];
      
      final body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      final String userMessage = data['message'];
      
      // Check if conversationId is provided
      String? providedConversationId = data['conversationId'];
      bool isNewConversation = false;
      bool createNewConversation = data['createNewConversation'] == true;
      
      // Initialize with a non-nullable value that will be set properly
      String conversationId;
      
      // If no conversationId is provided
      if (providedConversationId == null || providedConversationId.isEmpty) {
        // Check if user explicitly wants a new conversation
        if (createNewConversation) {
          // Create a new conversation
          conversationId = generateConversationId();
          isNewConversation = true;
        } else {
          // Try to find the most recent conversation for this user
          final query = mongo.where.eq('userId', userId);
          query.sortBy('timestamp', descending: true);
          query.limit(1);
          final recentConversation = await conversationsCollection.findOne(query);
          
          if (recentConversation != null) {
            // Use the most recent conversation
            conversationId = recentConversation['id'] as String;
          } else {
            // No existing conversations, create a new one
            conversationId = generateConversationId();
            isNewConversation = true;
          }
        }
        
        // If we need to create a new conversation
        if (isNewConversation) {
          // Create a title from the first message (limited to first 50 chars)
          String title = userMessage.length > 50 
              ? userMessage.substring(0, 47) + '...' 
              : userMessage;
          
          // Insert the new conversation
          await conversationsCollection.insertOne({
            "id": conversationId,
            "userId": userId,
            "title": title,
            "timestamp": DateTime.now().toIso8601String(),
          });
        }
      } else {
        // Use the provided conversationId
        conversationId = providedConversationId;
      }
      
      // Store the user message with sequential ID
      final userMessageId = await generateSequentialMessageId(messagesCollection, conversationId);
      final now = DateTime.now().toIso8601String();
      await messagesCollection.insertOne({
        "id": userMessageId,
        "conversationId": conversationId,
        "sender": "user",
        "content": userMessage,
        "timestamp": now,
      });
      
      // Get response from Groq
      final aiResponseData = await handleGroqRequest(userMessage);
      
      // Store the AI response if it's a valid legal response
      if (aiResponseData.containsKey('response')) {
        final aiMessageId = await generateSequentialMessageId(messagesCollection, conversationId);
        await messagesCollection.insertOne({
          "id": aiMessageId,
          "conversationId": conversationId,
          "sender": "ai",
          "content": aiResponseData['response'],
          "timestamp": DateTime.now().toIso8601String(),
        });
      }
      
      // Add conversationId to the response
      final responseWithConversationId = Map<String, dynamic>.from(aiResponseData);
      responseWithConversationId['conversationId'] = conversationId;
      
      return jsonResponse(responseWithConversationId);
    } catch (e) {
      return jsonResponse({"error": e.toString()}, status: 400);
    }
  });
  
  // Get all conversations for the authenticated user
  chatRouter.get('/history', (Request request) async {
    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final userId = userData['userId'];
      
      // Find all conversations for this user, sorted by timestamp (newest first)
      final query = mongo.where.eq('userId', userId);
      query.sortBy('timestamp', descending: true);
      final conversations = await conversationsCollection
          .find(query)
          .toList();
      
      // Format the response
      final List<Map<String, dynamic>> formattedConversations = conversations.map((conv) {
        return {
          "id": conv['id'],
          "title": conv['title'],
          "timestamp": conv['timestamp'],
        };
      }).toList();
      
      return jsonResponse({"conversations": formattedConversations});
    } catch (e) {
      return jsonResponse({"error": e.toString()}, status: 500);
    }
  });
  
  // Get all messages for a specific conversation
  chatRouter.get('/conversations/<conversationId>/messages', (Request request, String conversationId) async {
    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final userId = userData['userId'];
      
      // Verify the conversation belongs to this user
      final conversation = await conversationsCollection.findOne(
        mongo.where.eq('id', conversationId).eq('userId', userId)
      );
      
      if (conversation == null) {
        return jsonResponse({"error": "Conversation not found"}, status: 404);
      }
      
      // Parse pagination parameters
      final params = request.url.queryParameters;
      int limit = 20;
      int offset = 0;
      
      if (params.containsKey('limit')) {
        limit = int.tryParse(params['limit'] ?? '20') ?? 20;
      }
      
      if (params.containsKey('offset')) {
        offset = int.tryParse(params['offset'] ?? '0') ?? 0;
      }
      
      // Find all messages for this conversation, sorted by timestamp
      final query = mongo.where.eq('conversationId', conversationId);
      query.sortBy('timestamp', descending: false);
      final messages = await messagesCollection
          .find(query)
          .skip(offset)
          .take(limit)
          .toList();
      
      // Format the response
      final List<Map<String, dynamic>> formattedMessages = messages.map((msg) {
        return {
          "id": msg['id'],
          "sender": msg['sender'],
          "content": msg['content'],
          "timestamp": msg['timestamp'],
        };
      }).toList();
      
      return jsonResponse({
        "id": conversationId,
        "title": conversation['title'],
        "messages": formattedMessages,
      });
    } catch (e) {
      return jsonResponse({"error": e.toString()}, status: 500);
    }
  });

  // create the handler
  final handler = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsHeaders())
    .addHandler((Request request) async {
      // path matching
      if (request.url.path.startsWith('profile')) {
        final pipeline = Pipeline()
            .addMiddleware(checkAuth());
        return pipeline.addHandler(privateRouter)(request);
      }

      if (request.url.path.startsWith('chat')) {
        final pipeline = Pipeline()
            .addMiddleware(checkAuth());
        return pipeline.addHandler(chatRouter)(request);
      }
      
      // Handle conversations endpoint
      if (request.url.path.startsWith('conversations/')) {
        final pipeline = Pipeline()
            .addMiddleware(checkAuth());
        return pipeline.addHandler(chatRouter)(request);
      }
      
      // API endpoints with /api prefix
      if (request.url.path.startsWith('history')) {
        final pipeline = Pipeline()
            .addMiddleware(checkAuth());
        return pipeline.addHandler(chatRouter)(request);
      }
      
      if (request.url.path.startsWith('api/chat/conversations/')) {
        final conversationId = request.url.pathSegments[3];
        final pipeline = Pipeline()
            .addMiddleware(checkAuth());
        return pipeline.addHandler((req) async {
          return await chatRouter.call(
              req.change(path: 'conversations/$conversationId/messages'));
        })(request);
      }
      
      return publicRouter(request);
    });

  final server = await serve(handler, 'localhost', 8080);
  print('Server running at http://${server.address.host}:${server.port}');
}