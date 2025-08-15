import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/snackbars.dart';

class ForgetPasswordController extends GetxController {
  final count = 0.obs;
  final showHidePassword = true.obs;
  final showHideConfirmPassword = true.obs;
  TextEditingController emailController = TextEditingController();
  RxBool isLoading = false.obs;

  void increment() => count.value++;

  void onOffToggle() {}

  // Email validation method
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> forgotPassword() async {
    String email = emailController.text.toString().trim();
    
    // Validate email before sending
    if (email.isEmpty) {
      AppSnackBar.showError(message: 'Please enter your email address');
      return;
    }

    if (!isValidEmail(email)) {
      AppSnackBar.showError(message: 'Please enter a valid email address');
      return;
    }

    try {
      isLoading.value = true;
      
      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // Success message
      AppSnackBar.showSuccess(
        message: 'Password reset email sent to $email. Please check your inbox and spam folder.'
      );
      
      // Clear the email field after successful send
      emailController.clear();
      
      // Navigate back after success (optional)
      Get.back();
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Something went wrong';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Error: ${e.message ?? 'Unknown error occurred'}';
      }
      
      AppSnackBar.showError(message: errorMessage);
      
    } catch (e) {
      // Handle any other unexpected errors
      AppSnackBar.showError(message: 'An unexpected error occurred. Please try again.');
      print('Forgot password error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}