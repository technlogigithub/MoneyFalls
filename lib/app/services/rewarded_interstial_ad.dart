// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class RewardedInterstitialAdService {
//   RewardedInterstitialAd? _rewardedInterstitialAd;
//   bool _isLoaded = false;

//   // ✅ CORRECT TEST Ad Unit ID for Rewarded Interstitial
//   final String adUnitId = 'ca-app-pub-7423453817166141~9588912494';

//   Future<void> loadAd({
//     VoidCallback? onLoaded,
//     Function(String)? onFailed,
//   }) async {
//     await RewardedInterstitialAd.load(
//       adUnitId: adUnitId,
//       request: const AdRequest(),
//       rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
//         onAdLoaded: (RewardedInterstitialAd ad) {
//           _rewardedInterstitialAd = ad;
//           _isLoaded = true;
//           onLoaded?.call();
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           _isLoaded = false;
//           onFailed?.call(error.message);
//         },
//       ),
//     );
//   }

//   void showMultipleAds({
//     required BuildContext context,
//     required void Function(RewardItem reward) onRewarded,
//     VoidCallback? onAllAdsClosed,
//     Function(String)? onError,
//     int adCount = 5,
//   }) {
//     int currentAdIndex = 0;

//     Future<void> showNextAd() async {
//       if (currentAdIndex >= adCount) {
//         onAllAdsClosed?.call();
//         return;
//       }

//       await loadAd(
//         onLoaded: () {
//           _rewardedInterstitialAd!.fullScreenContentCallback =
//               FullScreenContentCallback(
//             onAdShowedFullScreenContent: (ad) =>
//                 debugPrint("Ad ${currentAdIndex + 1} shown"),
//             onAdImpression: (ad) => debugPrint("Ad impression"),
//             onAdClicked: (ad) => debugPrint("Ad clicked"),
//             onAdFailedToShowFullScreenContent: (ad, error) {
//               ad.dispose();
//               _isLoaded = false;
//               onError?.call(error.message);
//               currentAdIndex++;
//               Future.delayed(const Duration(seconds: 10), showNextAd);
//             },
//             onAdDismissedFullScreenContent: (ad) {
//               ad.dispose();
//               _isLoaded = false;
//               currentAdIndex++;
//               Future.delayed(const Duration(seconds: 2), showNextAd);
//             },
//           );

//           _rewardedInterstitialAd!.show(
//             onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//               onRewarded(reward);
//             },
//           );

//           _isLoaded = false;
//         },
//         onFailed: (error) {
//           onError?.call(error);
//           currentAdIndex++;
//           Future.delayed(const Duration(seconds: 10), showNextAd);
//         },
//       );
//     }

//     showNextAd();
//   }

//   void dispose() {
//     _rewardedInterstitialAd?.dispose();
//   }

//   bool get isAdReady => _isLoaded;
// }
