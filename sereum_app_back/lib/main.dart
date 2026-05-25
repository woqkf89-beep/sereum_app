import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ads
import 'package:google_mobile_ads/google_mobile_ads.dart';

// IAP
import 'package:in_app_purchase/in_app_purchase.dart';

// ✅ API 서비스(별도 파일)
import 'services/api_service.dart';

// =====================
// ✅ AdMob IDs (실제 유닛)
// =====================
const String kBannerAdUnitIdAndroid = 'ca-app-pub-6908844178365643/4688262300';
const String kInterstitialAdUnitIdAndroid = 'ca-app-pub-6908844178365643/6847521783';

// =====================
// ✅ IAP 상품 ID (Play Console 상품 ID와 "완전 동일" 해야 함)
// =====================
// 아래 ID는 예시야. Play Console에서 같은 이름으로 만들거나,
// 너가 이미 만든 ID로 여기 값을 바꿔줘.
const String kIapHearts10 = 'hearts_10';
const String kIapHearts20 = 'hearts_20';
const String kIapHearts30 = 'hearts_30';
const String kSubMonthly = 'sub_monthly';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // ✅ 기본 서버 주소(설정에서 바꿀 수 있음)
  prefs.setStringIfNull('apiBaseUrl', ApiService.defaultBaseUrl);
  prefs.setIntIfNull('hearts', 10); // 첫 유저 맛보기 하트
  prefs.setBoolIfNull('isSubscriber', false);

  // ✅ 광고 초기화는 "모바일에서만"
  if (PluginGate.isMobile) {
    try {
      await MobileAds.instance.initialize();
      await InterstitialAdManager.instance.preload(); // 전면광고 미리 로드
    } catch (_) {}
  }

  // ✅ 결제(IAP) 초기화 (모바일에서만)
  if (PluginGate.isMobile) {
    try {
      await IapManager.instance.init(prefs);
    } catch (_) {}
  }

  runApp(SereumApp(prefs: prefs));
}

// ===================== 광고 매니저 =====================

class InterstitialAdManager {
  InterstitialAdManager._();
  static final instance = InterstitialAdManager._();

  InterstitialAd? _ad;
  bool _loading = false;
  DateTime? _lastShown;

  Future<void> preload() async {
    if (!PluginGate.isMobile) return;
    if (_loading || _ad != null) return;

    _loading = true;
    try {
      await InterstitialAd.load(
        adUnitId: kInterstitialAdUnitIdAndroid,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
          },
          onAdFailedToLoad: (_) {
            _ad = null;
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  Future<void> show({required bool disabled}) async {
    if (disabled) return;
    if (!PluginGate.isMobile) return;

    // 60초 쿨다운
    final now = DateTime.now();
    if (_lastShown != null && now.difference(_lastShown!).inSeconds < 60) return;

    if (_ad == null) {
      await preload();
      return;
    }

    final ad = _ad!;
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        preload();
      },
    );

    ad.show();
  }
}

class BannerBar extends StatefulWidget {
  final bool hidden; // 구독이면 숨김
  const BannerBar({super.key, required this.hidden});

  @override
  State<BannerBar> createState() => _BannerBarState();
}

class _BannerBarState extends State<BannerBar> {
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!PluginGate.isMobile) return;
    if (widget.hidden) return;

    BannerAd? tmp;

    tmp = BannerAd(
      adUnitId: kBannerAdUnitIdAndroid,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _banner = tmp;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            if (_banner == ad) _banner = null;
          });
        },
      ),
    );

    await tmp.load();
  }

  @override
  void didUpdateWidget(covariant BannerBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.hidden && !widget.hidden && _banner == null) {
      _init();
    }
    if (!oldWidget.hidden && widget.hidden) {
      _banner?.dispose();
      _banner = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PluginGate.isMobile) return const SizedBox.shrink();
    if (widget.hidden) return const SizedBox.shrink();
    if (_banner == null) return const SizedBox(height: 0);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: _banner!.size.height.toDouble(),
        width: double.infinity,
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}

// ===================== IAP 매니저 (찐결제) =====================

class IapManager {
  IapManager._();
  static final instance = IapManager._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loadingProducts = false;
  String? lastError;

  final Map<String, ProductDetails> products = {};

  // “하트 상품”은 소모성(consumable)으로 가정
  final Map<String, int> heartPack = const {
    kIapHearts10: 10,
    kIapHearts20: 20,
    kIapHearts30: 30,
  };

  Set<String> get _productIds => {
        ...heartPack.keys,
        kSubMonthly,
      };

