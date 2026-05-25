import 'package:flutter/material.dart';
import '../../core/widgets/ornate.dart';
import '../../core/theme/tokens.dart' as T;
import '../../core/services/api_service.dart';

class FortuneResultPage extends StatefulWidget {
  final String title;
  final Map<String, dynamic> userInfo;
  final Map<String, dynamic>? partnerInfo;
  final Map<String, dynamic>? relationshipInfo;
  final String topic;

  const FortuneResultPage({
    Key? key,
    required this.title,
    required this.userInfo,
    this.partnerInfo,
    this.relationshipInfo,
    required this.topic,
  }) : super(key: key);

  @override
  State<FortuneResultPage> createState() => _FortuneResultPageState();
}

class _FortuneResultPageState extends State<FortuneResultPage> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  String? _fortuneText;
  bool _showFull = false;
  int _heartCost = 1;

  @override
  void initState() {
    super.initState();
    _fetchFortune();
  }

  Future<void> _fetchFortune() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Validate required info before API call
    if (widget.topic != '궁합' && widget.topic != '재회운') {
      if (widget.userInfo['name'] == null ||
          widget.userInfo['birthDate'] == null ||
          widget.userInfo['birthTime'] == null ||
          widget.userInfo['gender'] == null) {
        setState(() {
          _error = '이름, 생년월일, 태어난 시간, 성별을 먼저 입력해주세요.';
          _loading = false;
        });
        return;
      }
    } else {
      // For 궁합 and 재회운, check partner and relationship info
      if (widget.userInfo.isEmpty ||
          widget.partnerInfo == null ||
          widget.relationshipInfo == null) {
        setState(() {
          _error = '두 사람 정보를 모두 입력해주세요.';
          _loading = false;
        });
        return;
      }
    }

    try {
      final response = await _apiService.fetchAiFortuneWithDetails(
        topic: widget.topic,
        userInfo: widget.userInfo,
        partnerInfo: widget.partnerInfo,
        relationshipInfo: widget.relationshipInfo,
      );
      setState(() {
        _fortuneText = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '서버 연결 실패';
        _loading = false;
      });
    }
  }

  void _showDetails() {
    if (_showFull) return;
    // Deduct heart here, update user profile accordingly (not shown)
    setState(() {
      _showFull = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewText = _fortuneText != null && _fortuneText!.length > 300
        ? _fortuneText!.substring(0, 300) + '...'
        : _fortuneText ?? '';

    return MysticScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(widget.title, style: TextStyle(color: T.gold)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
                  : ListView(
                      children: [
                        GoldCard(
                          child: Text(
                            _showFull ? _fortuneText! : previewText,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        if (!_showFull)
                          ElevatedButton(
                            onPressed: _showDetails,
                            child: Text('자세히 보기 1하트 차감'),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}