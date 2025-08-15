import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottery/app/modules/bottom_bar/controllers/bottom_bar_controller.dart';
import 'package:lottery/app/services/user_data.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/snackbars.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/rewarded_video_ads.dart';
import '../../../utils/constants.dart';
import '../../../utils/my_text.dart';
import '../../../utils/global_functions.dart';

class HomeController extends GetxController {
  TextEditingController searchController = TextEditingController();
  final UserController userController = Get.find<UserController>();
  final BottomBarController bottomBarController =
      Get.find<BottomBarController>();

  RxString lotteryKey = "lottery_1".obs;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Dynamic lists for 10 lotteries
  RxList<bool> hasJoinedLotteries = List.filled(10, false).obs;
  RxList<int> totalUsersInLotteries = List.filled(10, 0).obs;
  List<String> winnerNames = List.filled(10, 'Unknown Winner');
  List<String> winnerProfilePics = List.filled(10, '');
  List<String> currentWinnerIds = List.filled(10, '');

  RxBool hasShownWinnerDialog = false.obs;
  RxInt totalTickets = 10.obs;

  final adService = RewardedAdService();

  var isLoading = false.obs;
  var isAdLoading = false.obs;

  // Separate loading states for each lottery (10 lotteries)
  RxList<bool> isLoadingLotteries = List.filled(10, false).obs;
  RxList<bool> isAdLoadingLotteries = List.filled(10, false).obs;
  RxList<int> currentAdCountLotteries = List.filled(10, 0).obs;

  RxBool showingDialogueOnce = false.obs;
  bool dialogShownForCurrentWinners = false;

  @override
  void onInit() {
    hasShownWinnerDialog.value = false;
    checkingInit();
    listenToLotteryCountChanges(isFrom7PM: true);
    super.onInit();
  }

  @override
  void onClose() {
    adService.dispose();
    super.onClose();
  }

  checkingInit() async {
    await updateStreakForCurrentUser();
  }

  Widget _buildWinnerColumn(String winnerName, String profilePic,
      int totalUsers, String lotteryName) {
    return Column(
      children: [
        Text(
          lotteryName,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        5.height,
        Image.asset('assets/images/crown.png', scale: 5),
        CachedNetworkImage(
          imageUrl: profilePic,
          imageBuilder: (context, imageProvider) => Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: AppColors.yellowColor,
                width: 2,
              ),
            ),
          ),
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Container(
            height: 100,
            width: 100,
            child: Image.network(AssetsConstant.onlineLogo),
          ),
        ),
        10.height,
        MyText(
          winnerName,
          textAlign: TextAlign.center,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        Row(
          children: [
            MyText(
              totalUsers.toString(),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            Image.asset('assets/images/fire.png'),
          ],
        ),
      ],
    );
  }

  // Fetch the winner's data from Firestore using the winnerID
  Future<Map<String, dynamic>> fetchWinnerData(String winnerId) async {
    if (winnerId.isEmpty) {
      return {'name': 'Unknown Winner'};
    }

    try {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(winnerId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        return data ?? {'name': 'Unknown Winner'};
      } else {
        return {'name': 'Unknown Winner'};
      }
    } catch (e) {
      print('Error fetching winner data: $e');
      return {'name': 'Unknown Winner'};
    }
  }

  Stream<QuerySnapshot> getLotteryStream() {
    return firestore.collection('lotteries').snapshots();
  }

  void updateLotteryStatus(QuerySnapshot querySnapshot,
      {bool isFrom7PM = false}) async {
    log("isFrom7PM $isFrom7PM");
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime referenceDate =
        (now.hour < 19 || (now.hour == 19 && now.minute == 0 && now.second < 2))
            ? now.subtract(Duration(days: 1))
            : now;

    DateTime docDate =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    if (docDate.isAfter(today)) {
      print("Trying to fetch a future lottery document. Aborting.");
      return;
    }
    final String docIdToCheck = docDate.toIso8601String().split('T')[0];

    // Loop through all documents to find and print lotteries with status == true
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      // Check all 10 lotteries
      for (int i = 1; i <= 10; i++) {
        final lotteryData = data?['lottery_$i'] as Map<String, dynamic>? ?? {};
        if ((lotteryData['status'] as bool?) == true) {
          // log('✅ ${doc.id} - Lottery $i with status true: $lotteryData');
        }
      }
    }