  Future<void> init(SharedPreferences prefs) async {
    if (!PluginGate.isMobile) return;

    available = await _iap.isAvailable();
    if (!available) {
      lastError = 'Google Play 결제 사용 불가';
      return;
    }

    // 구매 스트림 (1번만)
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.error) {
            lastError = p.error?.message ?? '결제 오류';
            continue;
          }

          if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
            // ✅ 지급/처리
            await _deliver(prefs, p);

            // ✅ completePurchase 필수 (안 하면 환불/중복 꼬임)
            if (p.pendingCompletePurchase) {
              await _iap.completePurchase(p);
            }
          }
        }
      },
      onError: (e) {
        lastError = '$e';
      },
    );

    await queryProducts();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> queryProducts() async {
    if (!PluginGate.isMobile) return;
    if (!available) return;

    loadingProducts = true;
    lastError = null;

    try {
      final resp = await _iap.queryProductDetails(_productIds);

      if (resp.error != null) {
        lastError = '상품 조회 실패: ${resp.error}';
        return;
      }

      products.clear();
      for (final p in resp.productDetails) {
        products[p.id] = p;
      }

      if (resp.notFoundIDs.isNotEmpty) {
        // 상품ID가 Play Console과 다르면 여기로 걸림
        lastError = '상품ID를 Play Console과 동일하게 맞춰야 함: ${resp.notFoundIDs.join(", ")}';
      }
    } catch (e) {
      lastError = '상품 조회 예외: $e';
    } finally {
      loadingProducts = false;
    }
  }

  Future<void> buyConsumable(String productId) async {
    final pd = products[productId];
    if (pd == null) throw Exception('상품 없음: $productId');
    final param = PurchaseParam(productDetails: pd);
    await _iap.buyConsumable(purchaseParam: param);
  }

  Future<void> buySubscription(String productId) async {
    final pd = products[productId];
    if (pd == null) throw Exception('상품 없음: $productId');
    final param = PurchaseParam(productDetails: pd);
    // 구독은 non-consumable로 purchase flow 진입
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> _deliver(SharedPreferences prefs, PurchaseDetails p) async {
    final id = p.productID;

    // ⚠️ 출시 강화 포인트:
    // 여기서 서버 영수증 검증을 붙이는 게 정석(부정결제 방지).
    // 지금은 빠른 출시를 위해 1차는 로컬 지급으로 간다.

    if (heartPack.containsKey(id)) {
      final add = heartPack[id]!;
      final cur = prefs.getInt('hearts') ?? 0;
      await prefs.setInt('hearts', cur + add);
      return;
    }

    if (id == kSubMonthly) {
      await prefs.setBool('isSubscriber', true);
      return;
    }
  }
}

// ===================== 플랫폼 게이트 =====================

class PluginGate {
  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}

// ===================== APP =====================

class SereumApp extends StatelessWidget {
  final SharedPreferences prefs;
  const SereumApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '관령이의 소름사주',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C4DFF),
        scaffoldBackgroundColor: const Color(0xFF0B0B10),
      ),
      home: MainShell(prefs: prefs),
    );
  }
}

class MainShell extends StatefulWidget {
  final SharedPreferences prefs;
  const MainShell({super.key, required this.prefs});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  void openStore() => setState(() => index = 2);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(prefs: widget.prefs, onOpenStore: openStore),
      ChatScreen(prefs: widget.prefs, onOpenStore: openStore),
      StoreScreen(prefs: widget.prefs, onBackHome: () => setState(() => index = 0)),
      HistoryScreen(prefs: widget.prefs),
      SettingsScreen(prefs: widget.prefs),
    ];

    final isSub = widget.prefs.getBool('isSubscriber') ?? false;

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerBar(hidden: isSub),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: '운세'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
              NavigationDestination(icon: Icon(Icons.storefront_outlined), label: '상점'),
              NavigationDestination(icon: Icon(Icons.history), label: '기록'),
              NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
            ],
          ),
        ],
      ),
    );
  }
}

