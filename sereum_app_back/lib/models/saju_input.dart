class SajuInput {
  final String name;
  final String birthYmd; // YYYYMMDD
  final String calendarType; // 양력/음력
  final String gender; // 남/여
  final String birthTimeLabel; // "인(03:00~04:59)" 같은 라벨
  final String timeText; // 서버로 보낼 축약값 ("인" / "모름")

  SajuInput({
    required this.name,
    required this.birthYmd,
    required this.calendarType,
    required this.gender,
    required this.birthTimeLabel,
    required this.timeText,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "birth": birthYmd,
        "calendarType": calendarType,
        "gender": gender,
        "timeText": timeText,
      };
}
