class SajuOptions {
  static const calendarTypes = ["양력", "음력"];

  // 태어난 시간 옵션(자시~해시 느낌) + 모름
  // (돈 되는 앱들은 “대충 선택”이 아니라 “선택지 많고 그럴듯”해야 함)
  static const birthTimeLabels = [
    "모름",
    "자(23:00~00:59)",
    "축(01:00~02:59)",
    "인(03:00~04:59)",
    "묘(05:00~06:59)",
    "진(07:00~08:59)",
    "사(09:00~10:59)",
    "오(11:00~12:59)",
    "미(13:00~14:59)",
    "신(15:00~16:59)",
    "유(17:00~18:59)",
    "술(19:00~20:59)",
    "해(21:00~22:59)",
  ];

  static String normalizeBirthTime(String label) {
    // 서버로 보낼 값 (timeText) 은 너무 길게 보내지 말고 핵심만
    // 예: "인(03:00~04:59)" -> "인"
    if (label == "모름") return "모름";
    final idx = label.indexOf("(");
    return idx > 0 ? label.substring(0, idx) : label;
  }
}
