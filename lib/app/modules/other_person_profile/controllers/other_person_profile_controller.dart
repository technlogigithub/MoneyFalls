import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottery/app/models/user_model.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/services/user_data.dart';
import 'package:lottery/app/utils/constants.dart';
import '../../../services/notification_service.dart';
import '../../../utils/snackbars.dart';
import '../../bottom_bar/controllers/bottom_bar_controller.dart';
import '../../login/controllers/login_signup_controller.dart';
import '../../winners/views/winners_view.dart';

class OtherPersonProfileController extends GetxController {
  final count = 0.obs;

  // Reactive UserModel to store the target user's data
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // late SplashController splashController;
  RxInt streak = 0.obs;
  RxInt totalWins = 0.obs;
  RxMap data = {}.obs;
  RxInt totalFollowers = 0.obs;
  RxInt downLineWinnersCount = 0.obs;
  RxInt followingCount = 0.obs; // Placeholder for following count
  RxString otherUserid = ''.obs;
  RxString referralName = ''.obs;
  RxString currentUserName = ''.obs;

  @override
  void onInit() {
    super.onInit();

    getArguments();
  }

  getArguments() async {
    print("otherUserid.....");
    otherUserid.value = Get.arguments['userID'];
    print("otherUserid ${otherUserid.value}");
    await assignData(uid: otherUserid.value);
  }

  // Assign data based on the provided uid
  Future<void> assignData({String? uid}) async {
    print('Fetching data for uid: $uid');
    await fetchCurrentUserData(uid: uid); // Fetch data for the specified uid
    // checkAndUpdateStreak(uid: uid);
    await fetchReferralData(uid: uid);
  }

