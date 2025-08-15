import 'package:get/get.dart';
import '../controllers/ChangePasswordController.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePasswordController>(
          () => ChangePasswordController(),
    );
  }
}
