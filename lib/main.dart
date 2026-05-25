import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'https://sereumapp-production.up.railway.app';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const App());
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
  bool loading = false;
  bool detailOpen = false;
  String title = '사주';
  String preview = '운세를 선택해주세요.';
  String full = '';

  final name = TextEditingController();
  final birth = TextEditingController();
  final time = TextEditingController();
  String gender = '남자';
  bool lunar = false;

  final pName = TextEditingController();
  final pBirth = TextEditingController();
  final pTime = TextEditingController();
  String pGender = '여자';
  bool pLunar = false;

  final breakupDate = TextEditingController();
  final contactStatus = TextEditingController();
  final breakupReason = TextEditingController();

  bool get mineEmpty => name.text.trim().isEmpty || birth.text.trim().isEmpty || time.text.trim().isEmpty || gender.trim().isEmpty;
  bool get partnerEmpty => pName.text.trim().isEmpty || pBirth.text.trim().isEmpty || pTime.text.trim().isEmpty || pGender.trim().isEmpty;

  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> pickDate(TextEditingController c) async {
    final d = await showDatePicker(context: context, initialDate: DateTime(1990, 1, 1), firstDate: DateTime(1900), lastDate: DateTime.now());
    if (d != null) c.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> pickTime(TextEditingController c) async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 3, minute: 0));
    if (t != null) c.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> fortune(String topic) async {
    if (topic == '심리상담') {
      setState(() => tab = 2);
      return;
    }

    if (['사주', '연애운', '재물운', '직업운', '신년운세'].contains(topic) && mineEmpty) {
      msg('이름, 생년월일, 태어난 시간, 성별을 모두 입력해주세요.');
      return;
    }

    if (['궁합', '재회운'].contains(topic) && (mineEmpty || partnerEmpty)) {
      msg('두 사람 정보를 모두 입력해주세요.');
      return;
    }

    setState(() {
      tab = 1;
      title = topic;
      loading = true;
      detailOpen = false;
      preview = 'AI가 $topic 분석 중입니다...';
      full = '';
    });

    try {
      final r = await http.post(
        Uri.parse('$apiBaseUrl/ai-fortune'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic,
          'userInfo': {
            'name': name.text.trim(),
            'birth': birth.text.trim(),
            'calendarType': lunar ? '음력' : '양력',
            'time': time.text.trim(),
            'gender': gender,
          },
          'partnerInfo': {
            'name': pName.text.trim(),
            'birth': pBirth.text.trim(),
            'calendarType': pLunar ? '음력' : '양력',
            'time': pTime.text.trim(),
            'gender': pGender,
          },
          'relationshipInfo': {
            'breakupDate': breakupDate.text.trim(),
            'contactStatus': contactStatus.text.trim(),
            'breakupReason': breakupReason.text.trim(),
          }
        }),
      );

      final data = jsonDecode(r.body);
      final text = (data['reply'] ?? data['error'] ?? '응답 없음').toString();
      final cut = text.length > 450 ? 450 : text.length;

      setState(() {
        full = text;
        preview = '${text.substring(0, cut)}\n\n🔒 핵심 결론과 상세 조언은 자세히 보기에서 확인하세요.';
        loading = false;
      });
    } catch (e) {
      setState(() {
        preview = 'AI 서버 연결 실패';
        full = '$e';
        loading = false;
      });
    }
  }

  void detail() {
    if (full.isEmpty || loading) return;
    if (hearts <= 0) {
      msg('하트가 부족합니다.');
      return;
    }
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
        lunar: lunar,
        pName: pName,
        pBirth: pBirth,
        pTime: pTime,
        pGender: pGender,
        pLunar: pLunar,
        breakupDate: breakupDate,
        contactStatus: contactStatus,
        breakupReason: breakupReason,
        setGender: (v) => setState(() => gender = v),
        setLunar: (v) => setState(() => lunar = v),
        setPGender: (v) => setState(() => pGender = v),
        setPLunar: (v) => setState(() => pLunar = v),
        pickDate: pickDate,
        pickTime: pickTime,
        fortune: fortune,
      ),
      Result(title: title, preview: preview, full: full, loading: loading, detailOpen: detailOpen, hearts: hearts, detail: detail),
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
    decoration: BoxDecoration(color: C.card, border: Border.all(color: C.gold), borderRadius: BorderRadius.circular(24)),
    child: child,
  );
}

class Home extends StatelessWidget {
  const Home({
    super.key, required this.hearts, required this.name, required this.birth, required this.time,
    required this.gender, required this.lunar, required this.pName, required this.pBirth,
    required this.pTime, required this.pGender, required this.pLunar, required this.breakupDate,
    required this.contactStatus, required this.breakupReason, required this.setGender,
    required this.setLunar, required this.setPGender, required this.setPLunar,
    required this.pickDate, required this.pickTime, required this.fortune,
  });

