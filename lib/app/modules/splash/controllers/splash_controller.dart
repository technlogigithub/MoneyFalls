import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/user_data.dart';

class SplashController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    checkUserAlreadyLogin();
  }

  Future<void> checkUserAlreadyLogin() async {
    await Future.delayed(Duration(seconds: 3)); // Reduced from 5 to 3 seconds
    
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // Reload user to get the latest verification status
      await currentUser.reload();
      currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && currentUser.emailVerified) {
        // User is logged in and email is verified
        try {
          // Fetch user data using UserController
          await Get.find<UserController>().fetchUserData();
          Get.offAllNamed(Routes.BOTTOM_BAR);
        } catch (e) {
          // If there's an error fetching user data, go to login
          print('Error fetching user data: $e');
          Get.offAllNamed(Routes.LOGIN_SIGNUP);
        }
      } else {
        // User is logged in but email is not verified
        // You can create a separate route for email verification
        // For now, redirecting to login/signup
        Get.offAllNamed(Routes.LOGIN_SIGNUP);
        
        // Optional: Show a message about email verification
        Get.snackbar(
          'Email Verification Required',
          'Please verify your email address to continue',
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3),
        );
      }
    } else {
      // No user is logged in
      Get.offAllNamed(Routes.LOGIN_SIGNUP);
    }
  }
  
  // Optional: Method to send verification email
  Future<void> sendEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        Get.snackbar(
          'Verification Email Sent',
          'Please check your email and verify your account',
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3),
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to send verification email: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3),
        );
      }
    }
  }
  
  // Optional: Method to manually check verification status
  Future<void> checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      
      if (user != null && user.emailVerified) {
        // Email is now verified, proceed to main app
        try {
          await Get.find<UserController>().fetchUserData();
          Get.offAllNamed(Routes.BOTTOM_BAR);
        } catch (e) {
          print('Error fetching user data: $e');
        }
      } else {
        Get.snackbar(
          'Email Not Verified',
          'Please verify your email address first',
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3),
        );
      }
    }
  }
}