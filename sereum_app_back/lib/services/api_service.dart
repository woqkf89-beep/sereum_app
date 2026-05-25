import "dart:convert";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

class ApiService {
  // ✅ 기본 서버(railway). prefs에 apiBaseUrl 있으면 그걸 우선 사용
  static const String defaultBaseUrl =
      "https://considerate-optimism-production-8dda.up.railway.app";

  // ✅ 서버에서 APP_KEY로 비교할 값과 동일해야 함
  // ⚠️ 운영에서 완벽한 보안은 아니지만, 무단 호출/크롤링 대부분 차단에 도움됨.
  // 서버 ENV의 APP_KEY와 똑같이 맞춰 넣어야 함.
  static const String appKey = "k9xPq7Lz4Tn2Ym8Rw6Hd5Jc3Vs1Qa0BxZ";

  static String _base(SharedPreferences prefs) {
    final v = (prefs.getString("apiBaseUrl") ?? "").trim();
    return v.isEmpty ? defaultBaseUrl : v;
  }

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      "x-app-key": appKey,
    };
  }

  static Future<String> healthCheck(SharedPreferences prefs) async {
    final uri = Uri.parse("${_base(prefs)}/health");
    final r = await http.get(uri, headers: {"x-app-key": appKey});
    if (r.statusCode == 200) return r.body;
    throw Exception("healthCheck failed: ${r.statusCode} ${r.body}");
  }

  // ✅ 오늘의 한마디
  static Future<String> getDaily(SharedPreferences prefs) async {
    final uri = Uri.parse("${_base(prefs)}/daily");
    final r = await http.get(uri, headers: {"x-app-key": appKey});
    if (r.statusCode != 200) {
      throw Exception("daily failed: ${r.statusCode} ${r.body}");
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data["text"] ?? "").toString();
  }

  // ✅ 운세/채팅 공용
  static Future<String> postAi(
    SharedPreferences prefs,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse("${_base(prefs)}/ai-saju");

    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (r.statusCode == 401) {
      throw Exception("unauthorized (x-app-key 불일치 / 서버 APP_KEY 확인)");
    }

    if (r.statusCode != 200) {
      throw Exception("server_error: ${r.statusCode} ${r.body}");
    }

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final text = (data["text"] ?? "").toString();
    if (text.trim().isEmpty) throw Exception("AI 응답이 비었습니다.");
    return text;
  }
}