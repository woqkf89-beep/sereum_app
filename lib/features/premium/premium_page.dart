import 'package:flutter/material.dart';

import '../../core/widgets/app_nav.dart';
import '../../core/widgets/ornate.dart';
import '../../core/theme/tokens.dart' as T;
import 'package:sereum_app/core/i18n/strings.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return StarryBackground(
      imageAsset: 'assets/ui/mock_set4.png',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: AppNavBar(currentIndex: 3, onTap: (_) {}),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(s.navPremium),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [
            OrnateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('포인트 충전', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('AI 상담 / 특수 운세 / 궁합에 사용', style: TextStyle(color: T.muted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _BuyChip(price: '₩ 3,900', sub: '100', onTap: () => _toast(context, '${s.buy}: 100')),
                      _BuyChip(price: '₩ 7,900', sub: '250', onTap: () => _toast(context, '${s.buy}: 250')),
                      _BuyChip(price: '₩ 14,900', sub: '600', onTap: () => _toast(context, '${s.buy}: 600')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(s.watchAd, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  GoldButton(text: s.watchAd, onTap: () => _toast(context, '광고 보상(UI)')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _BuyChip extends StatelessWidget {
  final String price;
  final String sub;
  final VoidCallback onTap;
  const _BuyChip({required this.price, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: OrnateCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('포인트 $sub', style: TextStyle(color: T.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}