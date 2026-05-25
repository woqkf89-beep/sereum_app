import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class BannerBottom extends StatefulWidget {
  final Widget child;
  const BannerBottom({super.key, required this.child});

  @override
  State<BannerBottom> createState() => _BannerBottomState();
}

class _BannerBottomState extends State<BannerBottom> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();

    _ad = AdsService.instance.createBanner(
      onLoaded: () {
        if (!mounted) return;
        setState(() => _loaded = true);
      },
      onFailed: (_) {
        if (!mounted) return;
        setState(() => _loaded = false);
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        if (_loaded && _ad != null)
          SafeArea(
            top: false,
            child: SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            ),
          ),
      ],
    );
  }
}