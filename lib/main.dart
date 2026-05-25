import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'https://sereumapp-production.up.railway.app';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int tab = 0;
  int hearts = 10;

  String resultTitle = '오늘의 운세';
  String preview = '아직 운세를 보지 않았습니다.';
  String fullResult = '';
  bool detailOpen = false;
  bool loading = false;

  final name = TextEditingController();
  final birth = TextEditingController();
  final time = TextEditingController();
  final gender = TextEditingController();

  bool isLunar = false;

  final partnerName = TextEditingController();
  final partnerBirth = TextEditingController();
  final partnerTime = TextEditingController();
  final partnerGender = TextEditingController();
  bool partnerLunar = false;

  final breakupDate = TextEditingController();
  final contactStatus = TextEditingController();
  final breakupReason = TextEditingController();

  Future<void> pickDate(TextEditingController c) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      c.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> pickTime(TextEditingController c) async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 3, minute: 0),
    );
    if (t != null) {
      c.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> requestFortune(String topic) async {
    bool emptyMine = name.text.trim().isEmpty || birth.text.trim().isEmpty || time.text.trim().isEmpty || gender.text.trim().isEmpty;
    bool emptyPartner = partnerName.text.trim().isEmpty || partnerBirth.text.trim().isEmpty || partnerTime.text.trim().isEmpty || partnerGender.text.trim().isEmpty;

    if (topic == '심리상담') {
      setState(() => tab = 2);
      return;
    }

    if (['사주','연애운','재물운','직업운','신년운세'].contains(topic) && emptyMine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름, 생년월일, 태어난 시간, 성별을 모두 입력해주세요.')),
      );
      return;
    }

    if (['궁합','재회운'].contains(topic) && (emptyMine || emptyPartner)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('두 사람 정보를 모두 입력해주세요.')),
      );
      return;
    }
    if (topic == '심리상담') {
      setState(() => tab = 2);
      return;
    }

    setState(() {
      loading = true;
      resultTitle = topic;
      preview = 'AI가 $topic 분석 중입니다...';
      fullResult = '';
      detailOpen = false;
      tab = 1;
    });

    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/ai-fortune'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic,
          'userInfo': {
            'name': name.text,
            'birth': birth.text,
            'calendarType': isLunar ? '음력' : '양력',
            'time': time.text,
            'gender': gender.text,
          },
          'partnerInfo': {
            'name': partnerName.text,
            'birth': partnerBirth.text,
            'calendarType': partnerLunar ? '음력' : '양력',
            'time': partnerTime.text,
            'gender': partnerGender.text,
          },
          'relationshipInfo': {
            'breakupDate': breakupDate.text,
            'contactStatus': contactStatus.text,
            'breakupReason': breakupReason.text,
          }
        }),
      );

      final data = jsonDecode(res.body);
      final text = (data['reply'] ?? data['result'] ?? data['error'] ?? '응답 없음').toString();

      setState(() {
        fullResult = text;
        preview = text.length > 260 ? '${text.substring(0, 260)}...\n\n🔒 핵심 조언과 결론은 상세보기에서 확인하세요.' : text;
        loading = false;
      });
    } catch (e) {
      setState(() {
        preview = 'AI 서버 연결 실패';
        fullResult = 'AI 서버 연결 실패\n$e';
        loading = false;
      });
    }
  }

  void openDetail() {
    if (fullResult.isEmpty || fullResult == 'AI 서버 연결 실패') return;
    if (hearts <= 0) return;
    setState(() {
      hearts--;
      detailOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Home(
        hearts: hearts,
        name: name,
        birth: birth,
        time: time,
        gender: gender,
        isLunar: isLunar,
        setLunar: (v) => setState(() => isLunar = v),
        partnerName: partnerName,
        partnerBirth: partnerBirth,
        partnerTime: partnerTime,
        partnerGender: partnerGender,
        partnerLunar: partnerLunar,
        setPartnerLunar: (v) => setState(() => partnerLunar = v),
        breakupDate: breakupDate,
        contactStatus: contactStatus,
        breakupReason: breakupReason,
        pickDate: pickDate,
        pickTime: pickTime,
        requestFortune: requestFortune,
      ),
      Result(
        title: resultTitle,
        preview: preview,
        fullResult: fullResult,
        detailOpen: detailOpen,
        loading: loading,
        hearts: hearts,
        openDetail: openDetail,
      ),
      Chat(hearts: hearts, useHeart: () => setState(() => hearts--)),
      Store(add: (v) => setState(() => hearts += v)),
      const Records(),
      const Settings(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF07020D),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        backgroundColor: const Color(0xFF080B18),
        indicatorColor: const Color(0xFFD9A441).withOpacity(0.25),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: '운세'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: '결과'),
          NavigationDestination(icon: Icon(Icons.chat), label: '채팅'),
          NavigationDestination(icon: Icon(Icons.diamond), label: '상점'),
          NavigationDestination(icon: Icon(Icons.history), label: '기록'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class C {
  static const gold = Color(0xFFD9A441);
  static const card = Color(0xFF1A1026);
  static const muted = Color(0xFFB7A98A);
}

class Box extends StatelessWidget {
  const Box({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: C.card,
      border: Border.all(color: C.gold),
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class Home extends StatelessWidget {
  const Home({
    super.key,
    required this.hearts,
    required this.name,
    required this.birth,
    required this.time,
    required this.gender,
    required this.isLunar,
    required this.setLunar,
    required this.partnerName,
    required this.partnerBirth,
    required this.partnerTime,
    required this.partnerGender,
    required this.partnerLunar,
    required this.setPartnerLunar,
    required this.breakupDate,
    required this.contactStatus,
    required this.breakupReason,
    required this.pickDate,
    required this.pickTime,
    required this.requestFortune,
  });

  final int hearts;
  final TextEditingController name, birth, time, gender;
  final bool isLunar;
  final ValueChanged<bool> setLunar;

  final TextEditingController partnerName, partnerBirth, partnerTime, partnerGender;
  final bool partnerLunar;
  final ValueChanged<bool> setPartnerLunar;

  final TextEditingController breakupDate, contactStatus, breakupReason;

  final Future<void> Function(TextEditingController) pickDate;
  final Future<void> Function(TextEditingController) pickTime;
  final Future<void> Function(String) requestFortune;

  @override
  Widget build(BuildContext context) {
    final menus = ['사주', '연애운', '재물운', '직업운', '신년운세', '궁합', '재회운', '심리상담'];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Icon(Icons.auto_awesome, size: 90, color: C.gold),
          const Text('관령이의 소름사주', textAlign: TextAlign.center, style: TextStyle(color: C.gold, fontSize: 30, fontWeight: FontWeight.bold)),
          Text('보유 하트 $hearts', textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),

          Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('내 기본정보', style: TextStyle(color: C.gold, fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '이름')),
            TextField(controller: birth, readOnly: true, onTap: () => pickDate(birth), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '생년월일 클릭 선택')),
            Row(children: [
              ChoiceChip(label: const Text('양력'), selected: !isLunar, onSelected: (_) => setLunar(false)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('음력'), selected: isLunar, onSelected: (_) => setLunar(true)),
            ]),
            TextField(controller: time, readOnly: true, onTap: () => pickTime(time), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '태어난 시간 클릭 선택')),
            TextField(controller: gender, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '성별 예: 남자/여자')),
          ])),

          Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('상대 정보 - 궁합/재회운용', style: TextStyle(color: C.gold, fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: partnerName, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '상대 이름')),
            TextField(controller: partnerBirth, readOnly: true, onTap: () => pickDate(partnerBirth), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '상대 생년월일 클릭 선택')),
            Row(children: [
              ChoiceChip(label: const Text('상대 양력'), selected: !partnerLunar, onSelected: (_) => setPartnerLunar(false)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('상대 음력'), selected: partnerLunar, onSelected: (_) => setPartnerLunar(true)),
            ]),
            TextField(controller: partnerTime, readOnly: true, onTap: () => pickTime(partnerTime), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '상대 태어난 시간 클릭 선택')),
            TextField(controller: partnerGender, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '상대 성별')),
            TextField(controller: breakupDate, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '헤어진 시기')),
            TextField(controller: contactStatus, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '현재 연락 여부')),
            TextField(controller: breakupReason, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '이별 이유')),
          ])),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: menus.map((m) => ActionChip(label: Text(m), onPressed: () => requestFortune(m))).toList(),
          ),
          const Box(child: Center(child: Text('AdMob Banner Area', style: TextStyle(color: C.muted)))),
        ],
      ),
    );
  }
}

