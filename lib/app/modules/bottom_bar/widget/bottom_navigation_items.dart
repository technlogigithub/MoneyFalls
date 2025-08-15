import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/modules/favourite/controllers/favourite_controller.dart';
import 'package:lottery/app/modules/home/controllers/home_controller.dart';
import 'package:lottery/app/services/user_data.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';

import '../../../utils/constants.dart';

class BottomNavigationTabBarView extends StatelessWidget {
final int currentIndex;
final Function(int)? onTabChange;

BottomNavigationTabBarView(this.currentIndex, {this.onTabChange});
UserController userController = Get.find<UserController>();
HomeController homeController = Get.put(HomeController());
FavouriteController favouriteController = Get.put(FavouriteController());

var inactiveTabs = [
  "assets/images/home.png",
  "assets/images/search.png",
  "assets/images/wallet.png",
  "assets/images/favourite.png",
  "assets/images/user.png",
];

var names = [
  "Home",
  "Search",
  "Wallet",
  "Messages",
  "Profile",
];

@override
Widget build(BuildContext context) {
  return bottomNavigationTabBarView(context);
}

Widget bottomNavigationTabBarView(BuildContext context) {
  const iconSize = 30.0;
  return Container(
    decoration: BoxDecoration(
      color: AppColors.blackColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 3,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: BottomNavigationBar(
      enableFeedback: false,
      key: const Key('bottomBar'),
      currentIndex: currentIndex, // Use the passed index
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedFontSize: 0,
      elevation: 35,
      unselectedFontSize: 0,
      backgroundColor: AppColors.blackColor,
      iconSize: iconSize,
      onTap: (index) {
        print('Tapped index: $index');
        if (onTabChange != null) onTabChange!(index);
      },
      type: BottomNavigationBarType.fixed,
      items: [
        for (int i = 0; i < names.length; i++) ...{
          BottomNavigationBarItem(
            label: names[i],
            icon: Column(
              children: [
                const SizedBox(height: 6),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    Image.asset(
                      inactiveTabs[i],
                      width: iconSize,
                      height: iconSize,
                      color: AppColors.inactiveBottomItemColor,
                    ),
                    Visibility(
                      visible: i == 0 || i == 2 || i == 3,
                      child: Positioned(
                        top: -5,
                        right: -10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.red,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                            child: i == 2
                                ? Obx(() => MyText(
                              userController.userData.value?.totalCoins.toStringAsFixed(2) ?? '0',
                              color: AppColors.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ))
                                : i == 0
                                ? Obx(() => MyText(
                              homeController.totalTickets.value.toString(),
                              color: AppColors.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ))
                                : Obx(() => MyText(
                              favouriteController.totalUnseenMessages.value.toString(),
                              color: AppColors.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  names[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inactiveBottomItemColor,
                  ),
                ),
                5.height,
              ],
            ),
            activeIcon: Column(
              children: [
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    Image.asset(
                      inactiveTabs[i],
                      width: iconSize,
                      height: iconSize,
                      color: AppColors.whiteColor,
                    ),
                    Visibility(
                      visible: i == 0 || i == 2 || i == 3,
                      child: Positioned(
                        top: -5,
                        right: -10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.red,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                            child: i == 2
                                ? Obx(() => MyText(
                              userController.userData.value?.totalCoins.toStringAsFixed(2) ?? '0',
                              color: AppColors.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ))
                                : i == 0
                                ? Obx(() => MyText(
                              homeController.totalTickets.value.toString(),
                              color: AppColors.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ))
                                : Obx(() => MyText(
                              favouriteController.totalUnseenMessages.value.toString(),
                              color: AppColors.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  names[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.whiteColor,
                  ),
                ),
                5.height,
              ],
            ),
          ),
        },
      ],
    ),
  );
}
}