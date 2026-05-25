import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'features/home/home_page.dart';
import 'features/fortunes/fortunes_page.dart';
import 'features/chat/chat_page.dart';
import 'features/premium/premium_page.dart';
import 'core/widgets/app_nav.dart';

class SereumApp extends StatelessWidget {
  const SereumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: '관령이의 소름사주',
      theme: appTheme,
      home: MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pages = [
      const FortunesPage(),
      const ChatPage(),
      const PremiumPage(),
      const HomePage(), // Records placeholder
      const HomePage(), // Settings placeholder
    ];
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _pages,
        physics: const NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}