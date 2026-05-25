import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class S {
  final Locale locale;
  final Map<String, String> _t;
  S(this.locale, this._t);

  static const supported = [Locale('en'), Locale('ko')];
  static const LocalizationsDelegate<S> delegate = _SDelegate();

  static S of(BuildContext context) => Localizations.of<S>(context, S)!;

  String tr(String key) => _t[key] ?? key;

  String get brand => tr('brand');
  String get todaySignal => tr('today_signal');
  String get todayHint => tr('today_hint');
  String get readMore => tr('read_more');

  String get aiSession => tr('ai_session');
  String get aiSessionSub => tr('ai_session_sub');
  String get compatTitle => tr('compat_title');
  String get compatSub => tr('compat_sub');
  String get specialTitle => tr('special_title');
  String get specialSub => tr('special_sub');

  String get premiumTitle => tr('premium_title');
  String get premiumSub => tr('premium_sub');
  String get goPremium => tr('go_premium');

  String get offersTitle => tr('offers_title');

  String get navHome => tr('nav_home');
  String get navFortunes => tr('nav_fortunes');
  String get navChat => tr('nav_chat');
  String get navPremium => tr('nav_premium');

  String get chatTitle => tr('chat_title');
  String get chatHint => tr('chat_hint');

  String get points => tr('points');
  String get askCost => tr('ask_cost');

  String get watchAd => tr('watch_ad');
  String get buy => tr('buy');
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      S.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<S> load(Locale locale) async {
    final code = (locale.languageCode == 'ko') ? 'ko' : 'en';
    final raw = await rootBundle.loadString('assets/i18n/$code.json');
    final map = (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', '$v'));
    return S(locale, map);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<S> old) => false;
}