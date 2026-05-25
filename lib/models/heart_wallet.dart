class HeartWallet {
  int hearts;

  HeartWallet({this.hearts = 0});

  factory HeartWallet.fromJson(Map<String, dynamic> json) {
    return HeartWallet(
      hearts: json['hearts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hearts': hearts,
    };
  }

  void addHearts(int count) {
    hearts += count;
  }

  bool useHearts(int count) {
    if (hearts >= count) {
      hearts -= count;
      return true;
    }
    return false;
  }
}