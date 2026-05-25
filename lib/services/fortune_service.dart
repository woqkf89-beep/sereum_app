import '../models/fortune_result.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:uuid/uuid.dart';

class FortuneService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final String _storageKey = 'fortune_results';

  Future<FortuneResult> generateFortune(String inputData) async {
    final fortuneText = await _apiService.fetchAiFortune(inputData);
    final fortune = FortuneResult(
      id: Uuid().v4(),
      date: DateTime.now(),
      inputData: inputData,
      resultText: fortuneText,
    );
    await saveFortune(fortune);
    return fortune;
  }

  Future<void> saveFortune(FortuneResult fortune) async {
    final fortunes = await getFortunes();
    fortunes.add(fortune);
    final jsonList = fortunes.map((f) => f.toJson()).toList();
    await _storageService.saveString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<FortuneResult>> getFortunes() async {
    final jsonString = await _storageService.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => FortuneResult.fromJson(json)).toList();
  }
}