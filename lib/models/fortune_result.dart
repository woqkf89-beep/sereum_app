class FortuneResult {
  final String id;
  final DateTime date;
  final String inputData;
  final String resultText;

  FortuneResult({
    required this.id,
    required this.date,
    required this.inputData,
    required this.resultText,
  });

  factory FortuneResult.fromJson(Map<String, dynamic> json) {
    return FortuneResult(
      id: json['id'],
      date: DateTime.parse(json['date']),
      inputData: json['inputData'],
      resultText: json['resultText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'inputData': inputData,
      'resultText': resultText,
    };
  }
}