  // Fetch user data from Firestore based on uid
  Future<void> fetchCurrentUserData({String? uid}) async {
    try {
      String targetUid = uid ?? '';
      if (targetUid.isEmpty) {
        Get.snackbar('Error', 'Invalid user ID');
        currentUser.value = null;
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(targetUid).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        currentUser.value = UserModel.fromFirestore(userData);
        streak.value = currentUser.value?.streak ?? 0;
        log("currentUser ${currentUser.value?.toMap()}");

        referralName.value = userData["referralUsername"];
        currentUserName.value = userController.userData.value!.username;

      } else {
        currentUser.value = null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      currentUser.value = null;
    }
  }

  // Check and update streak for the specified user
  Future<void> checkAndUpdateStreak({String? uid}) async {
    String targetUid = uid ?? '';
    if (targetUid.isEmpty) return;

    final userDocRef = _firestore.collection('users').doc(targetUid);
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    try {
      final userDoc = await userDocRef.get();
      int currentStreak = 0;
      String? lastParticipationDate;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        currentStreak = userData['streak'] ?? 0;
        lastParticipationDate = userData['lastParticipationDate'] as String?;
      }

      final todayDocRef = _firestore.collection('lotteries').doc(todayStr);
      final todayDoc = await todayDocRef.get();
      bool participatedToday = false;

      if (todayDoc.exists) {
        final data = todayDoc.data() as Map<String, dynamic>;
        final lottery1Users =
            (data['lottery_1']?['users'] as Map<String, dynamic>?) ?? {};
        final lottery2Users =
            (data['lottery_2']?['users'] as Map<String, dynamic>?) ?? {};
        participatedToday = lottery1Users.containsKey(targetUid) ||
            lottery2Users.containsKey(targetUid);
      }

      final yesterdayDocRef =
          _firestore.collection('lotteries').doc(yesterdayStr);
      final yesterdayDoc = await yesterdayDocRef.get();
      bool participatedYesterday = false;

      if (yesterdayDoc.exists) {
        final data = yesterdayDoc.data() as Map<String, dynamic>;
        final lottery1Users =
            (data['lottery_1']?['users'] as Map<String, dynamic>?) ?? {};
        final lottery2Users =
            (data['lottery_2']?['users'] as Map<String, dynamic>?) ?? {};
        participatedYesterday = lottery1Users.containsKey(targetUid) ||
            lottery2Users.containsKey(targetUid);
      }

      if (participatedToday) {
        if (lastParticipationDate == yesterdayStr && participatedYesterday) {
          currentStreak++;
        } else if (lastParticipationDate != todayStr) {
          currentStreak = 1;
        }
        await userDocRef.set({
          'streak': currentStreak,
          'lastParticipationDate': todayStr,
        }, SetOptions(merge: true));
      } else if (lastParticipationDate != todayStr &&
          lastParticipationDate != yesterdayStr) {
        currentStreak = 0;
        await userDocRef.set({
          'streak': 0,
          'lastParticipationDate': null,
        }, SetOptions(merge: true));
      }

      streak.value = currentStreak;
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Fetch referral data and calculate followers and downline winners
  Future<void> fetchReferralData({String? uid}) async {
    String userName = currentUser.value?.username ?? '';
    data.value = await fetchReferrals(userName: userName);
    print("fetchReferrals: "+data.value.toString());
    totalFollowers.value = (data['level1']?.length ?? 0) +
        (data['level2']?.length ?? 0) +
        (data['level3']?.length ?? 0) +
        (data['level4']?.length ?? 0) +
        (data['level5']?.length ?? 0);
    print('this is totalFollowers $totalFollowers');
    downLineWinnersCount.value = (data['level1']?.isNotEmpty == true
            ? (data['level1'][0]['totalWinCount'] ?? 0)
            : 0) +
        (data['level2']?.isNotEmpty == true
            ? (data['level2'][0]['totalWinCount'] ?? 0)
            : 0) +
        (data['level3']?.isNotEmpty == true
            ? (data['level3'][0]['totalWinCount'] ?? 0)
            : 0) +
        (data['level4']?.isNotEmpty == true
            ? (data['level4'][0]['totalWinCount'] ?? 0)
            : 0) +
        (data['level5']?.isNotEmpty == true
            ? (data['level5'][0]['totalWinCount'] ?? 0)
            : 0);
    print("DownLineWinnerCount ${downLineWinnersCount.value}");
  }

  Future<void> getReferralUserAndPrintName(String referralUsername) async {
    print('Fetching user with referralUsername: $referralUsername');
    try {
      // Query the 'users' collection to find a user with the given referralUsername
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: referralUsername)
          .limit(1)
          .get();

      // Check if a user with the given referralUsername exists
      if (querySnapshot.docs.isEmpty) {
        print('No user found with the referralUsername "$referralUsername".');
        return;
      }

      // Get the user data from the first (and only) document
      var userDoc = querySnapshot.docs.first;
      var userData = userDoc.data() as Map<String, dynamic>;

      // Extract and print the user's name (prefer 'name' field, fallback to 'username')
      String name = userData['name'] ?? userData['username'] ?? 'Unknown';
      print('Fetched user name: $name');
    } catch (e) {
      print('Error fetching referral user: $e');
    }
  }

  // Generate chat room ID
  static String generateChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

// Create a chat
  Future<void> createChat(String chatRoomId, String currentUserId,
      String otherUserId, Map<String, dynamic> otherUserData) async {
    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (!currentUserDoc.exists) {
        throw Exception('Current user data not found');
      }
      Map<String, dynamic> currentUserData =
          currentUserDoc.data() as Map<String, dynamic>;

      String? currentUserFcmToken = NotificationService.instance.fcmToken;
      String? otherUserFcmToken = otherUserData['fcmToken'];

      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .get();

      // if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
        'lastMessage': 'Chat started',
        'lastOnline': otherUserData['isOnline'] == true
            ? FieldValue.serverTimestamp()
            : null,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserData['name'] ?? 'Unknown',
          otherUserId: otherUserData['name'] ?? 'Unknown',
        },
        'participantImages': {
          currentUserId: (Get.find<UserController>()
                      .userData
                      .value
                      ?.profileImage
                      .trim()
                      .isNotEmpty ??
                  false)
              ? Get.find<UserController>().userData.value?.profileImage
              : AssetsConstant.onlineLogo,
          otherUserId:
              (otherUserData['profile_image']?.toString().trim().isNotEmpty ??
                      false)
                  ? otherUserData['profile_image']
                  : AssetsConstant.onlineLogo,
        },
        'participantFcmTokens': {
          currentUserId: currentUserFcmToken ?? '',
          otherUserId: otherUserFcmToken ?? '',
        },
        'lastMessageSeenBy': [currentUserId],
      });

      // Update users' chatIds arrays
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'chatIds': FieldValue.arrayUnion([chatRoomId]),
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .update({
        'chatIds': FieldValue.arrayUnion([chatRoomId]),
      });
      // }
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Initiate a chat with the other user
  Future<void> initiateChat() async {
    String currentUserId = _auth.currentUser!.uid;
    String chatRoomId = generateChatRoomId(currentUserId, otherUserid.value);

// Fetch other user's data for createChat
    DocumentSnapshot otherUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserid.value)
        .get();
    if (!otherUserDoc.exists) {
      AppSnackBar.showError(message: 'Other user data not found');
      return;
    }
    Map<String, dynamic> otherUserData =
        otherUserDoc.data() as Map<String, dynamic>;

    print('check other userProfile ${otherUserData['profile_image']}');

// Create or update chat
    await createChat(
        chatRoomId, currentUserId, otherUserid.value, otherUserData);

// Navigate to chat screen
    Get.find<BottomBarController>().currentIndex.value =
        1; // Switch to chat tab
    Get.toNamed(Routes.CHAT_SCREEN, arguments: {
      'chatRoomId': chatRoomId,
      'userName': otherUserData['name'] ?? 'Unknown',
      'userImage': otherUserData['profile_image'] ?? AssetsConstant.onlineLogo,
      'userStatus': otherUserData['isOnline'] == true ? 'online' : 'offline',
      'fcmToken': otherUserData['fcmToken'] ?? '',
      'otherUserid': otherUserid.value,
    });
  }
}
