import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:lottery/app/services/user_data.dart';

class SettingsController extends GetxController {
  //TODO: Implement SettingsController
  UserController userController = Get.find<UserController>();
  
  // Map to store auto-add coin states for lotteries 1-10
  final RxMap<int, bool> autoAddCoins = <int, bool>{}.obs;

  final count = 0.obs;

  @override
  void onInit() {
    super.onInit();
    assignData();
  }

  assignData() async {
    try {
      final userData = userController.userData.value;
      if (userData == null) {
        // If userData is null, initialize all to false
        for (int i = 1; i <= 10; i++) {
          autoAddCoins[i] = false;
        }
        return;
      }

      // Initialize states for lotteries 1-10
      for (int i = 1; i <= 10; i++) {
        autoAddCoins[i] = getUserAutoLotteryValue(i);
      }
    } catch (e) {
      // Handle any errors gracefully
      print('Error in assignData: $e');
      for (int i = 1; i <= 10; i++) {
        autoAddCoins[i] = false;
      }
    }
  }

  bool getUserAutoLotteryValue(int lotteryNumber) {
    final userData = userController.userData.value;
    if (userData == null) return false;
    
    // Get the value from user data based on lottery number
    switch (lotteryNumber) {
      case 1:
        return userData.automaticPurchaseLottery1 ?? false;
      case 2:
        return userData.automaticPurchaseLottery2 ?? false;
      case 3:
        return userData.automaticPurchaseLottery3 ?? false;
      case 4:
        return userData.automaticPurchaseLottery4 ?? false;
      case 5:
        return userData.automaticPurchaseLottery5 ?? false;
      case 6:
        return userData.automaticPurchaseLottery6 ?? false;
      case 7:
        return userData.automaticPurchaseLottery7 ?? false;
      case 8:
        return userData.automaticPurchaseLottery8 ?? false;
      case 9:
        return userData.automaticPurchaseLottery9 ?? false;
      case 10:
        return userData.automaticPurchaseLottery10 ?? false;
      default:
        return false;
    }
  }

  bool getAutoAddCoinValue(int lotteryNumber) {
    return autoAddCoins[lotteryNumber] ?? false;
  }

  void toggleAutoAddCoin(int lotteryNumber) {
    try {
      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return;
      }

      // Toggle the value
      autoAddCoins[lotteryNumber] = !getAutoAddCoinValue(lotteryNumber);
      
      // Update in Firebase with error handling
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'automaticPurchaseLottery$lotteryNumber': autoAddCoins[lotteryNumber],
      }).catchError((error) {
        print('Error updating Firebase: $error');
        // Revert the change if Firebase update fails
        autoAddCoins[lotteryNumber] = !autoAddCoins[lotteryNumber]!;
      });
      
      // Refresh user data
      userController.refreshUserData();
    } catch (e) {
      print('Error in toggleAutoAddCoin: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Listen to user data changes and update local state
    ever(userController.userData, (userData) {
      if (userData != null) {
        assignData();
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}