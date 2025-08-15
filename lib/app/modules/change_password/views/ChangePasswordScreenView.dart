import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/global_extension.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/snackbars.dart';
import '../../../utils/common_widget.dart';
import '../../../utils/constants.dart';
import '../../../utils/my_text.dart';

class ChangePasswordScreenView extends StatefulWidget {
  @override
  _ChangePasswordScreenViewState createState() =>
      _ChangePasswordScreenViewState();
}

class _ChangePasswordScreenViewState extends State<ChangePasswordScreenView> {
  FirebaseAuth auth = FirebaseAuth.instance;

  // Text controllers for current and new passwords
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  var isLoading = false.obs;

  // Change password function
  Future<void> changePassword() async {
    // Get the current user
    User? user = auth.currentUser;

    if (user == null) {
      AppSnackBar.showError(message: 'No user logged in.');
      return;
    }

    String currentPassword = currentPasswordController.text.trim();
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      AppSnackBar.showError(message: 'New password and confirm password do not match.');
      return;
    }

    if (newPassword.length < 6) {
      AppSnackBar.showError(message: 'New password must be at least 6 characters.');
      return;
    }

    // Show loading indicator
    isLoading.value = true;

    try {
      // Reauthenticate the user first
      AuthCredential credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credentials);

      // Update the password
      await user.updatePassword(newPassword);
      await user.reload(); // Reload user data to apply changes

      // Show success message
      AppSnackBar.showSuccess(message: 'Password changed successfully!');
      isLoading.value = false;

      // Optionally, navigate to another screen
      Get.offAllNamed(Routes.LOGIN_SIGNUP);  // Or wherever you want to go
    } catch (e) {
      isLoading.value = false;
      AppSnackBar.showError(message: 'Failed to change password. Please try again.');
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topBar(),
          15.height,
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        AssetsConstant.loginImage,
                        scale: 4,
                      ),
                    ),
                    20.height,
                    buildTextFormField(
                      'Current Password',
                      'Enter your current password',
                      currentPasswordController,
                    ),
                    buildTextFormField(
                      'New Password',
                      'Enter your new password',
                      newPasswordController,
                    ),
                    buildTextFormField(
                      'Confirm Password',
                      'Confirm your new password',
                      confirmPasswordController,
                    ),
                    20.height,
                    buildContinueButton('Change Password', currentPasswordController),
                    20.height,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextFormField(
      String label,
      String hint,
      TextEditingController textController,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: textController,
        obscureText: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textFieldBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textFieldHintColor,
          ),
        ),
      ),
    );
  }

  Widget buildContinueButton(String text, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        changePassword();
      },
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: AppColors.buttonBackgroundColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: isLoading.value
                ? CircularProgressIndicator(
              color: Colors.white70,
            )
                : MyText.titleLarge(
              text,
              fontSize: 18,
              color: AppColors.whiteColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget topBar() {
    return CommonWidget.topBars(
      label: 'Change Password',
      hint: 'Please enter your current and new passwords',
      showArrow: true,
      verticalPadding: 40,
    );
  }
}
