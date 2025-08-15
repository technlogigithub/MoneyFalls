import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/modules/profile/controllers/profile_controller.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/my_text.dart';
import 'dart:ui' as ui;
import '../../../services/user_data.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // You can handle your custom logic here before going back

          if (Get.previousRoute.isNotEmpty) {
            // Navigator.pop(context);
            // Get.back(); // Go to previous screen
            // Get.offAllNamed(Routes.HOME);
            // Fetch user data using UserController
            Get.find<UserController>().fetchUserData();
            Get.offAllNamed(Routes.BOTTOM_BAR);
          } else {
            // Optionally: show a dialog or exit the app
            // SystemNavigator.pop(); // Exit the app (optional)
            // Get.offAllNamed(Routes.CHANGE_PASSWORD_SCREEN);
            // Navigator.pop(context);
            Get.find<UserController>().fetchUserData();
            Get.offAllNamed(Routes.BOTTOM_BAR);
          }

          return false; // Prevent default pop
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
              child: SizedBox(
            width: Get.width,
            child: Stack(
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: RPSCustomPainter(),
                  ),
                ),
                Positioned(
                  top: 30,
                  child: SizedBox(
                    width: Get.width,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Text(
                            "Settings",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          GestureDetector(
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                await Get.put(ProfileController())
                                    .clearProfileData();
                                controller.userController.userData.value = null;
                                Get.offAllNamed(Routes.LOGIN_SIGNUP);
                              },
                              child: Image.asset(
                                'assets/images/logout.png',
                                height: 30,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 80),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.yellow, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 67,
                            backgroundImage: controller.userController.userData
                                            .value?.profileImage !=
                                        null &&
                                    controller.userController.userData.value!
                                        .profileImage.isNotEmpty
                                ? NetworkImage(controller.userController
                                    .userData.value!.profileImage)
                                : null,
                            child: controller.userController.userData.value
                                            ?.profileImage ==
                                        null ||
                                    controller.userController.userData.value!
                                        .profileImage.isEmpty
                                ? Icon(Icons.person,
                                    size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 130),
                        SettingOption(
                          title: "Email",
                          value: controller.userController.userData.value?.email
                                      ?.isNotEmpty ==
                                  true
                              ? controller.userController.userData.value!.email
                              : 'Not available',
                        ),

                        // Dynamic lottery switches for lotteries 1-10
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: 10, // For lotteries 1-10
                          itemBuilder: (context, index) {
                            int lotteryNumber =
                                index + 1; // Start from lottery 1
                            return Obx(
                              () => switchSetting(
                                title:
                                    "Coins add automatically ($lotteryNumber)",
                                onTap: () {
                                  controller.toggleAutoAddCoin(lotteryNumber);
                                },
                                autoPurchased: controller
                                    .getAutoAddCoinValue(lotteryNumber),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: () {
                            // Your logic here (e.g., navigate to Change Password screen)
                            print("Change Password tapped");
                            Get.offAllNamed(Routes.CHANGE_PASSWORD_SCREEN);
                          },
                          child: const MyText(
                            "Change Password",
                            style: TextStyle(
                              fontSize: 18,
                              // fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ));
  }

  Widget switchSetting({
    required String title,
    required Function onTap,
    required bool autoPurchased,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.whiteColor,
          ),
          Switch(
              value: autoPurchased,
              onChanged: (bool value) {
                onTap();
              }),
        ],
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

class SettingOption extends StatelessWidget {
  final String title;
  final String value;

  const SettingOption({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.whiteColor,
          ),
          MyText(
            value,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.whiteColor,
          ),
        ],
      ),
    );
  }
}
