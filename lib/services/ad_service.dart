import 'package:flutter/widgets.dart';

/// Thrown by [AdService.showRewardedAd] when no ad is currently loaded (e.g.
/// still loading, or the last load attempt failed) — distinct from "the user
/// watched it but skipped before earning the reward", which just returns
/// false, so callers can show a different message for each case.
class AdNotReadyException implements Exception {}

/// Abstraction over ads so screens never talk to the AdMob SDK directly.
/// [AdMobAdService] is the real implementation; [NoOpAdService] is used once
/// the "광고 제거" IAP is purchased (no ads, rewarded gate always passes).
abstract class AdService {
  /// Banner widget for the bottom of the screen. Returns an empty box when
  /// no ad is available/active.
  Widget bannerWidget(BuildContext context);

  /// Shows a rewarded ad and returns true if the user watched it fully and
  /// earned the reward. Throws [AdNotReadyException] if no ad is loaded yet.
  Future<bool> showRewardedAd();

  /// Cheap, idempotent hint: "load a rewarded ad now if one isn't already
  /// loaded/loading". Safe to call repeatedly (e.g. from a periodic timer).
  void ensureRewardedAdLoading();

  bool get isAdRemoved;
}

class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Widget bannerWidget(BuildContext context) => const SizedBox.shrink();

  @override
  Future<bool> showRewardedAd() async => true;

  @override
  void ensureRewardedAdLoading() {}

  @override
  bool get isAdRemoved => true;
}
