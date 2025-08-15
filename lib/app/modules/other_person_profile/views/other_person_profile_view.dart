import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';
import 'package:lottery/app/utils/constants.dart';
import 'dart:ui' as ui;
import '../../../services/user_data.dart';
import '../../../utils/snackbars.dart';
import '../controllers/other_person_profile_controller.dart';

class OtherPersonProfile extends GetView<OtherPersonProfileController> {
  OtherPersonProfile({super.key});
  final OtherPersonProfileController controller =
      Get.put(OtherPersonProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: Get.width,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RPSCustomPainter(),
              ),
            ),
            // Back button to return to previous screen
            Positioned(
              top: 30,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: () {
                    Get.back(); // Go back to previous screen
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: AppColors.lightBrownColor,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () => controller.currentUser.value == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 80),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.yellow, width: 4),
                                  ),
                                  child: Obx(
                                    () => CircleAvatar(
                                      radius: 67,
                                      backgroundImage: NetworkImage(controller
                                              .currentUser
                                              .value
                                              ?.profileImage ??
                                          AssetsConstant.onlineLogo),
                                      onBackgroundImageError: (_, __) =>
                                          const AssetImage(
                                              'assets/dummy/user1.png'),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 22.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MyText(
                                        controller.currentUser.value!.name,
                                        fontSize: 18,
                                      ),
                                      Row(
                                        children: [
                                          MyText(
                                            '@${controller.currentUser.value!.username}',
                                            fontSize: 14,
                                            color: AppColors.blackColor
                                                .withAlpha(100),
                                          ),
                                          10.width,
                                          GestureDetector(
                                            onTap: () {
                                              final userName = controller
                                                  .currentUser.value!.username;
                                              Clipboard.setData(ClipboardData(
                                                  text: userName));
                                              AppSnackBar.showInfo(
                                                  message:
                                                      'Text copied $userName');
                                            },
                                            child: Image.asset(
                                              'assets/images/copy.png',
                                              height: 15,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 100),
                            settingOptions(
                              title: "Streak",
                              value: controller.streak.value.toString(),
                            ),
                            GestureDetector(
                              onTap: () {
                                controller.getReferralUserAndPrintName(
                                    controller.currentUser.value
                                            ?.referralUsername ??
                                        '');
                              },
                              child: settingOptions(
                                title: "Following",
                                value: controller.currentUser.value
                                            ?.referralUsername.isNotEmpty ==
                                        true
                                    ? '1'
                                    : '0', // Placeholder, update with actual data
                              ),
                            ),
                            settingOptions(
                              title: "Followers",
                              value: controller.totalFollowers.value.toString(),
                            ),
                            settingOptions(
                              title: "Wins",
                              value: controller.currentUser.value?.totalWinCount
                                      .toString() ??
                                  '',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 27),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: const WidgetSpan(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                MyText(
                                                  'Winners ',
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.whiteColor,
                                                ),
                                                MyText(
                                                  'from DownLine',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.whiteColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  27.width,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MyText(
                                          controller.downLineWinnersCount.value
                                              .toString(),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.whiteColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            57.height,
                            Row(
                              children: [
                                Obx(
                                  () => Get.find<UserController>()
                                              .userData
                                              .value
                                              ?.referralUsername
                                              .isNotEmpty ==
                                          true
                                      ? SizedBox()
                                      : Visibility(
                                          visible:
                                              // controller.otherUserid.value !=
                                              //     Get.find<UserController>()
                                              //         .userData
                                              //         .value
                                              //         ?.uid,
                                          controller.referralName !=
                                              controller.currentUserName ,
                                          child: Expanded(
                                            child: buildContinueButton(
                                                'Follow', false),
                                          ),
                                        ),
                                ),
                                30.width,
                                Visibility(
                                  visible: controller.otherUserid.value ==
                                      controller.currentUser.value?.uid,
                                  child: Expanded(
                                    child:
                                        buildContinueButton('Message', false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector buildContinueButton(String text, bool isOutlined) {
    return GestureDetector(
      onTap: () async {
        if (text == 'Follow') {
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            'referralUsername': controller.currentUser.value!.username,
          });
          Get.find<UserController>().refreshUserData();
        } else {
          controller.initiateChat();
        }
      },
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: AppColors.whiteColor),
          color: isOutlined ? Colors.transparent : AppColors.whiteColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: MyText.titleLarge(
              text,
              fontSize: 16,
              color:
                  isOutlined ? AppColors.whiteColor : AppColors.lightBlueColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget settingOptions({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(top: 27),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  title,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),
          30.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  value,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RPSCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();

    double topPadding = size.height * 0.16;

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
