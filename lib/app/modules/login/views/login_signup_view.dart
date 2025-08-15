import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/modules/login/controllers/login_signup_controller.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/common_widget.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';

class LoginSignupView extends GetView<LoginSignupController> {
  const LoginSignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topBar(),
          15.height,
          Obx(
            () => controller.isEmailVerificationSent.value
                ? buildEmailVerificationScreen()
                : controller.isLogin.value
                    ? login()
                    : buildSignup(),
          ),
        ],
      ),
    );
  }

  // Email verification screen
  Widget buildEmailVerificationScreen() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 100,
              color: AppColors.yellowColor,
            ),
            30.height,
            MyText.titleLarge(
              'Check Your Email',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            20.height,
            MyText.bodyMedium(
              'We\'ve sent a verification link to your email address. Please click the link to verify your account.',
              fontSize: 16,
              textAlign: TextAlign.center,
              color: AppColors.textLightColor,
            ),
            30.height,
            GestureDetector(
              onTap: () async {
                await controller.refreshEmailVerificationStatus();
              },
              child: Container(
                width: Get.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: AppColors.buttonBackgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Center(
                    child: MyText.titleLarge(
                      'I\'ve Verified My Email',
                      fontSize: 18,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
            ),
            20.height,
            GestureDetector(
              onTap: () {
                // Resend verification email
                if (controller.auth.currentUser != null) {
                  controller.auth.currentUser!.sendEmailVerification();
                  Get.snackbar(
                    'Email Sent',
                    'Verification email has been resent',
                    backgroundColor: AppColors.yellowColor,
                  );
                }
              },
              child: MyText.bodyMedium(
                'Didn\'t receive the email? Resend',
                color: AppColors.yellowColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            30.height,
            GestureDetector(
              onTap: () {
                controller.changeScreen(true);
              },
              child: MyText.bodyMedium(
                'Back to Login',
                color: AppColors.textLightColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  login() {
    return Expanded(
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
                'Email',
                'Enter your email',
                controller.emailController,
              ),
              buildTextFormField(
                'Password',
                'Enter your password',
                controller.passwordController,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.FORGET_PASSWORD);
                  },
                  child: MyText.bodyMedium(
                    'Forget Password ?',
                    color: AppColors.yellowColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              20.height,
              buildContinueButton('Login', controller.emailController),
              20.height,
              buildLoginSignUpBottomText(
                'Don\'t have an account? ',
                ' Signup',
                () {
                  controller.changeScreen(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildSignup() {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextFormField(
                'Full Name',
                'Enter your full name',
                controller.fullNameController,
              ),
              buildTextFormField(
                'Username',
                'Enter your username',
                controller.usernameController,
              ),
              buildTextFormField(
                'Email',
                'Enter your email',
                controller.emailController,
              ),
              buildTextFormField(
                'Password',
                'Enter your password',
                controller.passwordController,
              ),
              buildTextFormField(
                'Referral username',
                'Enter Referral username',
                controller.referralUsernameController,
              ),
              10.height,
              buildTermsCondition(),
              10.height,
              buildContinueButton('Continue', controller.emailController),
              20.height,
              buildLoginSignUpBottomText(
                'Already have an account? ',
                ' Login',
                () {
                  controller.changeScreen(true);
                },
              ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }

  buildTermsCondition() {
    return Row(
      children: [
        SizedBox(
          height: 40,
          width: 40,
          child: Theme(
            data: Theme.of(Get.context!).copyWith(
              unselectedWidgetColor: Colors.grey,
              checkboxTheme: CheckboxThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            child: Obx(
              () => Checkbox(
                value: controller.termCondition.value,
                onChanged: (value) {
                  controller.termCondition.value = value!;
                },
              ),
            ),
          ),
        ),
        buildLoginSignUpBottomText(
          'I agree to ',
          ' Terms and Conditions',
          () {
            // Handle terms and conditions tap
          },
        ),
      ],
    );
  }

  Center buildLoginSignUpBottomText(
    String title,
    String word,
    Function onTap,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: title,
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: AppColors.textLightColor,
                    fontSize: 15),
              ),
              TextSpan(
                text: word,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellowColor,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector buildContinueButton(
      String text, TextEditingController emailController) {
    return GestureDetector(
      onTap: () {
        String email = emailController.text;
        String password = controller.passwordController.text;

        if (controller.isLogin.value) {
          controller.signInWithEmailAndPassword(email, password);
        } else {
          controller.signUpWithEmailAndPassword(email, password);
        }
      },
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: AppColors.buttonBackgroundColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: Obx(
              () => controller.isLoading.value
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
        obscureText: label == 'Password' 
            ? controller.showHidePassword.value 
            : false,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textFieldBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: label == 'Password'
              ? Obx(() => GestureDetector(
                  onTap: () {
                    controller.onOffToggle();
                  },
                  child: Icon(
                    controller.showHidePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ))
              : SizedBox(),
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textFieldHintColor,
          ),
        ),
      ),
    );
  }

  Widget topBar() {
    return Obx(
      () => controller.isEmailVerificationSent.value
          ? CommonWidgets.topBar(
              label: 'Email\nVerification',
              hint: 'Verify your email to continue',
              showArrow: false,
              verticalPadding: 40)
          : controller.isLogin.value
              ? CommonWidgets.topBar(
                  label: 'Welcome',
                  hint: 'Please sign in to continue',
                  showArrow: false,
                  verticalPadding: 40)
              : CommonWidgets.topBar(
                  label: 'Create\nAccount',
                  hint: 'Please sign Up to continue',
                  showArrow: false,
                ),
    );
  }
}