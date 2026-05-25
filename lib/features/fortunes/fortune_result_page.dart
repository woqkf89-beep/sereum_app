import 'package:flutter/material.dart';
import '../../core/widgets/ornate.dart';
import '../../core/theme/tokens.dart' as T;

class FortuneResultPage extends StatelessWidget {
  final String title;
  const FortuneResultPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    final fortuneContent = '이것은 $title 운세 결과입니다. 오늘의 운세를 참고하세요.';
    final dailySummary = '오늘은 좋은 기운이 가득합니다.';
    final luckyColor = T.gold;
    final luckyNumber = 7;
    final heartCost = 1;

    return MysticScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: T.gold)),
                IconButton(
                  icon: Icon(Icons.arrow_back, color: T.gold),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('운세 내용:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(fortuneContent, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('오늘의 총평:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(dailySummary, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('행운의 색: ', style: Theme.of(context).textTheme.titleMedium),
              Container(width: 24, height: 24, color: luckyColor),
              const SizedBox(width: 16),
              Text('행운의 숫자: $luckyNumber', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('하트 차감: $heartCost', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}