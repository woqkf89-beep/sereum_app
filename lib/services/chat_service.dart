import '../models/chat_message.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final String _storageKey = 'chat_messages';

  Future<String> sendMessage(String message) async {
    return await _apiService.fetchAiChatResponse(message);
  }

  Future<void> saveMessage(ChatMessage message) async {
    final messages = await getMessages();
    messages.add(message);
    final jsonList = messages.map((m) => m.toJson()).toList();
    await _storageService.saveString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<ChatMessage>> getMessages() async {
    final jsonString = await _storageService.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }
}