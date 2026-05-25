import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.starlightGradient,
      ),
      child: Center(
        child: Text(
          '기록 및 설정 화면은 곧 추가됩니다.',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}