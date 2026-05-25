import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('\$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> fetchAiFortune(String inputData) async {
    try {
      final response = await http.post(
        Uri.parse('\$baseUrl/ai-fortune'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'inputData': inputData}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fortune'] ?? '';
      } else {
        throw Exception('Failed to fetch fortune');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> sendChatMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('\$baseUrl/ai-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? '';
      } else {
        throw Exception('Failed to send chat message');
      }
    } catch (e) {
      rethrow;
    }
  }
}