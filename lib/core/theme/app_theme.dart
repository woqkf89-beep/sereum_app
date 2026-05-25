import 'package:flutter/material.dart';
import 'tokens.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: gold,
  scaffoldBackgroundColor: bg,
  fontFamily: 'NotoSansKR',
  colorScheme: ColorScheme.dark(
    primary: gold,
    secondary: darkPurple,
    background: bg,
    surface: deepNavy,
    onPrimary: Colors.black,
    onSecondary: gold,
    onBackground: gold,
    onSurface: gold,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: deepNavy,
    elevation: 0,
    iconTheme: IconThemeData(color: gold),
    titleTextStyle: TextStyle(
      color: gold,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  tabBarTheme: TabBarTheme(
    labelColor: gold,
    unselectedLabelColor: darkPurple,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: gold, width: 2),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      color: gold,
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
    titleLarge: TextStyle(
      color: gold,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    bodyLarge: TextStyle(
      color: gold,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: muted,
      fontSize: 14,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: gold,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: gold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
);