import 'package:flutter/material.dart';
import '../../core/widgets/ornate.dart';
import '../../core/theme/tokens.dart' as T;
import '../../core/i18n/strings.dart';
import '../fortunes/fortune_result_page.dart';

class FortuneInputPage extends StatefulWidget {
  final String topic;
  const FortuneInputPage({Key? key, required this.topic}) : super(key: key);

  @override
  State<FortuneInputPage> createState() => _FortuneInputPageState();
}

class _FortuneInputPageState extends State<FortuneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _isLunar = false;
  final _birthTimeController = TextEditingController();
  String _gender = '남성';

  bool _loading = false;
  String? _error;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FortuneResultPage(
          title: widget.topic,
          userInfo: {
            'name': _nameController.text,
            'birthDate': _birthDateController.text,
            'isLunar': _isLunar,
            'birthTime': _birthTimeController.text,
            'gender': _gender,
          },
          topic: widget.topic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return MysticScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('${widget.topic} 입력'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: '이름'),
                  validator: (v) => v == null || v.isEmpty ? '이름을 입력하세요' : null,
                ),
                TextFormField(
                  controller: _birthDateController,
                  decoration: InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                  validator: (v) => v == null || v.isEmpty ? '생년월일을 입력하세요' : null,
                ),
                SwitchListTile(
                  title: Text('음력 사용'),
                  value: _isLunar,
                  onChanged: (v) => setState(() => _isLunar = v),
                ),
                TextFormField(
                  controller: _birthTimeController,
                  decoration: InputDecoration(labelText: '태어난 시간 (HH:mm)'),
                  validator: (v) => v == null || v.isEmpty ? '태어난 시간을 입력하세요' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: ['남성', '여성'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _gender = v ?? '남성'),
                  decoration: InputDecoration(labelText: '성별'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? CircularProgressIndicator() : Text('운세 보기 (1 하트 차감)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}