import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/otherWidgets/timer.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/my_text.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});
  @override
  final HomeController controller = Get.put(HomeController());

  // Define the color palette for the 5 cards
  final List<Color> cardColors = [
    AppColors.transparent, // 1. Sunset Orange
    AppColors.secondTicketColor, // 2. Coral Pink
    Color(0xFF3EB489), // 3. Mint Green
    Color(0xFF9B59B6), // 4. Lavender Purple
    Color(0xFFFFD700), // 5. Bright Gold
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            children: [
              buildAppBar(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Listen to Firestore lottery data in real-time
              StreamBuilder<QuerySnapshot>(
                  stream: controller.getLotteryStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: AppColors.blackColor),
                      ));
                    }

                    controller.updateLotteryStatus(snapshot.data!);

                    return Column(
                      children: [
                        // Generate 5 lottery tickets dynamically
                        ...List.generate(5, (index) {
                          return Column(
                            children: [
                              buildLotteryTicket(context, index + 1),
                              if (index < 4)
                                SizedBox(
                                    height:
                                        12), // Slightly increased space between tickets for better visual separation
                            ],
                          );
                        }),
                      ],
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }

  //=========================== Dynamic Lottery Ticket Widget ==========================

  Widget buildLotteryTicket(BuildContext context, int lotteryNumber) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final Color? backgroundColor;
    // Get the specific color for this lottery number

    backgroundColor = cardColors[lotteryNumber - 1];

    // Use white text for better contrast on colored backgrounds
    final Color textColor = AppColors.whiteColor;

    return Container(
      // Increased card height since we have fewer cards
      height: height > 700 ? height * 0.28 : height * 0.32, // Increased from previous values
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: height * 0.02, // Increased vertical padding
        horizontal: width * 0.04,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Slightly increased border radius
        color: backgroundColor,
        image: lotteryNumber == 1
            ? DecorationImage(
                image: AssetImage(AssetsConstant.topTicket),
                fit: BoxFit.cover,
              )
            : null,
        // Add subtle shadow for better depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                'Today\'s Prize (Growing Until 7pm)',
                color: textColor,
                fontWeight: FontWeight.w400,
                fontSize: width * 0.038, // Slightly increased font size
              ),
              Obx(() => MyText(
                    "${controller.totalUsersInLotteries[lotteryNumber - 1]}.00",
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.055, // Increased font size
                  )),
              MyText(
                'Time Left',
                color: textColor,
                fontWeight: FontWeight.w300,
                fontSize: width * 0.038, // Slightly increased font size
              ),
              CountdownTimerScreen(textColor: AppColors.whiteColor),

              // Check if user has joined this lottery
              Obx(() => controller.hasJoinedLotteries[lotteryNumber - 1]
                  ? userJoinedTicket(height, isWhite: true)
                  : joinLotteryOptions(context, width, height,
                      'lottery_$lotteryNumber', lotteryNumber,
                      isWhite: true)),

              OverlappingAvatars(id: lotteryNumber),
            ],
          ),

          // Add a subtle overlay pattern or gradient for depth
          Positioned(
            right: -10,
            bottom: -20,
            child: IgnorePointer(
              child: Container(
                height: height * 0.1, // Increased overlay size
                width: width * 0.25, // Increased overlay width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //=========================== UI Helpers ==========================

  Widget userJoinedTicket(double height, {bool isWhite = false}) {
    return Row(
      children: [
        SizedBox(
          height: height * 0.045, // Increased image size
          child: Image.asset('assets/images/ticketPurchase.png'),
        ),
        MyText.bodyMedium(
          'You are in',
          fontSize: 12, // Slightly increased font size
          fontWeight: FontWeight.w500,
          color: isWhite ? AppColors.whiteColors : AppColors.blackColor,
        ),
      ],
    );
  }

  Widget joinLotteryOptions(
      BuildContext context, double width, double height, String key, int id,
      {bool isWhite = false}) {
    return Obx(
      () => Row(
        children: [
          GestureDetector(
            onTap: () async {
              controller.lotteryKey.value = key;
              await controller.joinLottery(context, false, lotteryNumber: id);
            },
            child: controller.isLoadingLotteries[id - 1]
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.045, // Increased padding
                        vertical: height * 0.01), // Increased padding
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22), // Increased border radius
                      color: AppColors.whiteColor,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: MyText(
                      'Add Coin',
                      fontSize: width * 0.035, // Increased font size
                      fontWeight: FontWeight.w400,
                      color: AppColors.blackColor,
                    ),
                  ),
          ),
          SizedBox(width: width * 0.02), // Increased spacing
          MyText.bodyMedium('or',
              fontSize: width * 0.035, // Increased font size
              fontWeight: FontWeight.w500,
              color: AppColors.whiteColor),
          SizedBox(width: width * 0.02), // Increased spacing
          GestureDetector(
            onTap: () {
              // Prevent multiple clicks when ads are loading
              if (controller.isAdLoadingLotteries[id - 1]) return;
              controller.showRewardedInterstitial(context, id);
            },
            child: controller.isAdLoadingLotteries[id - 1]
                ? Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.045, // Increased padding
                        vertical: height * 0.01), // Increased padding
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22), // Increased border radius
                      color: AppColors.whiteColor,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16, // Increased loading indicator size
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.blackColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Obx(() => MyText(
                              'Loading... ${controller.currentAdCountLotteries[id - 1] + 1}/5',
                              fontSize: width * 0.03, // Increased font size
                              fontWeight: FontWeight.w400,
                              color: AppColors.blackColor,
                            )),
                      ],
                    ),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.045, // Increased padding
                        vertical: height * 0.01), // Increased padding
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22), // Increased border radius
                      color: AppColors.whiteColor,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: MyText(
                      'Watch five Ads',
                      fontSize: width * 0.03, // Increased font size
                      fontWeight: FontWeight.w400,
                      color: AppColors.blackColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  //=========================== AppBar ==========================

  Row buildAppBar() {
    return Row(
      children: [
        SizedBox(),
        SizedBox(width: 10),
        MyText.titleLarge(
          'Money Falls',
          fontSize: 25,
          fontWeight: FontWeight.w500,
          color: AppColors.blackColor,
        ),
        Spacer(),
        GestureDetector(
          onTap: () => Get.toNamed(Routes.SETTINGS),
          child: Image.asset(AssetsConstant.settings, scale: 3.3),
        ),
        SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Get.dialog(
              useSafeArea: true,
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: InfoDialog(),
              ),
            );
          },
          child: Image.asset(AssetsConstant.info, scale: 3.4),
        ),
      ],
    );
  }
}

class InfoDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16).copyWith(topRight: Radius.zero),
          ),
          height: 400,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                MyText(
                    'Welcome to the ultimate experience! Play daily and win exciting prizes...'),
                SizedBox(height: 10),
                MyText(
                    '...अपने खाते में निकालें और एक सुगम अनुभव का आनंद लें।'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//=========================== Avatar Badge ==========================

class OverlappingAvatars extends StatelessWidget {
  final int id;
  const OverlappingAvatars({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final avatarSize = MediaQuery.of(context).size.width * 0.06; // Increased size
    final overlap = avatarSize * 0.4;

    return GestureDetector(
      onTap: () =>
          Get.toNamed(Routes.WINNERS, arguments: {'lotteryId': 'lottery_$id'}),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.04, // Increased height
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomRight,
          children: [
            Positioned(
                right: 0,
                child: CircleAvatarWithBorder(
                    imagePath: 'assets/dummy/user1.png',
                    borderColor: Colors.white)),
            Positioned(
                right: avatarSize - overlap * 1.1,
                child: CircleAvatarWithBorder(
                    imagePath: 'assets/dummy/user2.png',
                    borderColor: Colors.white)),
            Positioned(
                right: (avatarSize - overlap) * 1.7,
                child: CircleAvatarWithBorder(
                    imagePath: 'assets/dummy/user3.png',
                    borderColor: Colors.white)),
            Positioned(
                right: (avatarSize - overlap) * 3.2,
                bottom: -2,
                child: Image.asset('assets/images/trophy.png', scale: 2.6)), // Slightly larger trophy
          ],
        ),
      ),
    );
  }
}

class CircleAvatarWithBorder extends StatelessWidget {
  final String imagePath;
  final Color borderColor;

  const CircleAvatarWithBorder(
      {super.key, required this.imagePath, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final avatarSize = MediaQuery.of(context).size.width * 0.06; // Increased size

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}