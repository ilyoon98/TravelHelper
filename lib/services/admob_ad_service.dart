import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Real AdMob ad unit IDs (from the AdMob console — these identifiers are
/// public, not secrets, so it's normal to ship them in source).
///
/// [useTestIds] flips every ID to Google's official always-fill test units —
/// flip this to true to check "is my integration code correct?" separately
/// from "is my real ad unit serving fill yet?" (a brand-new unit can take up
/// to ~1 hour, or longer if the app itself is still pending AdMob review).
/// Remember to flip it back to false before shipping.
class AdUnitIds {
  AdUnitIds._();

  static const useTestIds = false;

  static const androidAppId =
      useTestIds ? 'ca-app-pub-3940256099942544~3347511713' : 'ca-app-pub-3418571939032672~9394087901';
  static const bannerAdUnitId =
      useTestIds ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3418571939032672/5621916745';
  static const rewardedAdUnitId =
      useTestIds ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3418571939032672/2995753402';
}

/// Real AdMob-backed [AdService]. A brand-new ad unit can take up to ~1 hour
/// after creation before AdMob actually starts serving fill for it — until
/// then, loads will fail here exactly the same way a genuine no-fill would,
/// which is expected and not a bug. [ensureRewardedAdLoading] is a cheap,
/// idempotent "top up the cache if empty" call — the currency tab calls it
/// on its own periodic timer while it's on screen (see currency_tab.dart),
/// so an ad is very likely already waiting by the time the user taps "최신
/// 환율 받기" instead of them having to keep tapping to retry manually. That
/// timer lives on the tab's widget lifecycle rather than here so it stops
/// when the tab isn't visible and never leaks (e.g. into widget tests).
class AdMobAdService implements AdService {
  AdMobAdService._() {
    _loadRewardedAd();
  }

  static final AdMobAdService instance = AdMobAdService._();

  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  @override
  bool get isAdRemoved => false;

  @override
  Widget bannerWidget(BuildContext context) => const _BannerAdWidget();

  @override
  void ensureRewardedAdLoading() => _loadRewardedAd();

  void _loadRewardedAd() {
    if (_loadingRewarded || _rewardedAd != null) return;
    _loadingRewarded = true;
    try {
      RewardedAd.load(
        adUnitId: AdUnitIds.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _loadingRewarded = false;
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _loadingRewarded = false;
          },
        ),
      );
    } catch (_) {
      _loadingRewarded = false;
    }
  }

  @override
  Future<bool> showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewardedAd();
      throw AdNotReadyException();
    }
    _rewardedAd = null; // consumed — preload the next one below.

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    try {
      BannerAd(
        adUnitId: AdUnitIds.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) setState(() => _bannerAd = ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      ).load();
    } catch (_) {
      // No ad this session — the banner slot just stays empty.
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