class Result extends StatelessWidget {
  const Result({
    super.key,
    required this.title,
    required this.preview,
    required this.fullResult,
    required this.detailOpen,
    required this.loading,
    required this.hearts,
    required this.openDetail,
  });

  final String title, preview, fullResult;
  final bool detailOpen, loading;
  final int hearts;
  final VoidCallback openDetail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(children: [
      Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI $title 결과', style: const TextStyle(color: C.gold, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (loading) const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Text(detailOpen ? fullResult : preview, style: const TextStyle(color: Colors.white, height: 1.5)),
        const SizedBox(height: 16),
        Text('보유 하트 $hearts', style: const TextStyle(color: C.muted)),
        ElevatedButton(
          onPressed: detailOpen || loading ? null : openDetail,
          child: Text(detailOpen ? '상세풀이 열림' : '자세히 보기 1하트'),
        ),
      ])),
    ]));
  }
}

class Chat extends StatefulWidget {
  const Chat({super.key, required this.hearts, required this.useHeart});
  final int hearts;
  final VoidCallback useHeart;
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final c = TextEditingController();
  final messages = <String>['AI: 어떤 고민을 상담해드릴까요? 연애, 이별, 가족, 직장, 불안, 인간관계 중 편하게 말해주세요.'];
  bool loading = false;

