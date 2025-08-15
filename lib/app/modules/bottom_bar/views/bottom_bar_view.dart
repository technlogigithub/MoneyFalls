import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/bottom_bar_controller.dart';
import '../widget/bottom_navigation_items.dart';

class BottomBarView extends GetView<BottomBarController> {
  const BottomBarView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: Get.height,
        width: Get.width,
        child: Obx(() {
          return controller.onTapChange(controller.currentIndex.value);
        }),
      ),
     bottomNavigationBar: Obx(() {
        return BottomNavigationTabBarView(
        controller.currentIndex.value,
        onTabChange: (index) => controller.currentIndex.value = index,
        );
      }),
    );
  }
}
