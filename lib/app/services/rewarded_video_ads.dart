import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoaded = false;
  bool _isLoading = false; // Add loading state

  final String adUnitId = 'ca-app-pub-3940256099942544/5224354917';
  int _adsShown = 0;
  final int maxAdsToShow = 5;

  void loadAndShowSequentialAds({
    required BuildContext context,
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onAllAdsFinished,
    Function(String)? onError,
  }) async {
    // Prevent multiple simultaneous loads
    if (_isLoading) {
      log("Already loading ads, ignoring request");
      return;
    }

    log("Starting sequential ad loading...");
    _isLoading = true;
    _adsShown = 0;
    _loadAndShowNext(
      context: context,
      onRewarded: onRewarded,
      onAllAdsFinished: onAllAdsFinished,
      onError: onError,
    );
  }

  void _loadAndShowNext({
    required BuildContext context,
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onAllAdsFinished,
    Function(String)? onError,
  }) async {
    if (_adsShown >= maxAdsToShow) {
      log("All ads shown ($_adsShown/$maxAdsToShow), finishing sequence");
      _isLoading = false; // Reset loading state
      onRewarded(RewardItem(10, "type"));

      onAllAdsFinished?.call();
      return;
    }

    log("Loading ad ${_adsShown + 1}/$maxAdsToShow");
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          log("Ad ${_adsShown + 1} loaded successfully");
          _rewardedAd = ad;
          _isLoaded = true;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              log("Ad ${_adsShown + 1} dismissed");
              ad.dispose();
              _isLoaded = false;
              _adsShown++;
              _loadAndShowNext(
                context: context,
                onRewarded: onRewarded,
                onAllAdsFinished: onAllAdsFinished,
                onError: onError,
              );
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              log("Ad ${_adsShown + 1} failed to show: ${error.message}");
              ad.dispose();
              _isLoaded = false;
              onError?.call(error.message);
              _adsShown++;
              _loadAndShowNext(
                context: context,
                onRewarded: onRewarded,
                onAllAdsFinished: onAllAdsFinished,
                onError: onError,
              );
            },
          );
          _rewardedAd!.show(onUserEarnedReward: (ad, reward) {});
        },
        onAdFailedToLoad: (error) {
          log("Ad ${_adsShown + 1} failed to load: ${error.message}");
          _isLoaded = false;
          onError?.call(error.message);
          _adsShown++;
          _loadAndShowNext(
            context: context,
            onRewarded: onRewarded,
            onAllAdsFinished: onAllAdsFinished,
            onError: onError,
          );
        },
      ),
    );
  }

  void dispose() {
    log("Disposing RewardedAdService");
    _rewardedAd?.dispose();
    _isLoading = false; // Reset loading state on dispose
  }

  bool get isAdReady => _isLoaded;
  bool get isLoading => _isLoading; // Add getter for loading state
  bool get isAdLoading => _isLoading; // Alias for consistency
  int get currentAdCount => _adsShown; // Getter for current ad count
  int get maxAdsCount => maxAdsToShow; // Getter for max ads count
}
