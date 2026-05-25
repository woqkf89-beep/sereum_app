import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';

const String apiBaseUrl = "https://your-railway-app-url.up.railway.app"; // Replace with your Railway URL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appProvider = AppProvider();
  await appProvider.loadUserProfile();

  runApp(
    ChangeNotifierProvider(
      create: (_) => appProvider,
      child: const SereumApp(),
    ),
  );
}