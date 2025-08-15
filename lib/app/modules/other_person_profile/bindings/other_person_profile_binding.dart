import 'package:get/get.dart';

import '../controllers/other_person_profile_controller.dart';

class OtherPersonProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtherPersonProfileController>(
      () => OtherPersonProfileController(),
    );
  }
}
