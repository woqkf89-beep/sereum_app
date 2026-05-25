import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _inited = false;

  // TODO: 아래 3개를 "네 AdMob 유닛ID"로 바꿔야 함 (배너/전면/보상형)
  // 예: ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx
  static const String bannerUnitId = 'PUT_YOUR_BANNER_UNIT_ID';
  static const String interstitialUnitId = 'PUT_YOUR_INTERSTITIAL_UNIT_ID';
  static const String rewardedUnitId = 'PUT_YOUR_REWARDED_UNIT_ID';

  Future<void> init() async {
    if (_inited) return;
    if (!Platform.isAndroid) return;
    await MobileAds.instance.initialize();
    _inited = true;
  }

  BannerAd createBanner({
    required void Function() onLoaded,
    required void Function(LoadAdError error) onFailed,
  }) {
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );
    ad.load();
    return ad;
  }

  Future<InterstitialAd?> loadInterstitial() async {
    InterstitialAd? result;
    await InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => result = ad,
        onAdFailedToLoad: (_) => result = null,
      ),
    );
    return result;
  }

  Future<RewardedAd?> loadRewarded() async {
    RewardedAd? result;
    await RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => result = ad,
        onAdFailedToLoad: (_) => result = null,
      ),
    );
    return result;
  }
}