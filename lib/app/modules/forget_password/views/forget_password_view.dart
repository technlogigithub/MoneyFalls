import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/common_widget.dart';
import 'package:lottery/app/utils/my_text.dart';
import '../../../utils/constants.dart';
import '../controllers/forget_password_controller.dart';

class ForgetPasswordView extends GetView<ForgetPasswordController> {
  const ForgetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonWidgets.topBar(
              label: 'Forgot\nPassword',
              hint: 'Please Reset Your Password',
              verticalPadding: 30,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      AssetsConstant.forgetPassword,
                      scale: 4,
                    ),
                  ),
                  SizedBox(height: 20),
                  buildTextFormField(
                    'Email',
                    'Enter your email',
                    controller.emailController,
                  ),
                  SizedBox(height: 20),
                  Obx(() => GestureDetector(
                    onTap: controller.isLoading.value ? null : () {
                      controller.forgotPassword();
                    },
                    child: buildContinueButton('Submit'),
                  )),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildContinueButton(String text) {
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: AppColors.buttonBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Center(
          child: Obx(
            () => controller.isLoading.value
                ? CircularProgressIndicator(
                    color: Colors.white,
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

  Widget buildTextFormField(
    String label,
    String hint,
    TextEditingController textController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: textController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => controller.forgotPassword(),
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
          errorMaxLines: 2,
        ),
      ),
    );
  }
}