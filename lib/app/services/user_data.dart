import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../utils/snackbars.dart';
import 'notification_service.dart';

class UserController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  var userData = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  // Method to fetch user data from Firestore
  Future<void> fetchUserData() async {
    String? userId = auth.currentUser?.uid;
    if (userId == null) {
      AppSnackBar.showError(message: 'User not logged in');
      return;
    }

    try {
      // Update user online status and FCM token
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({
        "isOnline": true,
        "lastActive": DateTime.now(),
        "fcmToken": NotificationService.instance.fcmToken
      });

      // Fetch the user data from Firestore
      assignValueToModel(userId);
    } catch (e) {
      print("Error fetching user data: $e");
      AppSnackBar.showError(message: 'Error fetching user data: $e');
    }
  }

  assignValueToModel(String userId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists) {
      userData.value =
          UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
    } else {
      AppSnackBar.showError(message: 'User data not found');
    }
  }

  // Optional: Method to refresh user data (e.g., after an update)
  Future<void> refreshUserData() async {
    await fetchUserData();
  }
}
