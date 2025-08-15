import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/snackbars.dart';
import '../controllers/profile_controller.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/my_text.dart';

import 'dart:ui' as ui;

class ProfileView extends GetView<ProfileController> {
  ProfileView({super.key});

  @override
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    controller.assignData();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: Get.width,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            // Background or decorative element (placed first to be at the bottom)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: RPSCustomPainter(),
                ),
              ),
            ),
            // Profile content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                      () => controller.splashController.userData.value == null || controller.isLoading.value
                      ? Center(
                    child: CircularProgressIndicator(),
                  )
                      : SizedBox(
                    height: Get.height,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 80),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                controller
                                    .pickAndUploadProfilePicture();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.yellow, width: 4),
                                ),
                                child: Obx(() => CircleAvatar(
                                  radius: 67,
                                  backgroundColor:
                                  Colors.grey.shade200,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: controller
                                          .splashController
                                          .userData
                                          .value
                                          ?.profileImage ??
                                          '',
                                      fit: BoxFit.cover,
                                      width: 134, // 2 * radius
                                      height: 134,
                                      placeholder: (context,
                                          url) =>
                                          Center(
                                              child:
                                              CircularProgressIndicator()),
                                      errorWidget: (context,
                                          url, error) =>
                                          Image.network(
                                            AssetsConstant
                                                .onlineLogo,
                                            fit: BoxFit.cover,
                                            width: 134,
                                            height: 134,
                                          ),
                                    ),
                                  ),
                                )),
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.only(left: 22.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    controller.splashController.userData
                                        .value?.name ?? '',
                                    fontSize: 18,
                                  ),
                                  Row(
                                    children: [
                                      MyText(
                                        '@${controller.splashController.userData
                                            .value?.username}',
                                        fontSize: 14,
                                        color: AppColors.blackColor
                                            .withAlpha(100),
                                      ),
                                      10.width,
                                      GestureDetector(
                                        onTap: () {
                                          final userName = controller.splashController.userData
                                              .value?.username ?? '';
                                          Clipboard.setData(
                                              ClipboardData(
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
                        Spacer(),
                        Obx(
                              () => settingOptions(
                            title: "Streak",
                            value: controller.splashController.userData
                                .value?.streak
                                .toString() ??
                                '0',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            controller.getReferralUserAndPrintName(
                                controller.splashController.userData
                                    .value?.referralUsername ??
                                    '');
                          },
                          child: settingOptions(
                            title: "Following",
                            value: controller
                                .splashController
                                .userData
                                .value
                                ?.referralUsername
                                .isEmpty ==
                                true
                                ? '0'
                                : '1',
                          ),
                        ),
                        settingOptions(
                          title: "Followers",
                          value: controller.totalFollowers.value
                              .toString(),
                        ),
                        settingOptions(
                          title: "Wins",
                          value: controller.splashController.userData
                              .value?.totalWinCount
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
                                      text: WidgetSpan(
                                        child: Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            MyText(
                                              'Winners ',
                                              fontSize: 17,
                                              fontWeight:
                                              FontWeight.w400,
                                              color:
                                              AppColors.whiteColor,
                                            ),
                                            MyText(
                                              'from DownLine',
                                              fontSize: 11,
                                              fontWeight:
                                              FontWeight.w400,
                                              color:
                                              AppColors.whiteColor,
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
                                      controller
                                          .downLineWinnersCount.value
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
                        30.height,
                        buildContinueButton('Followers', true),
                        20.height,
                        // Visibility(
                        //   visible: controller.currentUser.value
                        //           ?.beneficiary?.beneficiaryId ==
                        //       null,
                        //   child: buildContinueButton(
                        //       'Add Account Details', false),
                        // ),
                        // 20.height,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Settings button (placed near the end to be tappable)
            Positioned(
              top: 30,
              right: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(Routes.EDITPROFILE);
                  },
                  child: Image.asset(
                    AssetsConstant.settings,
                    scale: 3.3,
                  ),
                ),
              ),
            ),
            // Back button (placed last to ensure it's on top)
            Positioned(
              top: 30,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: () {
                    print('Back button tapped');
                    if (controller.bottomBarController.currentIndex.value !=
                        0) {
                      print(
                          'Bottom Bar Index: ${controller.bottomBarController.currentIndex.value}');
                      controller.bottomBarController.currentIndex.value = 0;
                      controller.bottomBarController.onTapChange(
                          controller.bottomBarController.currentIndex.value);
                    }
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
    );
  }

  void showBeneficiaryFormBottomSheet() {
    var userData = controller.splashController.userData.value;
    Get.bottomSheet(
      backgroundColor: AppColors.whiteColor,
      SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Withdraw Form",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Beneficiary Name
              // customInput(controller.nameController, "Name"),
              // customInput(controller.emailController, "Email"),
              customInput(controller.phoneController, "Phone"),
              // customInput(controller.countryCodeController, "Country Code"),

              // const Divider(),

              // Bank Details
              // customInput(controller.bankAccountController, "Bank Account No."),
              customInput(controller.vpaController, "UPI ID (VPA)"),
              // customInput(controller.ifscController, "Bank IFSC Code"),

              const Divider(),

              // Address
              // customInput(controller.addressController, "Address"),
              // customInput(controller.cityController, "City"),
              // customInput(controller.stateController, "State"),
              // customInput(controller.postalCodeController, "Postal Code"),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: GestureDetector(
                  onTap: () {
                    if ((controller.vpaController.text.isEmpty) ||
                        (controller.phoneController.text.isEmpty)
                    // ||
                    // (controller.cityController.text.isEmpty) ||
                    // (controller.stateController.text.isEmpty) ||
                    // (controller.postalCodeController.text.isEmpty)
                    ) {
                      AppSnackBar.showError(
                          message: 'Please fill all the fields');
                      return;
                    } else {
                      Get.back();
                      controller.addBeneficiary(
                        beneficiaryId: '${userData?.name}${userData?.uid}',
                        beneficiaryName: userData?.name ?? '',
                        beneficiaryEmail: userData?.email ?? '',
                        beneficiaryPhone: controller.phoneController.text,
                        // beneficiaryCountryCode:
                        // "+1",
                        // bankAccountNumber: controller.bankAccountController
                        //     .text,
                        // bankIfsc: controller.ifscController.text,
                        vpa: controller.vpaController.text,
                        // beneficiaryAddress: controller.addressController.text,
                        // beneficiaryCity: controller.cityController.text,
                        // beneficiaryState: controller.stateController.text,
                        // beneficiaryPostalCode:
                        // controller.postalCodeController.text,
                      );
                    }
                  },
                  child: Container(
                    width: Get.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: AppColors.whiteColor),
                      color: AppColors.lightBlueColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Center(
                        child: MyText.titleLarge(
                          'Submit',
                          fontSize: 16,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget customInput(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  GestureDetector buildContinueButton(String text, bool isOutlined) {
    return GestureDetector(
      onTap: () {
        isOutlined
            ? Get.toNamed(Routes.REFERAL_LEVEL)
            : showBeneficiaryFormBottomSheet();
      },
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: AppColors.whiteColor),
          color: AppColors.whiteColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: MyText.titleLarge(
              text,
              fontSize: 16,
              color: AppColors.lightBlueColor,
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
