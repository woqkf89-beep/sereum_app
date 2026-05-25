import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/tokens.dart' as T;
import '../../core/widgets/app_nav.dart';
import '../../core/widgets/ornate.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _Msg {
  const _Msg(this.me, this.text);
  final bool me;
  final String text;
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _c = TextEditingController();
  int points = 10;

  final List<_Msg> _msgs = const [
    _Msg(false, '안녕하세요. 관령이입니다. 궁금한 운세를 물어보세요.'),
  ].toList();

  Future<void> send() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;

    if (points <= 0) {
      setState(() => _msgs.add(_Msg(false, '포인트가 부족해. 프리미엄에서 충전해.')));
      return;
    }

    setState(() {
      points -= 1;
      _msgs.add(_Msg(true, text));
    });

    _c.clear();

    try {
      final response = await _sendChatMessage(text);
      setState(() {
        _msgs.add(_Msg(false, response));
      });
    } catch (e) {
      setState(() {
        _msgs.add(_Msg(false, '서버 연결 실패'));
      });
    }
  }

  Future<String> _sendChatMessage(String message) async {
    const apiBaseUrl = 'https://your-railway-app-url.up.railway.app'; // Replace with your Railway URL
    final url = Uri.parse('\$apiBaseUrl/ai-chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? '응답이 없습니다.';
    } else {
      throw Exception('Failed to send chat message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      bottomNavigationBar: AppNavBar(currentIndex: 2, onTap: (_) {}),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GoldCard(
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: T.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI 사주 상담',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text('하트 \$points', style: const TextStyle(color: T.gold)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  return Align(
                    alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: m.me ? T.gold.withOpacity(0.18) : T.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: T.stroke),
                      ),
                      child: Text(m.text, style: const TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '질문을 입력하세요',
                      hintStyle: const TextStyle(color: T.muted),
                      filled: true,
                      fillColor: T.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onSubmitted: (_) => send(),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send_rounded, color: T.gold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}