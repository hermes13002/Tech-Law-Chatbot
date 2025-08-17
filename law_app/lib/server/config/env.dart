import 'package:dotenv/dotenv.dart' as dotenv;

/// Environment configuration class for the server
class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();
  late final dotenv.DotEnv env;
  
  // Singleton pattern
  factory EnvConfig() {
    return _instance;
  }
  
  EnvConfig._internal() {
    env = dotenv.DotEnv();
    // Load environment variables from .env file
    try {
      env.load();
      print('Environment variables loaded from .env file');
    } catch (e) {
      print('No .env file found, using environment variables or defaults');
    }
  }
  
  /// Get JWT secret key
  String get jwtSecret => env['JWT_SECRET'] ?? 'excelsiorJWTSecretKey';
  
  /// Get MongoDB connection URI
  String get dbUri => env['DB_URI'] ?? 
      "mongodb+srv://soaresayoigbala:Excelsior13\$@techlawcluster1.4oil6yw.mongodb.net/?retryWrites=true&w=majority&tls=true";
  
  /// Get Groq API key
  String get groqApiKey => env['GROQ_API_KEY'] ?? 
      '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';
  
  /// Get Groq API URL
  String get groqApiUrl => 'https://api.groq.com/openai/v1/chat/completions';
}