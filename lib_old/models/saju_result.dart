class SajuResult {
  final String text;
  final DateTime createdAt;

  SajuResult({required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {
        "text": text,
        "createdAt": createdAt.toIso8601String(),
      };

  static SajuResult fromJson(Map<String, dynamic> json) => SajuResult(
        text: (json["text"] ?? "").toString(),
        createdAt: DateTime.tryParse((json["createdAt"] ?? "").toString()) ??
            DateTime.now(),
      );
}
