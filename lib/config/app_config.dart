class AppConfig {
  static const String appName = "관령이의 소름사주";
  static const String apiBaseUrl = "https://your-railway-app-url.up.railway.app"; // Replace with your Railway deployment URL

  // Ad config
  static const String bannerAdUnitId = "ca-app-pub-xxxxxxxxxxxxxxxx/banner";
  static const String interstitialAdUnitId = "ca-app-pub-xxxxxxxxxxxxxxxx/interstitial";
  static const String rewardedAdUnitId = "ca-app-pub-xxxxxxxxxxxxxxxx/rewarded";

  // In-app purchase product IDs
  static const String productHearts10 = "hearts_10";
  static const String productHearts20 = "hearts_20";
  static const String productHearts30 = "hearts_30";
  static const String productPremiumMonthly = "premium_monthly";

  // Other config
  static const int initialHearts = 10;
  static const int dailyFreeChatLimit = 1;
}