    try {
      final doc = querySnapshot.docs.firstWhere(
        (doc) => doc.id == docIdToCheck,
        orElse: () => throw Exception("Document not found for $docIdToCheck"),
      );

      print("Found document: ${doc.id}");
      final data = doc.data() as Map<String, dynamic>?;

      bool anyWinnersChanged = false;

      // Handle all 10 lotteries
      for (int i = 1; i <= 10; i++) {
        final lotteryData = data?['lottery_$i'] as Map<String, dynamic>? ?? {};
        final users = lotteryData['users'] as Map<String, dynamic>? ?? {};

        hasJoinedLotteries[i - 1] = users.containsKey(userId);
        totalUsersInLotteries[i - 1] = (lotteryData['totalUsersCount'] as int?) ?? 0;
        
        String newWinnerId = lotteryData['winnerID'] ?? '';
        print('Lottery $i Full Data: $lotteryData');

        // Check if winner changed
        if (newWinnerId != currentWinnerIds[i - 1]) {
          anyWinnersChanged = true;
          currentWinnerIds[i - 1] = newWinnerId;
        }

        // Fetch winner details
        if (newWinnerId.isNotEmpty) {
          Map<String, dynamic> winnerData = await fetchWinnerData(newWinnerId);
          winnerNames[i - 1] = winnerData['name'] ?? 'Unknown Winner';
          winnerProfilePics[i - 1] = winnerData['profile_image'] ?? '';
          log('Winner $i Profile Pic: ${winnerProfilePics[i - 1]}');
        }
      }

      print('Total users in lotteries: ${totalUsersInLotteries.toString()}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkPurchasedTicket();
      });

      // Reset dialog flag if winners changed
      if (anyWinnersChanged) {
        dialogShownForCurrentWinners = false;
        showingDialogueOnce.value = true;
      }

      // Show dialog if needed (check if any lottery has winners)
      bool hasAnyWinners = currentWinnerIds.any((id) => id.isNotEmpty);
      if (hasAnyWinners && isFrom7PM) {
        showDialogueOnceForWinner();
      }

