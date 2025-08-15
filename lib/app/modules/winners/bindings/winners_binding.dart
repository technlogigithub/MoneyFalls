import 'package:get/get.dart';

import '../controllers/winners_controller.dart';

class WinnersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WinnersController>(
      () => WinnersController(),
    );
  }
}
