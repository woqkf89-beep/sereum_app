import 'package:flutter/material.dart';
import '../theme/tokens.dart' as T;

class MysticScaffold extends StatelessWidget {
  const MysticScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
  });

  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [T.bg2, T.bg],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class GoldCard extends StatelessWidget {
  const GoldCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.card.withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: T.stroke),
        boxShadow: [
          BoxShadow(
            color: T.gold.withOpacity(0.10),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.auto_awesome, color: Colors.black),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: T.gold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}
