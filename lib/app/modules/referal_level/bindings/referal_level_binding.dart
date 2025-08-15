import 'package:get/get.dart';

import '../controllers/referal_level_controller.dart';

class ReferalLevelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferalLevelController>(
      () => ReferalLevelController(),
    );
  }
}
