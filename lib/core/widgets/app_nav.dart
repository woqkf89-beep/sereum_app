import 'package:flutter/material.dart';
import '../theme/tokens.dart' as T;

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: T.deepNavy,
      indicatorColor: T.gold.withOpacity(0.18),
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.auto_awesome), label: '운세'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
        NavigationDestination(icon: Icon(Icons.diamond_outlined), label: '상점'),
        NavigationDestination(icon: Icon(Icons.history), label: '기록'),
        NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
      ],
    );
  }
}
