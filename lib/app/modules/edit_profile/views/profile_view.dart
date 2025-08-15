import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';

import '../controllers/profile_controller.dart';

import 'dart:ui' as ui;

class EditProfileView extends GetView<EditProfileController> {
  EditProfileView({super.key});
  @override
  final EditProfileController controller = Get.put(EditProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: Get.width,
          height: Get.height,
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: RPSCustomPainter(),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 90),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.yellow, width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 67,
                              backgroundImage: NetworkImage(
                                controller.splashController.userData.value
                                        ?.profileImage ??
                                    '',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 22.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Obx(
                                      () => SizedBox(
                                        width: 150,
                                        child: buildTextFormField(
                                          controller.userNameController,
                                          AppColors.blackColor,
                                          controller.nameFocusNode,
                                          controller.editName.value,
                                          // fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    // 10.width,
                                    GestureDetector(
                                      onTap: () {
                                        print('Hello');
                                        controller.editName.value =
                                            !controller.editName.value;
                                        Future.delayed(
                                            Duration(milliseconds: 100), () {
                                          if (controller.editName.value) {
                                            controller.nameFocusNode
                                                .requestFocus();
                                          }
                                        });
                                      },
                                      child: Image.asset(
                                        'assets/images/edit.png',
                                        height: 22,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                                Obx(
                                  () => Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: MyText(
                                      '@${controller.referralName.value}',
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 90),
                      settingOption(
                          value: "assets/images/edit.png", context: context),
                      Spacer(),
                      Obx(
                          ()=> GestureDetector(
                          onTap: () {
                            controller.updateEmailUserName();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: AppColors.whiteColor,
                            ),
                            child: controller.isLoading.value
                                ? CircularProgressIndicator()
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 45),
                                    child: Text('Update'),
                                  ),
                          ),
                        ),
                      ),
                      30.height,
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 40,
                right: 80,
                left: 100,
                child: Padding(
                    padding: const EdgeInsets.only(left: 50.0),
                    child: MyText.titleLarge(
                      'Edit Profile',
                      fontSize: 22,
                    )),
              ),
              // Back button (placed last to ensure it's on top)
              Positioned(
                top: 40,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: GestureDetector(
                    onTap: () {
                      print('Back button tapped');
                      Get.back();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: AppColors.lightBrownColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 13,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingOption({required String value, required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Obx(
              () => buildTextFormField(
                  controller.emailController,
                  AppColors.whiteColor,
                  controller.emailFocusNode,
                  controller.editEmail.value),
            ),
          ),
          // 150.width,
          // GestureDetector(
          //   onTap: () {
          //     controller.editPhone();
          //     Future.delayed(Duration(milliseconds: 100), () {
          //       if (controller.editEmail.value) {
          //         controller.emailFocusNode.requestFocus();
          //       }
          //     });
          //   },
          //   child: Image.asset(
          //     value,
          //     color: Color(0xffF4E20D),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget buildTextFormField(TextEditingController textController,
      Color textColor, FocusNode focusNode, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        focusNode: focusNode,
        enabled: isEnabled,
        style: TextStyle(
          // Ensures user-typed text is also white
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        controller: textController,
        decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: controller.editEmail.value
                      ? AppColors.yellowColor
                      : AppColors.transparent,
                  width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            hintStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.whiteColor,
            ),
            labelStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.whiteColor,
            )),
      ),
    );
  }
}

class RPSCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();

    double topPadding = size.height * 0.19;

    path.moveTo(size.width * 0.1586, topPadding);
    path.cubicTo(
      size.width * 0.1185,
      topPadding,
      size.width * 0.0251,
      size.height * 0.011 + topPadding,
      0,
      size.height * 0.0209 + topPadding,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.148 + topPadding);
    path.cubicTo(
      size.width * 0.9223,
      size.height * 0.184 + topPadding,
      size.width * 0.8495,
      size.height * 0.199 + topPadding,
      size.width * 0.7624,
      size.height * 0.199 + topPadding,
    );
    path.cubicTo(
      size.width * 0.6059,
      size.height * 0.199 + topPadding,
      size.width * 0.5308,
      size.height * 0.157 + topPadding,
      size.width * 0.4442,
      size.height * 0.093 + topPadding,
    );
    path.cubicTo(
      size.width * 0.3312,
      size.height * 0.0093 + topPadding,
      size.width * 0.2737,
      topPadding,
      size.width * 0.1586,
      topPadding,
    );
    path.close();

    Paint paint = Paint()..style = PaintingStyle.fill;
    paint.shader = ui.Gradient.linear(
      Offset(size.width * 0.0447, size.height * 0.866),
      Offset(size.width * 1.2395, size.height * 0.258),
      [const Color(0xffFEE800), const Color(0xff648CBC)],
      [0, 0.735],
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
