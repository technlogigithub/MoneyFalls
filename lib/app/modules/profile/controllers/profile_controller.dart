import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottery/app/modules/bottom_bar/controllers/bottom_bar_controller.dart';
import 'package:lottery/app/modules/other_person_profile/controllers/other_person_profile_controller.dart';
import 'package:lottery/app/modules/winners/views/winners_view.dart';
import 'package:lottery/app/services/user_data.dart';
import 'package:lottery/app/utils/constants.dart';
import '../../../models/user_model.dart';
import '../../../utils/image_picker.dart';
import '../../../utils/snackbars.dart';
import '../../login/controllers/login_signup_controller.dart';

class ProfileController extends GetxController {
  final count = 0.obs;
  // late var countAtIndex4=0;

  // Reactive UserModel to store current user data
  // Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Add Firebase Storage

  UserController splashController = Get.find<UserController>();
  BottomBarController bottomBarController = Get.find<BottomBarController>();
  // OtherPersonProfileController otherController = Get.put(OtherPersonProfileController());
  // UserController userController = Get.find<UserController>();

  // Reactive UserModel to store the target user's data
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  RxInt streak = 0.obs; // Observable for the streak
  RxInt totalWins = 0.obs;
  RxMap data = {}.obs;
  RxInt totalFollowers = 0.obs;
  RxInt downLineWinnersCount = 0.obs;
  // RxInt downLineWinnersCountNew = 0.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final countryCodeController = TextEditingController();
  final bankAccountController = TextEditingController();
  final ifscController = TextEditingController();
  final vpaController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final amountController = TextEditingController();

  static const String _baseUrl = 'https://sandbox.cashfree.com';
  // Replace with your actual Client ID and Secret from Cashfree Dashboard
  static const String _clientId = 'CF10532465D1BCLDJ17FCC73F0C3UG';
  static const String _clientSecret =
      'cfsk_ma_test_d87f17e0e2a05ffc2493e1c7a1e59655_bbe451be';
  // API version as per the provided cURL
  static const String _apiVersion = '2024-01-01';
  RxString otherUserid = ''.obs;
  RxBool isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    // _fetchWinners();
    assignData();
  }

  assignData() async {
    isLoading.value = true;
    await clearProfileData();
    await fetchCurrentUserData(); // Fetch user data when controller initializes
    await fetchReferralData();
    isLoading.value = false;
  }

  // Function to fetch current user data from Firestore
  Future<void> fetchCurrentUserData() async {
    await splashController.refreshUserData();
  }

  fetchReferralData() async {
    String userName = splashController.userData.value?.username ?? '';
    data.value = await fetchReferrals(userName: userName);
    totalFollowers.value = (data['level1']?.length ?? 0) +
        (data['level2']?.length ?? 0) +
        (data['level3']?.length ?? 0) +
        (data['level4']?.length ?? 0) +
        (data['level5']?.length ?? 0);

    downLineWinnersCount.value = (data['level1']?.isNotEmpty == true
        ? data['level1'][0]['totalWinCount']
        : 0) +
        (data['level2']?.isNotEmpty == true
            ? data['level2'][0]['totalWinCount']
            : 0) +
        (data['level3']?.isNotEmpty == true
            ? data['level3'][0]['totalWinCount']
            : 0) +
        (data['level4']?.isNotEmpty == true
            ? data['level4'][0]['totalWinCount']
            : 0) +
        (data['level5']?.isNotEmpty == true
            ? data['level5'][0]['totalWinCount']
            : 0);
    print("TotalReferalLength ${downLineWinnersCount.value}");
  }


  // Method to pick an image, upload it, and update the user's profile_image in Firestore

  Future<void> pickAndUploadProfilePicture() async {
    try {
      // isLoading.value = true;

      // Pick image using ImagePickerUtil
      final XFile? picker = await ImagePickerUtil.pickImage();
      print('filepath ${picker?.path}');

      if (picker != null) {
        // Upload the image to Firebase Storage
        String? imageUrl = await uploadImage(picker);
        print('We got the image url $imageUrl');

        if (imageUrl != null) {
          // Update the profile_image field in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .update({
            'profile_image': imageUrl, // Only update the profile_image field
          });

          AppSnackBar.showSuccess(
              message: 'Profile picture updated successfully!');
          splashController.refreshUserData();
          fetchCurrentUserData();
        } else {
          AppSnackBar.showError(message: 'Failed to upload image');
        }
      } else {
        AppSnackBar.showError(message: 'No image selected');
      }
    } catch (e) {
      print("Error updating profile picture: $e");
      AppSnackBar.showError(message: 'Error updating profile picture: $e');
    } finally {
      // isLoading.value = false;
    }
  }

  // Upload image to Firebase Storage and return URL
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      String fileName =
          'profile/${FirebaseAuth.instance.currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      await ref.putFile(File(imageFile.path));
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  updateImage(String imageUrl) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'profile_image': imageUrl, // Only update the profile_image field
    });
  }

