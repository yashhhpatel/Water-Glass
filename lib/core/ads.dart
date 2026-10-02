import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'data.dart';

/// Google AdMob integration. All ad unit ids are Google's official TEST ids;
/// replace them (and the APPLICATION_ID in AndroidManifest.xml) with your own
/// ids before publishing.
class Ads {
  static const appOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const interstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const rewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const bannerId = 'ca-app-pub-3940256099942544/9214589741';

  /// Interstitial after every N completed levels.
  static const levelsPerInterstitial = 3;

  static bool _started = false;
  static AppOpenAd? _appOpen;
  static DateTime? _appOpenLoadedAt;
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static bool _rewardedLoading = false;
  static bool _fullscreen = false;
  static DateTime _lastFullscreenClosed = DateTime.fromMillisecondsSinceEpoch(0);
  static bool _skipNextResume = false;

  static bool get adsRemoved => GameData.I.adsRemoved;

  /// Consent (UMP) first, then the SDK, then preload.
  static Future<void> init() async {
    if (_started) return;
    _started = true;
    final consent = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => consent.isCompleted ? null : consent.complete()),
      (_) => consent.isCompleted ? null : consent.complete(),
    );
    await consent.future.timeout(const Duration(seconds: 6), onTimeout: () {});
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('Ads init failed: $e');
      return;
    }
    _loadAppOpen();
    _loadInterstitial();
    _loadRewarded();
  }

  // ------------------------------------------------------------- app open
  static bool get _appOpenFresh =>
      _appOpen != null && _appOpenLoadedAt != null && DateTime.now().difference(_appOpenLoadedAt!) < const Duration(hours: 4);

  static void _loadAppOpen() {
    if (adsRemoved) return;
    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (e) => debugPrint('App open failed to load: $e'),
      ),
    );
  }

  /// Waits up to [wait] for an app-open ad during the splash, then shows it.
  static Future<void> showAppOpenOnLaunch({Duration wait = const Duration(seconds: 6)}) async {
    if (adsRemoved || !_started) return;
    final end = DateTime.now().add(wait);
    while (!_appOpenFresh && DateTime.now().isBefore(end)) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    await _showAppOpen();
  }

  /// Called when the app returns to the foreground.
  static Future<void> onResume() async {
    if (_skipNextResume) {
      _skipNextResume = false;
      return;
    }
    if (adsRemoved || _fullscreen || !GameData.I.onboarded) return;
    // returning from one of our own full-screen ads also fires a resume
    if (DateTime.now().difference(_lastFullscreenClosed) < const Duration(seconds: 3)) return;
    await _showAppOpen();
  }

  /// Use before opening another app (mail, Play billing sheet) so coming back
  /// does not trigger an app-open ad.
  static void skipNextResume() => _skipNextResume = true;

  static Future<void> _showAppOpen() async {
    final ad = _appOpen;
    if (ad == null || !_appOpenFresh || _fullscreen || adsRemoved) {
      if (_appOpen == null) _loadAppOpen();
      return;
    }
    _appOpen = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _fullscreen = true,
      onAdDismissedFullScreenContent: (a) {
        _closed(a);
        if (!done.isCompleted) done.complete();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        _closed(a);
        if (!done.isCompleted) done.complete();
        _loadAppOpen();
      },
    );
    ad.show();
    await done.future.timeout(const Duration(minutes: 2), onTimeout: () {});
  }

  static void _closed(Ad ad) {
    _fullscreen = false;
    _lastFullscreenClosed = DateTime.now();
    ad.dispose();
  }

  // ---------------------------------------------------------- interstitial
  static void _loadInterstitial() {
    if (adsRemoved) return;
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) => debugPrint('Interstitial failed to load: $e'),
      ),
    );
  }

  /// Count a finished level (classic, boss, challenge or Don't Spill).
  static void levelCompleted() {
    GameData.I.levelsSinceAd++;
    GameData.I.save();
  }

  /// Shows an interstitial when 3 levels have been completed since the last
  /// one. Call at a natural break (the NEXT LEVEL button).
  static Future<void> maybeShowInterstitial() async {
    final d = GameData.I;
    if (adsRemoved || d.levelsSinceAd < levelsPerInterstitial) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _fullscreen = true;
        d.levelsSinceAd = 0;
        d.save();
      },
      onAdDismissedFullScreenContent: (a) {
        _closed(a);
        if (!done.isCompleted) done.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        _closed(a);
        if (!done.isCompleted) done.complete();
        _loadInterstitial();
      },
    );
    ad.show();
    await done.future.timeout(const Duration(minutes: 2), onTimeout: () {});
  }

  // -------------------------------------------------------------- rewarded
  static void _loadRewarded() {
    if (_rewarded != null || _rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (e) {
          _rewardedLoading = false;
          debugPrint('Rewarded failed to load: $e');
        },
      ),
    );
  }

  /// Shows a rewarded video. Returns true if the user earned the reward,
  /// false if they closed it early and null if no video could be loaded.
  /// Rewarded videos stay available after Remove Ads (they are opt-in).
  static Future<bool?> showRewarded({VoidCallback? beforeShow}) async {
    if (!_started) return null;
    if (_rewarded == null) {
      _loadRewarded();
      final end = DateTime.now().add(const Duration(seconds: 5));
      while (_rewarded == null && DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
    final ad = _rewarded;
    if (ad == null) return null;
    _rewarded = null;
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _fullscreen = true,
      onAdDismissedFullScreenContent: (a) {
        _closed(a);
        if (!done.isCompleted) done.complete();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        _closed(a);
        if (!done.isCompleted) done.complete();
        _loadRewarded();
      },
    );
    beforeShow?.call();
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    await done.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    return earned;
  }

  /// Free everything after the player removes ads.
  static void onAdsRemoved() {
    _appOpen?.dispose();
    _appOpen = null;
    _interstitial?.dispose();
    _interstitial = null;
  }
}

/// Adaptive banner for menu screens (never shown during gameplay or after
/// Remove Ads).
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});
  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested && !Ads.adsRemoved && Ads._started) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    final ad = BannerAd(
      adUnitId: Ads.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (a, e) {
          a.dispose();
          debugPrint('Banner failed to load: $e');
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameData.I,
      builder: (_, __) {
        final ad = _ad;
        if (Ads.adsRemoved || !_loaded || ad == null) return const SizedBox.shrink();
        return SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad));
      },
    );
  }
}