  final int hearts;
  final TextEditingController name, birth, time, pName, pBirth, pTime, breakupDate, contactStatus, breakupReason;
  final String gender, pGender;
  final bool lunar, pLunar;
  final ValueChanged<String> setGender, setPGender;
  final ValueChanged<bool> setLunar, setPLunar;
  final Future<void> Function(TextEditingController) pickDate, pickTime;
  final Future<void> Function(String) fortune;

  Widget field(String label, TextEditingController c, {VoidCallback? tap}) => TextField(
    controller: c,
    readOnly: tap != null,
    onTap: tap,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: C.muted)),
  );

  Widget genderBox(String value, ValueChanged<String> set) => DropdownButton<String>(
    value: value,
    dropdownColor: C.card,
    items: const [
      DropdownMenuItem(value: '남자', child: Text('남자')),
      DropdownMenuItem(value: '여자', child: Text('여자')),
    ],
    onChanged: (v) => set(v!),
  );

  @override
  Widget build(BuildContext context) {
    final menus = ['사주', '연애운', '재물운', '직업운', '신년운세', '궁합', '재회운', '심리상담'];
    return SafeArea(child: ListView(padding: const EdgeInsets.all(14), children: [
      const Icon(Icons.auto_awesome, size: 90, color: C.gold),
      const Text('관령이의 소름사주', textAlign: TextAlign.center, style: TextStyle(color: C.gold, fontSize: 30, fontWeight: FontWeight.bold)),
      Text('보유 하트 $hearts', textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
      Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('내 기본정보', style: TextStyle(color: C.gold, fontSize: 20, fontWeight: FontWeight.bold)),
        field('이름', name),
        field('생년월일 클릭 선택', birth, tap: () => pickDate(birth)),
        Row(children: [
          ChoiceChip(label: const Text('양력'), selected: !lunar, onSelected: (_) => setLunar(false)),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('음력'), selected: lunar, onSelected: (_) => setLunar(true)),
        ]),
        field('태어난 시간 클릭 선택', time, tap: () => pickTime(time)),
        const SizedBox(height: 8),
        Row(children: [const Text('성별: ', style: TextStyle(color: C.muted)), genderBox(gender, setGender)]),
      ])),
      Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('상대 정보 - 궁합/재회운용', style: TextStyle(color: C.gold, fontSize: 20, fontWeight: FontWeight.bold)),
        field('상대 이름', pName),
        field('상대 생년월일 클릭 선택', pBirth, tap: () => pickDate(pBirth)),
        Row(children: [
          ChoiceChip(label: const Text('상대 양력'), selected: !pLunar, onSelected: (_) => setPLunar(false)),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('상대 음력'), selected: pLunar, onSelected: (_) => setPLunar(true)),
        ]),
        field('상대 태어난 시간 클릭 선택', pTime, tap: () => pickTime(pTime)),
        Row(children: [const Text('상대 성별: ', style: TextStyle(color: C.muted)), genderBox(pGender, setPGender)]),
        field('헤어진 시기', breakupDate),
        field('현재 연락 여부', contactStatus),
        field('이별 이유', breakupReason),
      ])),
      Wrap(spacing: 10, runSpacing: 10, children: menus.map((m) => ActionChip(label: Text(m), onPressed: () => fortune(m))).toList()),
      const Box(child: Center(child: Text('AdMob Banner Area', style: TextStyle(color: C.muted)))),
    ]));
  }
}

class Result extends StatelessWidget {
  const Result({super.key, required this.title, required this.preview, required this.full, required this.loading, required this.detailOpen, required this.hearts, required this.detail});
  final String title, preview, full;
  final bool loading, detailOpen;
  final int hearts;
  final VoidCallback detail;

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(children: [
    Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('AI $title 결과', style: const TextStyle(color: C.gold, fontSize: 26, fontWeight: FontWeight.bold)),
      if (loading) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LinearProgressIndicator()),
      Text(detailOpen ? full : preview, style: const TextStyle(color: Colors.white, height: 1.55)),
      const SizedBox(height: 14),
      Text('보유 하트 $hearts', style: const TextStyle(color: C.muted)),
      ElevatedButton(onPressed: detailOpen || loading ? null : detail, child: Text(detailOpen ? '상세풀이 열림' : '자세히 보기 1하트')),
    ])),
  ]));
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
      final r = await http.post(Uri.parse('$apiBaseUrl/ai-chat'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'message': text}));
      final d = jsonDecode(r.body);
      setState(() { messages.add('AI: ${d['reply'] ?? d['error'] ?? '응답 없음'}'); loading = false; });
      widget.useHeart();
    } catch (_) {
      setState(() { messages.add('AI: 서버 연결 실패'); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
    Box(child: Row(children: [const Text('AI 상담 채팅', style: TextStyle(color: C.gold, fontSize: 22, fontWeight: FontWeight.bold)), const Spacer(), Text('하트 ${widget.hearts}', style: const TextStyle(color: C.muted))])),
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
