class UserProfile {
  final String id;
  final String name;
  final bool isPremium;
  int hearts;
  DateTime lastChatDate;
  int dailyChatCount;

  UserProfile({
    required this.id,
    required this.name,
    this.isPremium = false,
    this.hearts = 0,
    DateTime? lastChatDate,
    this.dailyChatCount = 0,
  }) : lastChatDate = lastChatDate ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      isPremium: json['isPremium'] ?? false,
      hearts: json['hearts'] ?? 0,
      lastChatDate: json['lastChatDate'] != null
          ? DateTime.parse(json['lastChatDate'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      dailyChatCount: json['dailyChatCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPremium': isPremium,
      'hearts': hearts,
      'lastChatDate': lastChatDate.toIso8601String(),
      'dailyChatCount': dailyChatCount,
    };
  }
}