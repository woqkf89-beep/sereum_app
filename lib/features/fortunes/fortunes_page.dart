import 'package:flutter/material.dart';
import '../../core/widgets/app_nav.dart';
import '../../core/widgets/ornate.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/tokens.dart' as T;
import '../fortunes/fortune_result_page.dart';

class FortunesPage extends StatelessWidget {
  const FortunesPage({super.key});

  void _navigateToResult(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FortuneResultPage(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return StarryBackground(
      imageAsset: 'assets/ui/mock_saju.png',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: AppNavBar(currentIndex: 1, onTap: (_) {}),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(s.navFortunes),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '사주'),
                  child: const Text('사주'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '연애운'),
                  child: const Text('연애운'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '재물운'),
                  child: const Text('재물운'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '직업운'),
                  child: const Text('직업운'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '신년운세'),
                  child: const Text('신년운세'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '궁합'),
                  child: const Text('궁합'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '재회운'),
                  child: const Text('재회운'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToResult(context, '심리상담'),
                  child: const Text('심리상담'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}