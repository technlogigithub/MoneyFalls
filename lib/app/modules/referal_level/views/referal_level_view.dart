import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';

import '../controllers/referal_level_controller.dart';

class ReferalLevelView extends GetView<ReferalLevelController> {
  const ReferalLevelView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF648CBC),
                Color(0xFFFEE800),
              ],
              stops: [0.19, 0.8],
              begin: Alignment.topRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topBar(),
              20.height,
              Expanded(
                child: Container(
                  width: Get.width,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColors,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                                vertical: 22.0, horizontal: 15)
                            .copyWith(bottom: 10),
                        child: Row(
                          children: List.generate(5, (index) {
                            return Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topRight,
                              children: [
                                Obx(
                                  () => GestureDetector(
                                    onTap: () {
                                      controller.selectedLevel.value = index;
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: index == 0
                                            ? BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                bottomLeft: Radius.circular(10))
                                            : index == 4
                                                ? BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(10),
                                                    bottomRight:
                                                        Radius.circular(10))
                                                : BorderRadius.circular(0),
                                        color: controller.selectedLevel.value ==
                                                index
                                            ? AppColors.lightBlueColor
                                            : AppColors.levelOverviewColor,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 20),
                                      child: MyText(
                                        'Level ${index + 1}',
                                        fontSize: 12,
                                        color: controller.selectedLevel.value ==
                                                index
                                            ? AppColors.whiteColor
                                            : AppColors.blackColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Colors.red,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 8),
                                      child: Obx(
                                        () => MyText(
                                          "${controller.data['level${index + 1}']?.length ?? 0}",
                                          color: AppColors.whiteColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          }),
                        ),
                      ),
                      Obx(
                        () => controller.isLoading.value
                            ? Center(child: CircularProgressIndicator())
                            : Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: controller
                                          .data[
                                              'level${controller.selectedLevel.value + 1}']
                                          ?.length ??
                                      0,
                                  itemBuilder: (context, index) {
                                    var data = controller.data[
                                            'level${controller.selectedLevel.value + 1}']
                                        ?[index];
                                    final imageUrl = data?['profile_image'];
                                    // print('this is image url $imageUrl');
                                    // final finalImageUrl = (imageUrl == null || imageUrl.isEmpty)
                                    //     ? AssetsConstant.onlineLogo
                                    //     : imageUrl;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 25.0, right: 25, left: 25),
                                      child: GestureDetector(
                                        onTap: () {
                                          Get.toNamed(
                                              Routes.OTHER_PERSON_PROFILE,
                                              arguments: {
                                                'userID': data?['uid'],
                                              });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppColors
                                                    .searchFieldBorderColor),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  height: 50,
                                                  width: 50,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Center(
                                                          child:
                                                              CircularProgressIndicator()),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Image.network(
                                                    AssetsConstant.onlineLogo,
                                                    fit: BoxFit.cover,
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 20),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    MyText(
                                                      data?['name'],
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: AppColors
                                                          .newBlockColor,
                                                    ),
                                                    MyText(
                                                      data?['username'],
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: AppColors
                                                          .messageColor,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Padding topBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
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
          10.width,
          Text(
            'Followers',
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }

  GestureDetector buildContinueButton(
    String text,
  ) {
    return GestureDetector(
      onTap: () {
        // Get.toNamed(Routes.REFERAL_LEVEL);
      },
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.lightBlueColor),
          color: AppColors.lightBlueColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: MyText.titleLarge(
              text,
              fontSize: 18,
              color: AppColors.whiteColor,
            ),
          ),
        ),
      ),
    );
  }

  Positioned balanceCard() {
    return Positioned(
      top: -70,
      right: 20,
      left: 20,
      child: Center(
        child: Container(
          width: 350,
          height: 180,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/wallet_card.png'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                'Wallet',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.whiteColor,
              ),
              40.height,
              MyText(
                'Your Coins',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: AppColors.whiteColor,
              ),
              5.height,
              Row(
                children: [
                  Image.asset(
                    'assets/images/cruuencyIcon.png',
                    scale: 3,
                  ),
                  5.width,
                  MyText(
                    '8,700',
                    fontWeight: FontWeight.normal,
                    fontSize: 30,
                    color: AppColors.whiteColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