      print('hasJoinedLotteries: ${hasJoinedLotteries.toString()}');
      print('winnerNames: ${winnerNames.toString()}');
    } catch (e) {
      print('Error: $e');
    }
  }

  void showLotteryWinnerAnnouncement(QuerySnapshot querySnapshot,
      {bool isFrom7PM = false}) async {
    log("isFrom7PM $isFrom7PM");
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime referenceDate = now.subtract(Duration(days: 1));

    DateTime docDate =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    if (docDate.isAfter(today)) {
      print("Trying to fetch a future lottery document. Aborting.");
      return;
    }
    final String docIdToCheck = docDate.toIso8601String().split('T')[0];

    log("Checking for doc ID: $docIdToCheck");

    // Loop through all documents to find and print lotteries with status == true
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;

      // Check all 10 lotteries
      for (int i = 1; i <= 10; i++) {
        final lotteryData = data?['lottery_$i'] as Map<String, dynamic>? ?? {};
        if ((lotteryData['status'] as bool?) == true) {
          // log('✅ ${doc.id} - Lottery $i with status true: $lotteryData');
        }
      }
    }

    try {
      final doc = querySnapshot.docs.firstWhere(
        (doc) => doc.id == docIdToCheck,
        orElse: () => throw Exception("Document not found for $docIdToCheck"),
      );

      print("Found document: ${doc.id}");
      final data = doc.data() as Map<String, dynamic>?;

      bool anyWinnersChanged = false;

      // Handle all 10 lotteries
      for (int i = 1; i <= 10; i++) {
        final lotteryData = data?['lottery_$i'] as Map<String, dynamic>? ?? {};
        final users = lotteryData['users'] as Map<String, dynamic>? ?? {};

        hasJoinedLotteries[i - 1] = users.containsKey(userId);
        totalUsersInLotteries[i - 1] = (lotteryData['totalUsersCount'] as int?) ?? 0;
        
        String newWinnerId = lotteryData['winnerID'] ?? '';
        print('Lottery $i Full Data: $lotteryData');

        // Check if winner changed
        if (newWinnerId != currentWinnerIds[i - 1]) {
          anyWinnersChanged = true;
          currentWinnerIds[i - 1] = newWinnerId;
        }

        // Fetch winner details
        if (newWinnerId.isNotEmpty) {
          Map<String, dynamic> winnerData = await fetchWinnerData(newWinnerId);
          winnerNames[i - 1] = winnerData['name'] ?? 'Unknown Winner';
          winnerProfilePics[i - 1] = winnerData['profile_image'] ?? '';
          log('Winner $i Profile Pic: ${winnerProfilePics[i - 1]}');
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkPurchasedTicket();
      });

      // Reset dialog flag if winners changed
      if (anyWinnersChanged) {
        dialogShownForCurrentWinners = false;
        showingDialogueOnce.value = true;
      }

      // Show dialog if needed (check if any lottery has winners)
      bool hasAnyWinners = currentWinnerIds.any((id) => id.isNotEmpty);
      if (hasAnyWinners && isFrom7PM) {
        showDialogueOnceForWinner();
      }

      print('hasJoinedLotteries: ${hasJoinedLotteries.toString()}');
      print('winnerNames: ${winnerNames.toString()}');
    } catch (e) {
      log('Error: $e');
    }
  }

  showDialogueOnceForWinner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Create a scrollable grid view for 10 winners
      Get.defaultDialog(
        title: '',
        barrierDismissible: false,
        content: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Center(
                    child: MyText(
                      'Winners',
                      fontSize: 25,
                      fontWeight: FontWeight.w400,
                      color: AppColors.blackColor,
                    ),
                  ),
                  20.height,
                  Container(
                    height: 400, // Fixed height for scrollable area
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        if (currentWinnerIds[index].isNotEmpty) {
                          return _buildWinnerColumn(
                            winnerNames[index],
                            winnerProfilePics[index],
                            totalUsersInLotteries[index],
                            "Program ${index + 1}",
                          );
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Program ${index + 1}"),
                                Text("No Winner", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  20.height,
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.back();
                            hasShownWinnerDialog.value = true;
                          },
                          child: Container(
                            width: Get.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              border:
                                  Border.all(color: AppColors.lightBlueColor),
                              color: AppColors.whiteColor,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: Center(
                                child: MyText.titleLarge(
                                  'Done',
                                  fontSize: 18,
                                  color: AppColors.lightBlueColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -120,
              right: 10,
              left: 10,
              child: Image.asset(
                'assets/images/top_crown.png',
                scale: 2.6,
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> joinLottery(BuildContext context, bool isFromAds,
      {int? lotteryNumber}) async {
    // Validate lottery number
    if (lotteryNumber == null || lotteryNumber < 1 || lotteryNumber > 10) {
      AppSnackBar.showError(message: 'Invalid lottery number');
      return;
    }

    // Set loading state for specific lottery
    isLoadingLotteries[lotteryNumber - 1] = true;

    GlobalFunctions.showProgressDialog();

    final now = DateTime.now();
    final isBefore7PM = now.hour < 19;
    final dateStr = DateFormat('yyyy-MM-dd').format(
      isBefore7PM ? now.subtract(Duration(days: 1)) : now,
    );

    try {
      final docRef = firestore.collection('lotteries').doc(dateStr);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        GlobalFunctions.hideProgressDialog();
        AppSnackBar.showError(message: 'Lottery for $dateStr does not exist.');
        return;
      }

      final lotteryData =
          docSnapshot.data()![lotteryKey.value] as Map<String, dynamic>;
      if (lotteryData['status'] == false) {
        GlobalFunctions.hideProgressDialog();
        AppSnackBar.showError(message: 'This lottery is closed.');
        return;
      }

      final usersMap = lotteryData['users'] as Map<String, dynamic>? ?? {};
      if (usersMap.containsKey(userId)) {
        GlobalFunctions.hideProgressDialog();
        AppSnackBar.showError(message: 'You have already joined.');
        return;
      }
      final referralUsername =
          userController.userData.value?.referralUsername ?? '';

      bool hasReferral = referralUsername.trim().isNotEmpty;

      num totalCoins = userController.userData.value?.totalCoins ?? 0;
      if (!isFromAds) {
        int coinsToDeduct = hasReferral ? 2 : 1;

        if (totalCoins < coinsToDeduct) {
          GlobalFunctions.hideProgressDialog();
          AppSnackBar.showError(message: 'Not enough coins to join.');
          return;
        }
        final updatedCoins = totalCoins - coinsToDeduct;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'totalCoins': updatedCoins,
        });
      }

      if (hasReferral) {
        final referralQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: referralUsername)
            .limit(1)
            .get();

        if (referralQuery.docs.isNotEmpty) {
          final referralUserDoc = referralQuery.docs.first;
          final referralUserId = referralUserDoc.id;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(referralUserId)
              .update({
            'totalCoins': FieldValue.increment(1),
          });
        }
      }

      await docRef.update({
        '${lotteryKey.value}.users.$userId': userId,
        '${lotteryKey.value}.totalUsersCount': FieldValue.increment(1),
      });

      AppSnackBar.showSuccess(message: 'Successfully joined!');
      GlobalFunctions.hideProgressDialog();
      await checkPurchasedTicket();
      await userController.refreshUserData();
      await updateStreakValue();
      await userController.refreshUserData();
    } catch (e) {
      GlobalFunctions.hideProgressDialog();
      AppSnackBar.showError(message: 'Error joining: $e');
    } finally {
      // Reset loading state for specific lottery
      isLoadingLotteries[lotteryNumber - 1] = false;
    }
  }

  Future<void> updateStreakValue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userDocRef.get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final participationTimestamp = data['lastParticipationDate'];

    final now = DateTime.now();
    final todayAt7PM = DateTime(now.year, now.month, now.day, 19);

    final windowStart = now.isBefore(todayAt7PM)
        ? todayAt7PM.subtract(const Duration(days: 1))
        : todayAt7PM;

    final windowEnd = windowStart.add(const Duration(hours: 24));

    print('[Streak] NOW               : $now');
    print('[Streak] WINDOW START      : $windowStart');
    print('[Streak] WINDOW END        : $windowEnd');

    if (participationTimestamp != null && participationTimestamp is Timestamp) {
      final participationTime = participationTimestamp.toDate();
      print('[Streak] LAST PARTICIPATION: $participationTime');

      final inCurrentWindow = !participationTime.isBefore(windowStart) &&
          participationTime.isBefore(windowEnd);

      if (inCurrentWindow) {
        print(
            '[Streak] Already participated in current lottery window. Skipping.');
        return;
      }
    }

    print('[Streak] Updating streak +1 and timestamp.');
    await userDocRef.update({
      'streak': FieldValue.increment(1),
      'lastParticipationDate': Timestamp.fromDate(windowStart),
    });
  }

  checkPurchasedTicket() {
    int count = 10; // Start with 10 total tickets
    // Count how many lotteries the user has joined
    for (int i = 0; i < 10; i++) {
      if (hasJoinedLotteries[i]) count--;
    }
    totalTickets.value = count;
  }

  void showRewardedInterstitial(BuildContext context, int lotteryNumber) {
    // Validate lottery number
    if (lotteryNumber < 1 || lotteryNumber > 10) {
      AppSnackBar.showError(message: 'Invalid lottery number');
      return;
    }

    // Set loading state for specific lottery
    if (isAdLoadingLotteries[lotteryNumber - 1]) {
      log("Ads already loading for lottery $lotteryNumber, ignoring request");
      return;
    }
    isAdLoadingLotteries[lotteryNumber - 1] = true;

    adService.loadAndShowSequentialAds(
      context: context,
      onRewarded: (reward) {
        log("User earned ${reward.amount} ${reward.type}");
        log("lotterynumber $lotteryNumber");
        checkFromStorage(lotteryNumber, context);
      },
      onAllAdsFinished: () {
        // Reset loading state for specific lottery
        isAdLoadingLotteries[lotteryNumber - 1] = false;
        currentAdCountLotteries[lotteryNumber - 1] = 0;
        log("All ads finished for lottery $lotteryNumber");
      },
      onError: (err) {
        // Reset loading state for specific lottery
        isAdLoadingLotteries[lotteryNumber - 1] = false;
        currentAdCountLotteries[lotteryNumber - 1] = 0;
        print("Ad error: $err");
        AppSnackBar.showError(message: "Ad failed to load: $err");
      },
    );

    // Start a timer to update ad counts
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (isAdLoadingLotteries[lotteryNumber - 1]) {
        currentAdCountLotteries[lotteryNumber - 1] = adService.currentAdCount;
      } else {
        timer.cancel();
      }
    });
  }

  checkFromStorage(int lotteryNumber, BuildContext context) async {
    // Validate lottery number
    if (lotteryNumber < 1 || lotteryNumber > 10) {
      AppSnackBar.showError(message: 'Invalid lottery number');
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    lotteryKey.value = 'lottery_$lotteryNumber';
    joinLottery(context, true, lotteryNumber: lotteryNumber);
  }

  Future<void> updateStreakForCurrentUser() async {
    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDocRef = firestore.collection('users').doc(uid);
    final userDoc = await userDocRef.get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;
    final participationTimestamp = data['lastParticipationDate'];

    if (participationTimestamp == null || participationTimestamp is! Timestamp)
      return;

    final participationTime = participationTimestamp.toDate();
    final now = DateTime.now();

    final expired =
        now.isAfter(participationTime.add(const Duration(hours: 48)));

    log('[Streak] Now: $now');
    log('[Streak] Last valid window: $participationTime → ${participationTime.add(Duration(hours: 24))}');
    log('[Streak] Expired? $expired');

    if (expired) {
      print('[Streak] Missed the window. Resetting streak.');
      await userDocRef.update({
        'streak': 0,
      });
    } else {
      print('[Streak] Still inside valid window. Streak continues.');
    }
  }

  void listenToLotteryCountChanges({bool isFrom7PM = false}) {
    FirebaseFirestore.instance.collection('lotteryCount').snapshots().listen(
      (QuerySnapshot snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            log("🎯 Lottery count changed");

            firestore.collection('lotteries').get().then((snap) {
              showLotteryWinnerAnnouncement(snap, isFrom7PM: isFrom7PM);
            }).catchError((error) {
              print('❌ Error fetching lotteries: $error');
            });

            break;
          }
        }
      },
      onError: (error) {
        print('❌ Error listening to lotteryCount: $error');
      },
    );
  }
}