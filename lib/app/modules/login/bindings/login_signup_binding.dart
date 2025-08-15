import 'package:get/get.dart';

import '../controllers/login_signup_controller.dart';

class LoginSignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginSignupController>(
          () => LoginSignupController(),
    );
  }
}