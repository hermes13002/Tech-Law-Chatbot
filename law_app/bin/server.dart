import 'package:law_app/server/server.dart';

/// Main entry point for the server
void main() async {
  // Create and start the server
  final server = Server();
  await server.start();
}