/* -----------------------------
   HOME
------------------------------ */
class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onOpenStore;
  const HomeScreen({super.key, required this.prefs, required this.onOpenStore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String dailyText = '오늘의 관령이 한마디를 불러오는 중…';
  bool loadingDaily = false;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily({bool force = false}) async {
    final todayKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final cacheKey = 'daily_$todayKey';

    if (!force) {
      final cached = widget.prefs.getString(cacheKey);
      if (cached != null && cached.trim().isNotEmpty) {
        setState(() => dailyText = cached);
        return;
      }
    }

    setState(() => loadingDaily = true);
    try {
      final d = await ApiService.getDaily(widget.prefs);
      await widget.prefs.setString(cacheKey, d);
      setState(() => dailyText = d);
    } catch (e) {
      setState(() => dailyText = '오늘은 기운이 좀 꼬였네… 😵\n서버 상태를 확인해줘.\n($e)');
    } finally {
      setState(() => loadingDaily = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hearts = widget.prefs.getInt('hearts') ?? 0;
    final isSubscriber = widget.prefs.getBool('isSubscriber') ?? false;

    final items = <FeatureItem>[
      FeatureItem(type: 'saju', title: '사주', icon: Icons.temple_buddhist),
      FeatureItem(type: 'solo', title: '솔로탈출', icon: Icons.favorite_border),
      FeatureItem(type: 'couple', title: '커플(궁합)', icon: Icons.favorite),
      FeatureItem(type: 'breakup', title: '재회·이별', icon: Icons.heart_broken),
      FeatureItem(type: 'newyear', title: '신년운세', icon: Icons.calendar_month),
      FeatureItem(type: 'job', title: '직업운', icon: Icons.work_outline),
      FeatureItem(type: 'money', title: '재물운', icon: Icons.savings_outlined),
      FeatureItem(type: 'mind', title: '심리상담', icon: Icons.psychology_alt_outlined),
      FeatureItem(type: 'style', title: '헤어컨설팅', icon: Icons.content_cut),
      FeatureItem(type: 'naming', title: '아이 작명', icon: Icons.child_care_outlined),
    ];

    return Column(
      children: [
        _TopBar(
          title: '관령이의 소름사주',
          hearts: hearts,
          isSubscriber: isSubscriber,
          onOpenStore: widget.onOpenStore,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _DailyCard(
            text: dailyText,
            loading: loadingDaily,
            onRefresh: () => _loadDaily(force: true),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) {
                final it = items[i];
                return _FeatureTile(
                  title: it.title,
                  icon: it.icon,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeatureFlowScreen(
                          prefs: widget.prefs,
                          feature: it,
                          onOpenStore: widget.onOpenStore,
                        ),
                      ),
                    );
                    setState(() {}); // 하트/구독 갱신
                  },
                );
              },
            ),
          ),
        ),
        const _FooterNote(),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DailyCard extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onRefresh;
  const _DailyCard({required this.text, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔮', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘 관령이 한마디', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(color: Colors.white70, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          )
        ],
      ),
    );
  }
}

/* -----------------------------
   FEATURE FLOW (프리뷰 1회 무료 + 상세 하트10)
------------------------------ */
class FeatureFlowScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final FeatureItem feature;
  final VoidCallback onOpenStore;
  const FeatureFlowScreen({
    super.key,
    required this.prefs,
    required this.feature,
    required this.onOpenStore,
  });

  @override
  State<FeatureFlowScreen> createState() => _FeatureFlowScreenState();
}

class _FeatureFlowScreenState extends State<FeatureFlowScreen> {
  final nameCtrl = TextEditingController(text: '김재영');
  DateTime? birthDate;
  String calendarType = '양력';
  String gender = '남';
  TimeOfDay? birthTime;
  bool timeUnknown = true;

  // 커플
  final partnerNameCtrl = TextEditingController();
  DateTime? partnerBirth;
  String partnerCalendarType = '양력';
  String partnerGender = '여';
  TimeOfDay? partnerTime;
  bool partnerTimeUnknown = true;

  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    partnerNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hearts = widget.prefs.getInt('hearts') ?? 0;
    final isSubscriber = widget.prefs.getBool('isSubscriber') ?? false;

    final featureKey = 'freeUsed_${widget.feature.type}';
    final hasUsedFree = widget.prefs.getBool(featureKey) ?? false;

    const needFullCost = 10;
    final canFull = isSubscriber || hearts >= needFullCost;

