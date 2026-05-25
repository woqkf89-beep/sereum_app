import "dart:convert";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../models/saju_result.dart";
import "../widgets/primary_button.dart";

class ResultScreen extends StatelessWidget {
  final String title;
  final String resultText;

  const ResultScreen({super.key, required this.title, required this.resultText});

  Future<void> _saveResult(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("history") ?? [];

    final item = SajuResult(text: resultText, createdAt: DateTime.now());
    list.insert(0, jsonEncode(item.toJson()));

    // 최근 20개만
    final trimmed = list.take(20).toList();
    await prefs.setStringList("history", trimmed);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("저장 완료 (최근기록에 추가됨)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161524),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E2C45)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    resultText,
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: "결과 저장",
                      onPressed: () => _saveResult(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      text: "닫기",
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
