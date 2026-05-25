import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sereum_app/features/home/home_page.dart';
import 'package:sereum_app/features/fortunes/fortunes_page.dart';
import 'package:sereum_app/features/chat/chat_page.dart';
import 'package:sereum_app/features/premium/premium_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/fortunes', builder: (_, __) => const FortunesPage()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumPage()),
    ],
  );
});