    final isCouple = widget.feature.type == 'couple';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feature.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () {
              Navigator.pop(context);
              widget.onOpenStore();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: '안내',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• 최초 1회는 무료 프리뷰(짧게)'),
                SizedBox(height: 6),
                Text('• 그 다음부터 상세: 하트 10개 또는 월정액'),
                SizedBox(height: 6),
                Text('• “상세”는 더 길고 재밌게(건전 유머) + 현실 조언까지'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: '내 정보 입력',
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '이름')),
                const SizedBox(height: 10),
                _DatePickerRow(
                  label: '생년월일',
                  value: birthDate,
                  onPick: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900, 1, 1),
                      lastDate: DateTime.now(),
                      initialDate: birthDate ?? DateTime(1990, 12, 27),
                    );
                    if (d != null) setState(() => birthDate = d);
                  },
                ),
                const SizedBox(height: 10),
                _SegmentRow(
                  label: '음/양력',
                  options: const ['양력', '음력'],
                  value: calendarType,
                  onChanged: (v) => setState(() => calendarType = v),
                ),
                const SizedBox(height: 10),
                _SegmentRow(
                  label: '성별',
                  options: const ['남', '여'],
                  value: gender,
                  onChanged: (v) => setState(() => gender = v),
                ),
                const SizedBox(height: 10),
                _TimePickerRow(
                  label: '태어난 시간',
                  timeUnknown: timeUnknown,
                  time: birthTime,
                  onToggleUnknown: (v) => setState(() => timeUnknown = v),
                  onPick: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: birthTime ?? const TimeOfDay(hour: 3, minute: 0),
                    );
                    if (t != null) setState(() => birthTime = t);
                  },
                ),
              ],
            ),
          ),
          if (isCouple) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: '상대 정보 입력 (궁합)',
              child: Column(
                children: [
                  TextField(controller: partnerNameCtrl, decoration: const InputDecoration(labelText: '상대 이름')),
                  const SizedBox(height: 10),
                  _DatePickerRow(
                    label: '상대 생년월일',
                    value: partnerBirth,
                    onPick: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: DateTime.now(),
                        initialDate: partnerBirth ?? DateTime(1990, 1, 1),
                      );
                      if (d != null) setState(() => partnerBirth = d);
                    },
                  ),
                  const SizedBox(height: 10),
                  _SegmentRow(
                    label: '상대 음/양력',
                    options: const ['양력', '음력'],
                    value: partnerCalendarType,
                    onChanged: (v) => setState(() => partnerCalendarType = v),
                  ),
                  const SizedBox(height: 10),
                  _SegmentRow(
                    label: '상대 성별',
                    options: const ['남', '여'],
                    value: partnerGender,
                    onChanged: (v) => setState(() => partnerGender = v),
                  ),
                  const SizedBox(height: 10),
                  _TimePickerRow(
                    label: '상대 태어난 시간',
                    timeUnknown: partnerTimeUnknown,
                    time: partnerTime,
                    onToggleUnknown: (v) => setState(() => partnerTimeUnknown = v),
                    onPick: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: partnerTime ?? const TimeOfDay(hour: 3, minute: 0),
                      );
                      if (t != null) setState(() => partnerTime = t);
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _InfoCard(
            title: '내 상태',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('무료 프리뷰: ${hasUsedFree ? "이미 사용" : "아직 안 씀"}'),
                const SizedBox(height: 6),
                Text('하트: $hearts   |   월정액: ${isSubscriber ? "ON" : "OFF"}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    if (birthDate == null) {
                      _toast(context, '생년월일을 선택해줘');
                      return;
                    }
                    if (isCouple) {
                      if (partnerNameCtrl.text.trim().isEmpty) {
                        _toast(context, '상대 이름도 입력해줘');
                        return;
                      }
                      if (partnerBirth == null) {
                        _toast(context, '상대 생년월일도 선택해줘');
                        return;
                      }
                    }

                    final detailLevel = hasUsedFree ? 'full' : 'preview';

                    if (detailLevel == 'full' && !canFull) {
                      _showNeedHeartsDialog(context, onGoStore: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        widget.onOpenStore();
                      });
                      return;
                    }

                    setState(() => loading = true);
                    try {
                      final memory = MemoryBox(widget.prefs).summary();

                      final payload = <String, dynamic>{
                        'type': widget.feature.type,
                        'detailLevel': detailLevel,
                        'name': nameCtrl.text.trim(),
                        'birth': DateFormat('yyyyMMdd').format(birthDate!),
                        'calendarType': calendarType,
                        'timeText': timeUnknown ? '모름' : _fmtTime(birthTime),
                        'gender': gender,
                        'memory': memory,
                      };

                      if (isCouple) {
                        payload['partner'] = {
                          'name': partnerNameCtrl.text.trim(),
                          'birth': DateFormat('yyyyMMdd').format(partnerBirth!),
                          'calendarType': partnerCalendarType,
                          'timeText': partnerTimeUnknown ? '모름' : _fmtTime(partnerTime),
                          'gender': partnerGender,
                        };
                      }

                      final text = await ApiService.postAi(widget.prefs, payload);

                      // ✅ 전면광고 (구독이면 안 뜸)
                      final isSubNow = widget.prefs.getBool('isSubscriber') ?? false;
                      await InterstitialAdManager.instance.show(disabled: isSubNow);
                      await InterstitialAdManager.instance.preload();

                      if (detailLevel == 'preview') {
                        await widget.prefs.setBool(featureKey, true);
                      } else {
                        if (!isSubscriber) {
                          await widget.prefs.setInt('hearts', hearts - 10);
                        }
                      }

                      await MemoryBox(widget.prefs).remember(widget.feature.title);

                      await HistoryRepo(widget.prefs).add(
                        HistoryItem(
                          type: widget.feature.type,
                          title: widget.feature.title,
                          createdAt: DateTime.now(),
                          detailLevel: detailLevel,
                          inputSummary: '${widget.feature.title} • ${nameCtrl.text.trim()} • '
                              '${DateFormat('yyyy-MM-dd').format(birthDate!)}($calendarType) • '
                              '${timeUnknown ? "모름" : _fmtTime(birthTime)} • $gender',
                          resultText: text,
                        ),
                      );

                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            prefs: widget.prefs,
                            title: widget.feature.title,
                            detailLevel: detailLevel,
                            text: text,
                            onOpenStore: widget.onOpenStore,
                          ),
                        ),
                      );
                      setState(() {});
                    } catch (e) {
                      _toast(context, '서버/AI 오류: $e');
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            child: loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(hasUsedFree ? '상세 보기 (하트10)' : '무료 프리뷰 보기 (1회)'),
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final SharedPreferences prefs;
  final String title;
  final String detailLevel;
  final String text;
  final VoidCallback onOpenStore;
  const ResultScreen({
    super.key,
    required this.prefs,
    required this.title,
    required this.detailLevel,
    required this.text,
    required this.onOpenStore,
  });

  @override
  Widget build(BuildContext context) {
    final isPreview = detailLevel == 'preview';
    return Scaffold(
      appBar: AppBar(
        title: Text('$title 결과'),
        actions: [
          if (isPreview)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onOpenStore();
              },
              child: const Text('상세 해제'),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF12121A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: SingleChildScrollView(
            child: Text(
              isPreview ? _previewBadge(text) : text,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ),
      ),
    );
  }

  String _previewBadge(String t) {
    return '🔒 [프리뷰]\n'
        '— — — — — — — — — —\n'
        '$t\n'
        '\n— — — — — — — — — —\n'
        '상세는 상점에서 하트/월정액으로 해제할 수 있어요.';
  }
}

/* -----------------------------
   CHAT (하루 무료 5회 + 이후 하트2)
------------------------------ */
class ChatScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onOpenStore;
  const ChatScreen({super.key, required this.prefs, required this.onOpenStore});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final inputCtrl = TextEditingController();
  final List<_ChatMsg> messages = [];
  bool sending = false;

  static const freeDaily = 5;
  static const costPerQuestion = 2;

  @override
  void initState() {
    super.initState();

    final mem = MemoryBox(widget.prefs).summary();
    final intro = mem.isEmpty
        ? '오케이. 여기서부터는 관령이가 “짧고 재밌게” 봐준다.\n하루 무료 5번, 그 뒤엔 하트 2개씩 😎\n뭐부터 찔러볼래?'
        : '흠… 너 요즘 $mem 쪽으로 기운이 자주 흔들리던데?\n하루 무료 5번, 그 뒤엔 하트 2개씩 😎\n오늘은 뭐가 제일 궁금해?';
    messages.add(_ChatMsg(role: 'assistant', text: intro));
  }

  @override
  void dispose() {
    inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hearts = widget.prefs.getInt('hearts') ?? 0;
    final isSubscriber = widget.prefs.getBool('isSubscriber') ?? false;

    final used = _getTodayChatCount(widget.prefs);
    final remainingFree = (freeDaily - used).clamp(0, freeDaily);

    return Column(
      children: [
        _TopBar(
          title: '채팅 상담',
          hearts: hearts,
          isSubscriber: isSubscriber,
          onOpenStore: widget.onOpenStore,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '오늘 무료: $remainingFree회 남음  |  추가 질문: 하트 $costPerQuestion개',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              final isMe = m.role == 'user';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF2C2147) : const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(m.text, style: const TextStyle(height: 1.3)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputCtrl,
                  decoration: const InputDecoration(
                    hintText: '질문 입력… (예: 그 사람 연락 올까?)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final q = inputCtrl.text.trim();
                        if (q.isEmpty) return;

                        final nowUsed = _getTodayChatCount(widget.prefs);
                        final canFree = nowUsed < freeDaily;
                        final canPaid = isSubscriber || hearts >= costPerQuestion;

                        if (!canFree && !canPaid) {
                          _showNeedHeartsDialog(context, onGoStore: () {
                            Navigator.pop(context);
                            widget.onOpenStore();
                          });
                          return;
                        }

                        setState(() {
                          messages.add(_ChatMsg(role: 'user', text: q));
                          sending = true;
                          inputCtrl.clear();
                        });

                        try {
                          if (canFree) {
                            await _incTodayChatCount(widget.prefs);
                          } else if (!isSubscriber) {
                            await widget.prefs.setInt('hearts', hearts - costPerQuestion);
                          }

                          await MemoryBox(widget.prefs).remember('채팅');

                          final text = await ApiService.postAi(widget.prefs, {
                            'type': 'chat',
                            'detailLevel': 'full',
                            'question': q,
                            'memory': MemoryBox(widget.prefs).summary(),
                          });

                          setState(() {
                            messages.add(_ChatMsg(role: 'assistant', text: text));
                          });
                        } catch (e) {
                          setState(() {
                            messages.add(_ChatMsg(
                              role: 'assistant',
                              text: '음… 지금 기운이 좀 꼬였네 😵\n서버/AI 연결을 확인해줘.\n에러: $e',
                            ));
                          });
                        } finally {
                          if (mounted) setState(() => sending = false);
                        }
                      },
                child: sending ? const Text('전송중') : const Text('전송'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -----------------------------
   STORE (✅ 찐결제)
------------------------------ */
class StoreScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onBackHome;
  const StoreScreen({super.key, required this.prefs, required this.onBackHome});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool busy = false;

  Future<void> _refreshProducts() async {
    setState(() => busy = true);
    await IapManager.instance.queryProducts();
    if (mounted) setState(() => busy = false);
  }

  @override
  void initState() {
    super.initState();
    // 들어오면 상품 갱신
    if (PluginGate.isMobile) {
      Future.microtask(_refreshProducts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hearts = widget.prefs.getInt('hearts') ?? 0;
    final isSubscriber = widget.prefs.getBool('isSubscriber') ?? false;

    final iap = IapManager.instance;
    final err = iap.lastError;

    ProductDetails? pd(String id) => iap.products[id];

    String priceOrDash(String id) => pd(id)?.price ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('상점'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBackHome),
        actions: [
          IconButton(
            tooltip: '복원',
            icon: const Icon(Icons.restore),
            onPressed: !PluginGate.isMobile
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await iap.restore();
                      _toast(context, '복원 요청 완료');
                    } catch (e) {
                      _toast(context, '복원 실패: $e');
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: !PluginGate.isMobile || busy ? null : _refreshProducts,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: '내 상태',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('하트: $hearts'),
                const SizedBox(height: 6),
                Text('월정액: ${isSubscriber ? "활성(광고 제거)" : "비활성"}'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (!PluginGate.isMobile)
            const _InfoCard(
              title: '안내',
              child: Text('웹에서는 결제/광고가 비활성입니다. 안드로이드에서 테스트하세요.'),
            ),

          if (PluginGate.isMobile) ...[
            _InfoCard(
              title: '결제 상태',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(iap.available ? '✅ Google Play 결제 사용 가능' : '❌ 결제 사용 불가'),
                  const SizedBox(height: 8),
                  if (err != null) Text('⚠️ $err', style: const TextStyle(color: Colors.orangeAccent)),
                  const SizedBox(height: 8),
                  const Text(
                    '※ “찐결제”는 Play Console 내부테스트(AAB 설치)에서 정상 동작합니다.\n'
                    '※ 상품ID는 Play Console 상품ID와 100% 일치해야 합니다.',
                    style: TextStyle(color: Colors.white54, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (busy || iap.loadingProducts)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),

            _InfoCard(
              title: '하트 충전',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BuyRow(
                    title: '하트 10개',
                    price: priceOrDash(kIapHearts10),
                    onBuy: (!iap.available || busy)
                        ? null
                        : () async {
                            await _buyConsumable(context, kIapHearts10);
                          },
                  ),
                  const SizedBox(height: 10),
                  _BuyRow(
                    title: '하트 20개',
                    price: priceOrDash(kIapHearts20),
                    onBuy: (!iap.available || busy)
                        ? null
                        : () async {
                            await _buyConsumable(context, kIapHearts20);
                          },
                  ),
                  const SizedBox(height: 10),
                  _BuyRow(
                    title: '하트 30개',
                    price: priceOrDash(kIapHearts30),
                    onBuy: (!iap.available || busy)
                        ? null
                        : () async {
                            await _buyConsumable(context, kIapHearts30);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _InfoCard(
              title: '월정액(광고 제거 + 무제한)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('월정액 가격: ${priceOrDash(kSubMonthly)}'),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: (!iap.available || busy || isSubscriber)
                        ? null
                        : () async {
                            await _buySub(context);
                          },
                    child: Text(isSubscriber ? '이미 활성' : '월정액 가입'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _buyConsumable(BuildContext context, String productId) async {
    final iap = IapManager.instance;
    setState(() => busy = true);
    try {
      await iap.buyConsumable(productId);
      _toast(context, '결제 진행 중…(완료되면 자동으로 하트 지급)');
      // 구매 완료는 purchaseStream에서 처리됨
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() {});
    } catch (e) {
      _toast(context, '결제 시작 실패: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _buySub(BuildContext context) async {
    final iap = IapManager.instance;
    setState(() => busy = true);
    try {
      await iap.buySubscription(kSubMonthly);
      _toast(context, '구독 결제 진행 중…(완료되면 자동 활성)');
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() {});
    } catch (e) {
      _toast(context, '구독 시작 실패: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _BuyRow extends StatelessWidget {
  final String title;
  final String price;
  final VoidCallback? onBuy;
  const _BuyRow({required this.title, required this.price, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('$title  •  $price', style: const TextStyle(fontWeight: FontWeight.w700))),
        FilledButton.tonal(onPressed: onBuy, child: const Text('구매')),
      ],
    );
  }
}

/* -----------------------------
   HISTORY (최소 구현)
------------------------------ */
class HistoryScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const HistoryScreen({super.key, required this.prefs});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    list = await HistoryRepo(widget.prefs).getAll();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(
          title: '기록',
          hearts: widget.prefs.getInt('hearts') ?? 0,
          isSubscriber: widget.prefs.getBool('isSubscriber') ?? false,
          onOpenStore: () {},
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('아직 기록이 없어요'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final it = list[i];
                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              prefs: widget.prefs,
                              title: it.title,
                              detailLevel: it.detailLevel,
                              text: it.resultText,
                              onOpenStore: () {},
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(it.inputSummary, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(it.createdAt),
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/* -----------------------------
   SETTINGS (최소 구현)
------------------------------ */
class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController apiCtrl;

  @override
  void initState() {
    super.initState();
    apiCtrl = TextEditingController(text: widget.prefs.getString('apiBaseUrl') ?? ApiService.defaultBaseUrl);
  }

  @override
  void dispose() {
    apiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hearts = widget.prefs.getInt('hearts') ?? 0;
    final isSubscriber = widget.prefs.getBool('isSubscriber') ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TopBar(title: '설정', hearts: hearts, isSubscriber: isSubscriber, onOpenStore: () {}),
        const SizedBox(height: 12),
        _InfoCard(
          title: '서버 주소',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('기본 서버: ${ApiService.defaultBaseUrl}'),
              const SizedBox(height: 12),
              TextField(
                controller: apiCtrl,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: ApiService.defaultBaseUrl,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () async {
                  await widget.prefs.setString('apiBaseUrl', apiCtrl.text.trim());
                  if (!mounted) return;
                  _toast(context, '저장 완료');
                },
                child: const Text('저장'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: () async {
                  try {
                    final r = await ApiService.healthCheck(widget.prefs);
                    if (!mounted) return;
                    _toast(context, '헬스체크 OK: $r');
                  } catch (e) {
                    if (!mounted) return;
                    _toast(context, '헬스체크 실패: $e');
                  }
                },
                child: const Text('서버 연결 테스트(/health)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: '개발용 초기화',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('무료 프리뷰 사용 기록/오늘 채팅 카운트/기억을 초기화합니다.'),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: () async {
                  for (final t in ['saju','solo','couple','breakup','newyear','job','money','mind','style','naming']) {
                    await widget.prefs.remove('freeUsed_$t');
                  }
                  final today = DateFormat('yyyyMMdd').format(DateTime.now());
                  await widget.prefs.remove('chatCount_$today');
                  await MemoryBox(widget.prefs).clear();
                  if (!mounted) return;
                  _toast(context, '초기화 완료');
                },
                child: const Text('초기화'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -----------------------------
   MEMORY
------------------------------ */
class MemoryBox {
  final SharedPreferences prefs;
  MemoryBox(this.prefs);

  static const key = 'memory_tags';

  Future<void> remember(String tag) async {
    final list = prefs.getStringList(key) ?? [];
    final next = [tag, ...list.where((e) => e != tag)].take(5).toList();
    await prefs.setStringList(key, next);
  }

  String summary() {
    final list = prefs.getStringList(key) ?? [];
    if (list.isEmpty) return '';
    return list.take(3).join('/');
  }

  Future<void> clear() async {
    await prefs.remove(key);
  }
}

/* -----------------------------
   HISTORY
------------------------------ */
class HistoryItem {
  final String type;
  final String title;
  final DateTime createdAt;
  final String detailLevel;
  final String inputSummary;
  final String resultText;

  HistoryItem({
    required this.type,
    required this.title,
    required this.createdAt,
    required this.detailLevel,
    required this.inputSummary,
    required this.resultText,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'detailLevel': detailLevel,
        'inputSummary': inputSummary,
        'resultText': resultText,
      };

  static HistoryItem fromJson(Map<String, dynamic> j) => HistoryItem(
        type: j['type'],
        title: j['title'],
        createdAt: DateTime.parse(j['createdAt']),
        detailLevel: j['detailLevel'],
        inputSummary: j['inputSummary'],
        resultText: j['resultText'],
      );
}

class HistoryRepo {
  final SharedPreferences prefs;
  HistoryRepo(this.prefs);

  static const key = 'history_items';

  Future<void> add(HistoryItem item) async {
    final list = await getAll();
    list.insert(0, item);
    final trimmed = list.take(50).toList();
    final raw = trimmed.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(key, raw);
  }

  Future<List<HistoryItem>> getAll() async {
    final raw = prefs.getStringList(key) ?? [];
    return raw.map((s) => HistoryItem.fromJson(jsonDecode(s))).toList();
  }
}

/* -----------------------------
   UI COMPONENTS
------------------------------ */
class FeatureItem {
  final String type;
  final String title;
  final IconData icon;
  FeatureItem({required this.type, required this.title, required this.icon});
}

class _TopBar extends StatelessWidget {
  final String title;
  final int hearts;
  final bool isSubscriber;
  final VoidCallback onOpenStore;

  const _TopBar({
    required this.title,
    required this.hearts,
    required this.isSubscriber,
    required this.onOpenStore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onOpenStore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 16, color: Colors.pinkAccent),
                  const SizedBox(width: 6),
                  Text('$hearts', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Icon(isSubscriber ? Icons.verified : Icons.lock_outline, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.pinkAccent),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DatePickerRow({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final txt = value == null ? '선택' : DateFormat('yyyy-MM-dd').format(value!);
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white70))),
        Expanded(child: OutlinedButton(onPressed: onPick, child: Text(txt))),
      ],
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _SegmentRow({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white70))),
        Expanded(
          child: Wrap(
            spacing: 10,
            children: options.map((o) {
              final selected = o == value;
              return ChoiceChip(
                label: Text(o),
                selected: selected,
                onSelected: (_) => onChanged(o),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final bool timeUnknown;
  final TimeOfDay? time;
  final ValueChanged<bool> onToggleUnknown;
  final VoidCallback onPick;

  const _TimePickerRow({
    required this.label,
    required this.timeUnknown,
    required this.time,
    required this.onToggleUnknown,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final txt = timeUnknown ? '모름' : _fmtTime(time);
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white70))),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: timeUnknown ? null : onPick,
                  child: Text(txt),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('모름'),
                selected: timeUnknown,
                onSelected: (v) => onToggleUnknown(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '※ 결제는 Play Console 내부테스트(AAB 설치)에서 “찐결제”로 동작해요.\n'
        '※ 상품ID(hearts_10 등)는 Play Console과 완전 동일해야 합니다.',
        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
      ),
    );
  }
}

class _ChatMsg {
  final String role;
  final String text;
  _ChatMsg({required this.role, required this.text});
}

/* -----------------------------
   HELPERS
------------------------------ */
String _fmtTime(TimeOfDay? t) {
  if (t == null) return '모름';
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh$mm';
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

void _showNeedHeartsDialog(BuildContext context, {required VoidCallback onGoStore}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('하트가 부족해요'),
      content: const Text('상세/추가 질문은 하트 또는 월정액이 필요해요.\n상점으로 이동할까요?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: onGoStore, child: const Text('상점으로')),
      ],
    ),
  );
}

int _getTodayChatCount(SharedPreferences prefs) {
  final today = DateFormat('yyyyMMdd').format(DateTime.now());
  final key = 'chatCount_$today';
  return prefs.getInt(key) ?? 0;
}

Future<void> _incTodayChatCount(SharedPreferences prefs) async {
  final today = DateFormat('yyyyMMdd').format(DateTime.now());
  final key = 'chatCount_$today';
  final cur = prefs.getInt(key) ?? 0;
  await prefs.setInt(key, cur + 1);
}

/* -----------------------------
   PREF EXT
------------------------------ */
extension _PrefsExt on SharedPreferences {
  void setStringIfNull(String key, String value) {
    if (!containsKey(key)) setString(key, value);
  }

  void setIntIfNull(String key, int value) {
    if (!containsKey(key)) setInt(key, value);
  }

  void setBoolIfNull(String key, bool value) {
    if (!containsKey(key)) setBool(key, value);
  }
}