import 'package:get/get.dart';
import 'package:lottery/app/modules/favourite/controllers/favourite_controller.dart';
import 'package:lottery/app/modules/home/controllers/home_controller.dart';
import 'package:lottery/app/modules/wallet/controllers/wallet_controller.dart';

import '../controllers/bottom_bar_controller.dart';

class BottomBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomBarController>(
      () => BottomBarController(),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<WalletController>(
      () => WalletController(),
    );
    Get.lazyPut<FavouriteController>(
      () => FavouriteController(),
    );
    // Get.lazyPut<ProfileController>(
    //   () => ProfileController(),
    // );
  }
}
