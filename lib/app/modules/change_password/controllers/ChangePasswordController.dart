import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/snackbars.dart';

class ChangePasswordController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;

  // Controllers for current password, new password, and confirm new password
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  RxBool isLoading = false.obs;

  // Function to change password
  Future<void> changePassword() async {
    isLoading.value = true;

    try {
      // Get the current user
      User? user = auth.currentUser;
      if (user == null) {
        AppSnackBar.showError(message: 'No user logged in.');
        isLoading.value = false;
        return;
      }

      String currentPassword = currentPasswordController.text.trim();
      String newPassword = newPasswordController.text.trim();
      String confirmPassword = confirmPasswordController.text.trim();

      // Check if new password matches the confirmation password
      if (newPassword != confirmPassword) {
        AppSnackBar.showError(message: 'New password and confirm password do not match.');
        isLoading.value = false;
        return;
      }

      // Ensure new password is at least 6 characters long
      if (newPassword.length < 6) {
        AppSnackBar.showError(message: 'New password must be at least 6 characters.');
        isLoading.value = false;
        return;
      }

      // Reauthenticate user before updating password
      AuthCredential credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credentials);

      // Update password
      await user.updatePassword(newPassword);
      await user.reload(); // Reload user to apply the new password

      // Show success message
      AppSnackBar.showSuccess(message: 'Password changed successfully!');
      isLoading.value = false;

      // Optionally, log the user out or navigate to the login screen
      // auth.signOut();
      // Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      isLoading.value = false;
      AppSnackBar.showError(message: 'Failed to change password. Please try again.');
      print('Error: $e');
    }
  }
}