// Function to check and update the user's streak
  Future<void> checkAndUpdateStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[Streak] No authenticated user.');
      return;
    }

    final userId = user.uid;
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    final now = DateTime.now(); // IST
    final todayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 1)));
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 2)));

    print('[Streak] Checking for user: $userId');
    print('[Streak] Today: $todayStr, Yesterday: $yesterdayStr');

    try {
      // Helper function to check participation
      Future<bool> didUserParticipate(String dateStr) async {
        final docRef =
            FirebaseFirestore.instance.collection('lotteries').doc(dateStr);
        final doc = await docRef.get();
        if (!doc.exists) {
          print('[Streak] No lottery data for $dateStr');
          return false;
        }
        final data = doc.data() as Map<String, dynamic>;
        final lottery1Users =
            (data['lottery_1']?['users'] as Map<String, dynamic>?) ?? {};
        final lottery2Users =
            (data['lottery_2']?['users'] as Map<String, dynamic>?) ?? {};
        final participated = lottery1Users.containsKey(userId) ||
            lottery2Users.containsKey(userId);
        print('[Streak] Participation on $dateStr: $participated');
        return participated;
      }

      final userDoc = await userDocRef.get();
      int currentStreak = 0;
      String? lastParticipationDate;

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        currentStreak = userData['streak'] as int? ?? 0;
        lastParticipationDate = userData['lastParticipationDate'] as String?;
        print(
            '[Streak] Loaded data - streak: $currentStreak, lastDate: $lastParticipationDate');
      } else {
        print('[Streak] User doc doesn’t exist. Initializing...');
        await userDocRef.set({
          'streak': 0,
          'lastParticipationDate': null,
        }, SetOptions(merge: true));
      }

      final participatedToday = await didUserParticipate(todayStr);
      final participatedYesterday = await didUserParticipate(yesterdayStr);

      Map<String, dynamic> updateData = {};

      if (participatedToday) {
        if (lastParticipationDate == yesterdayStr && participatedYesterday) {
          currentStreak++; // Continue streak
          print('[Streak] Continuing streak. New streak: $currentStreak');
          updateData = {
            'streak': currentStreak,
            'lastParticipationDate': todayStr,
          };
        } else if (lastParticipationDate != todayStr) {
          currentStreak = 1; // Start new streak
          print('[Streak] Starting new streak at 1');
          updateData = {
            'streak': currentStreak,
            'lastParticipationDate': todayStr,
          };
        } else if (lastParticipationDate == todayStr && currentStreak == 0) {
          // Fix missed streak update
          print('[Streak] Fixing missed streak update for today.');
          currentStreak = participatedYesterday ? 2 : 1;
          updateData = {
            'streak': currentStreak,
            'lastParticipationDate': todayStr,
          };
        } else {
          print('[Streak] Already updated today. No fix needed.');
        }
      } else if (lastParticipationDate != todayStr &&
          lastParticipationDate != yesterdayStr) {
        currentStreak = 0; // Reset streak
        print('[Streak] Missed participation. Resetting streak.');
        updateData = {
          'streak': 0,
          'lastParticipationDate': null,
        };
      }

      if (updateData.isNotEmpty) {
        print('[Streak] Writing update to Firestore: $updateData');
        await userDocRef.set(updateData, SetOptions(merge: true));
        splashController.refreshUserData();
        streak.value = currentStreak;
        print('[Streak] Observable updated to: ${streak.value}');
      } else {
        print('[Streak] No updates needed.');
      }
    } catch (e) {
      print('[Streak] Error updating streak: $e');
    }
  }

  // Function to count how many lotteries the current user has won
  Future<void> countUserWins() async {
    final user = _auth.currentUser;
    if (user == null) return; // Exit if user is not authenticated

    final userId = user.uid;
    int winCount = 0;

    try {
      // Query all documents in the lotteries collection
      final lotteryDocs = await _firestore.collection('lotteries').get();

      for (var doc in lotteryDocs.docs) {
        final data = doc.data();
        final lottery1Data = data['lottery_1'] as Map<String, dynamic>? ?? {};
        final lottery2Data = data['lottery_2'] as Map<String, dynamic>? ?? {};

        // Check if the user is the winner in lottery_1
        final winnerId1 = lottery1Data['winnerID'] as String? ?? '';
        if (winnerId1 == userId) {
          winCount++;
        }

        // Check if the user is the winner in lottery_2
        final winnerId2 = lottery2Data['winnerID'] as String? ?? '';
        if (winnerId2 == userId) {
          winCount++;
        }
      }

      // Update the observable win count
      totalWins.value = winCount;

      // Optionally, store the win count in Firestore
      await _firestore.collection('users').doc(userId).set({
        'totalWins': winCount,
      }, SetOptions(merge: true));
      print('Total Wins $totalWins');
    } catch (e) {
      print('Error counting wins: $e');
    }
  }

  // Function to fetch a user by referralUsername and print their name
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

  // Function to add a beneficiary
  Future<bool> addBeneficiary({
    required String beneficiaryId,
    required String beneficiaryName,
    required String beneficiaryEmail,
    required String beneficiaryPhone,
    // required String beneficiaryCountryCode,
    // required String bankAccountNumber,
    // required String bankIfsc,
    required String vpa,
    // required String beneficiaryAddress,
    // required String beneficiaryCity,
    // required String beneficiaryState,
    // required String beneficiaryPostalCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://sandbox.cashfree.com/payout/beneficiary'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': _apiVersion,
          'x-client-id': _clientId,
          'x-client-secret': _clientSecret,
        },
        body: jsonEncode({
          'beneficiary_id': beneficiaryId,
          'beneficiary_name': beneficiaryName,
          'beneficiary_instrument_details': {
            // 'bank_account_number': bankAccountNumber,
            // 'bank_ifsc': bankIfsc,
            'vpa': vpa,
          },
          'beneficiary_contact_details': {
            'beneficiary_email': beneficiaryEmail,
            'beneficiary_phone': beneficiaryPhone,
            // 'beneficiary_country_code': beneficiaryCountryCode,
            'beneficiary_address': 'India Delhi Account',
            // 'beneficiary_city': beneficiaryCity,
            // 'beneficiary_state': beneficiaryState,
            // 'beneficiary_postal_code': beneficiaryPostalCode,
          },
        }),
      );
      print('Raw response: ${response.body}');
      print('Raw response: ${response.statusCode}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("response after adding beneficary ${data}");
        // if (data['status'] == 'SUCCESS') {
        AppSnackBar.showSuccess(message: 'Beneficiary added successfully');

        /// Upload to Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final Map<String, dynamic> beneficiaryData = {
            'beneficiaryId': beneficiaryId,
            'beneficiaryName': beneficiaryName,
            'beneficiaryEmail': beneficiaryEmail,
            // 'beneficiaryPhone': beneficiaryPhone,
            // 'beneficiaryCountryCode': beneficiaryCountryCode,
            // 'bankAccountNumber': bankAccountNumber,
            // 'bankIfsc': bankIfsc,
            'vpa': vpa,
            // 'beneficiaryAddress': beneficiaryAddress,
            // 'beneficiaryCity': beneficiaryCity,
            // 'beneficiaryState': beneficiaryState,
            // 'beneficiaryPostalCode': beneficiaryPostalCode,
            'timestamp': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'beneficiary': beneficiaryData});
        }

        splashController.refreshUserData();
        assignData();

        return true;
      } else {
        print('error adding account ${response.body}');
        AppSnackBar.showError(
            message: 'Error adding beneficiary: ${response.body}');
        return false;
      }
    } catch (e) {
      print('something went wrong $e');
      AppSnackBar.showError(message: 'Error adding beneficiary: $e');
      return false;
    }
  }
  //
  // Future<List<Map<String, dynamic>>> _fetchWinners() async {
  //   try {
  //     // Step 1: Fetch all documents from the lotteries collection
  //     final lotteriesSnapshot =
  //     await FirebaseFirestore.instance.collection('lotteries').get();
  //
  //     // Step 2: Extract winner IDs, totalUserCount, and createdAt field
  //     final winnerMap = <String,
  //         List<Map<String, dynamic>>>{}; // Store a list of wins per winnerId
  //     for (var dateDoc in lotteriesSnapshot.docs) {
  //       final lotteryData = dateDoc.data();
  //       final lottery1Map = lotteryData['lottery_1'] as Map<String, dynamic>?;
  //
  //       print('this is lottery 1 Map ${lottery1Map}');
  //
  //       final winnerId = lottery1Map?['winnerID'] as String?;
  //       print('the winner id is $winnerId');
  //       final totalUserCount =
  //           lottery1Map?['totalUserCount'] ?? lottery1Map?['totalUsersCount'];
  //       final createdAt = lottery1Map?['createdAt'] as Timestamp?;
  //
  //       if (winnerId != null &&
  //           winnerId.isNotEmpty &&
  //           totalUserCount != null &&
  //           totalUserCount is num) {
  //         winnerMap.putIfAbsent(winnerId, () => []);
  //         winnerMap[winnerId]!.add({
  //           'totalUserCount': totalUserCount,
  //           'createdAt': createdAt,
  //         });
  //       }
  //     }
  //
  //     // final currentUserName = userController.userData.value!.username; // assuming this exists
  //     // print('currentUserName: '+currentUserName);
  //
  //     // Step 3: Fetch user data for all winner IDs in a single batch
  //     final winnersData = <Map<String, dynamic>>[];
  //     if (winnerMap.isNotEmpty) {
  //       final idChunks = winnerMap.keys
  //           .toList()
  //           .asMap()
  //           .entries
  //           .groupBy((entry) => entry.key ~/ 10);
  //       for (var chunk in idChunks.values) {
  //         final chunkIds = chunk.map((e) => e.value).toList();
  //         final usersSnapshot = await FirebaseFirestore.instance
  //             .collection('users')
  //             .where(FieldPath.documentId, whereIn: chunkIds)
  //             .get();
  //
  //         // for(var data in chunk){
  //         //   controller.fetchCurrentUserData(data);
  //         // }
  //
  //         for (var userDoc in usersSnapshot.docs) {
  //           // Get the referralName of the winner
  //           final referralName = userDoc.data()['referralUsername'];
  //           print('referralName: '+referralName.toString());
  //           final userName = userDoc.data()['username'];
  //           print('userName: '+userName.toString());
  //           final winnerId = userDoc.id;
  //
  //           for (var win in winnerMap[winnerId]!) {
  //             final amount = win['totalUserCount'] ?? 0;
  //             final createdAt = win['createdAt'];
  //
  //             // Added winner count
  //             final isNotCurrentUser = winnerId != currentUserId;
  //             print('isNotCurrentUser: '+isNotCurrentUser.toString());
  //             final isReferredByCurrentUser =
  //                 // referralName != null && referralName == currentUserName;
  //             print('isReferredByCurrentUser: '+isReferredByCurrentUser.toString());
  //             if (isNotCurrentUser && isReferredByCurrentUser) {
  //               winnersCountList.add({
  //                 'winner_id': winnerId,
  //                 'amount': amount,
  //                 'createdAt': createdAt,
  //               });
  //             }
  //
  //             // downLineWinnersCountNew.value = winnersCountList.length;
  //
  //             print('winnerCountList: '+winnersCountList.length.toString());
  //
  //             winnersData.add({
  //               'name': userDoc.data()['name'] ?? 'Unknown',
  //               'image': userDoc.data()['profile_image'] ??
  //                   'assets/images/default_user.png',
  //               'last_message': 'Won $amount',
  //               'winner_id': userDoc.data()['uid'] ?? '',
  //               'createdAt':
  //               createdAt != null ? createdAt.toDate().toString() : null,
  //             });
  //           }
  //         }
  //       }
  //     }
  //
  //     // Step 4: Sort winnersData by createdAt in descending order
  //     winnersData.sort((a, b) {
  //       final dateA = a['createdAt'] != null
  //           ? DateTime.parse(a['createdAt'])
  //           : DateTime(0);
  //       final dateB = b['createdAt'] != null
  //           ? DateTime.parse(b['createdAt'])
  //           : DateTime(0);
  //       return dateB.compareTo(dateA); // Descending order (newest first)
  //     });
  //
  //     return winnersData;
  //   } catch (e) {
  //     print('Error fetching winners: $e');
  //     return [];
  //   }
  // }

  Future<void> clearProfileData() async {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    countryCodeController.clear();
    bankAccountController.clear();
    ifscController.clear();
    vpaController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    postalCodeController.clear();
    amountController.clear();

    streak.value = 0;
    totalWins.value = 0;
    data.value = {};
    totalFollowers.value = 0;
    downLineWinnersCount.value = 0;
    totalFollowers.value = 0;
  }
}