  Future<void> send() async {
    final text = c.text.trim();
    if (text.isEmpty || loading) return;
    c.clear();
    setState(() { messages.add('나: $text'); loading = true; });

    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/ai-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      final data = jsonDecode(res.body);
      setState(() {
        messages.add('AI: ${data['reply'] ?? data['error'] ?? '응답 없음'}');
        loading = false;
      });
      widget.useHeart();
    } catch (_) {
      setState(() {
        messages.add('AI: 서버 연결 실패');
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
    Box(child: Row(children: [
      const Text('AI 상담 채팅', style: TextStyle(color: C.gold, fontSize: 22, fontWeight: FontWeight.bold)),
      const Spacer(),
      Text('하트 ${widget.hearts}', style: const TextStyle(color: C.muted)),
    ])),
    Expanded(child: ListView(children: messages.map((m) => Box(child: Text(m, style: const TextStyle(color: Colors.white)))).toList())),
    if (loading) const LinearProgressIndicator(),
    Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Expanded(child: TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: '질문 입력'))),
      IconButton(onPressed: send, icon: const Icon(Icons.send, color: C.gold)),
    ])),
  ]));
}

class Store extends StatelessWidget {
  const Store({super.key, required this.add});
  final void Function(int) add;
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(children: [
    const Box(child: Text('상점', style: TextStyle(color: C.gold, fontSize: 26, fontWeight: FontWeight.bold))),
    Box(child: ElevatedButton(onPressed: () => add(10), child: const Text('하트 10개 mock 구매'))),
    Box(child: ElevatedButton(onPressed: () => add(30), child: const Text('하트 30개 mock 구매'))),
  ]));
}

class Records extends StatelessWidget {
  const Records({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(child: Box(child: Text('기록', style: TextStyle(color: Colors.white))));
}

class Settings extends StatelessWidget {
  const Settings({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(child: Box(child: Text('Railway AI 서버 연결 완료', style: TextStyle(color: Colors.white))));
}

