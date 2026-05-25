import "dart:convert";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../data/saju_options.dart";
import "../models/saju_input.dart";
import "../models/saju_result.dart";
import "../services/api_service.dart";
import "../widgets/primary_button.dart";
import "../widgets/segmented.dart";
import "result_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final nameCtrl = TextEditingController(text: "김재영");
  final birthCtrl = TextEditingController(text: "19901227"); // YYYYMMDD

  String gender = "남";
  String calendarType = "양력";
  String birthTimeLabel = SajuOptions.birthTimeLabels.first; // 모름
  bool loading = false;
  String serverStatus = "";

  @override
  void initState() {
    super.initState();
    _loadLast();
    _ping();
  }

  Future<void> _ping() async {
    try {
      final ok = await ApiService.healthCheck();
      setState(() => serverStatus = "서버: $ok");
    } catch (_) {
      setState(() => serverStatus = "서버: 연결안됨 (localhost:3000 확인)");
    }
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    nameCtrl.text = prefs.getString("last_name") ?? nameCtrl.text;
    birthCtrl.text = prefs.getString("last_birth") ?? birthCtrl.text;
    gender = prefs.getString("last_gender") ?? gender;
    calendarType = prefs.getString("last_calendar") ?? calendarType;
    birthTimeLabel = prefs.getString("last_timeLabel") ?? birthTimeLabel;
    if (mounted) setState(() {});
  }

  Future<void> _saveLast() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_name", nameCtrl.text.trim());
    await prefs.setString("last_birth", birthCtrl.text.trim());
    await prefs.setString("last_gender", gender);
    await prefs.setString("last_calendar", calendarType);
    await prefs.setString("last_timeLabel", birthTimeLabel);
  }

  bool _validYmd(String s) {
    if (s.length != 8) return false;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || m == null || d == null) return false;
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;
    return true;
  }

  Future<void> _pickBirthDate() async {
    // YYYYMMDD 입력 도우미: 달력 선택(돈되는 앱 느낌)
    DateTime init = DateTime(1990, 12, 27);
    final raw = birthCtrl.text.trim();
    if (_validYmd(raw)) {
      init = DateTime(
        int.parse(raw.substring(0, 4)),
        int.parse(raw.substring(4, 6)),
        int.parse(raw.substring(6, 8)),
      );
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      helpText: "생년월일 선택",
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7D72FF),
            surface: Color(0xFF161524),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      birthCtrl.text = DateFormat("yyyyMMdd").format(picked);
      setState(() {});
    }
  }

  Future<void> _pickClockTime() async {
    // ✅ “시계로 누르는” 시간 선택 (요청한 그거)
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 3, minute: 0),
      helpText: "태어난 시각 선택 (모르면 취소)",
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7D72FF),
            surface: Color(0xFF161524),
          ),
        ),
        child: child!,
      ),
    );

    if (t == null) return;

    // 시계를 선택하면 12지지로 자동 매핑
    final hour = t.hour;
    String label;
    if (hour == 23 || hour == 0) label = SajuOptions.birthTimeLabels[1]; // 자
    else if (hour <= 2) label = SajuOptions.birthTimeLabels[2]; // 축
    else if (hour <= 4) label = SajuOptions.birthTimeLabels[3]; // 인
    else if (hour <= 6) label = SajuOptions.birthTimeLabels[4]; // 묘
    else if (hour <= 8) label = SajuOptions.birthTimeLabels[5]; // 진
    else if (hour <= 10) label = SajuOptions.birthTimeLabels[6]; // 사
    else if (hour <= 12) label = SajuOptions.birthTimeLabels[7]; // 오
    else if (hour <= 14) label = SajuOptions.birthTimeLabels[8]; // 미
    else if (hour <= 16) label = SajuOptions.birthTimeLabels[9]; // 신
    else if (hour <= 18) label = SajuOptions.birthTimeLabels[10]; // 유
    else if (hour <= 20) label = SajuOptions.birthTimeLabels[11]; // 술
    else label = SajuOptions.birthTimeLabels[12]; // 해

    setState(() => birthTimeLabel = label);
  }

  Future<void> _runSaju() async {
    final name = nameCtrl.text.trim();
    final birth = birthCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("이름을 입력해")));
      return;
    }
    if (!_validYmd(birth)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("생년월일은 YYYYMMDD로 입력해")));
      return;
    }

    await _saveLast();

    final input = SajuInput(
      name: name,
      birthYmd: birth,
      calendarType: calendarType,
      gender: gender,
      birthTimeLabel: birthTimeLabel,
      timeText: SajuOptions.normalizeBirthTime(birthTimeLabel),
    );

    setState(() => loading = true);
    try {
      final text = await ApiService.requestSaju(input);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            title: "AI 사주 결과",
            resultText: text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI 오류: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("history") ?? [];
    if (list.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("저장된 결과가 없습니다.")));
      }
      return;
    }

    // 최신 1개를 바로 열어줌(돈되는 앱은 “클릭 최소화”)
    final first = SajuResult.fromJson(jsonDecode(list.first));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(title: "최근 결과", resultText: first.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131222),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E2C45)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 22,
                    spreadRadius: 2,
                    color: Colors.black54,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    "소름사주",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    serverStatus,
                    style: const TextStyle(color: Color(0xFFB9B7D0)),
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel("이름"),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco("예: 김재영"),
                  ),
                  const SizedBox(height: 12),

                  _fieldLabel("생년월일 (YYYYMMDD)"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: birthCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco("예: 19901227"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _pickBirthDate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3A3750)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("달력"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _fieldLabel("성별"),
                  Segmented(
                    items: const ["남", "여"],
                    value: gender,
                    onChanged: (v) => setState(() => gender = v),
                  ),

                  const SizedBox(height: 14),
                  _fieldLabel("음/양력"),
                  Segmented(
                    items: const ["양력", "음력"],
                    value: calendarType,
                    onChanged: (v) => setState(() => calendarType = v),
                  ),

                  const SizedBox(height: 14),
                  _fieldLabel("태어난 시간 (시계로 선택 가능)"),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: birthTimeLabel,
                          items: SajuOptions.birthTimeLabels
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => birthTimeLabel = v ?? birthTimeLabel),
                          dropdownColor: const Color(0xFF161524),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco("").copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _pickClockTime,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3A3750)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("시계"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: "내 결과 보기",
                    onPressed: _runSaju,
                    loading: loading,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openHistory,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3A3750)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("최근기록 열기"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _ping,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3A3750)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("서버 재확인"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "※ 실제 출시에서는 localhost 대신 서버 도메인을 사용합니다.",
                    style: TextStyle(color: Color(0xFF6F6C8E), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            t,
            style: const TextStyle(
              color: Color(0xFFB9B7D0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6F6C8E)),
        filled: true,
        fillColor: const Color(0xFF161524),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E2C45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E2C45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7D72FF), width: 1.4),
        ),
      );

  @override
  void dispose() {
    nameCtrl.dispose();
    birthCtrl.dispose();
    super.dispose();
  }
}
