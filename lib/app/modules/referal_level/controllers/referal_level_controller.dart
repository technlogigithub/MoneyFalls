import 'package:get/get.dart';
import 'package:lottery/app/modules/login/controllers/login_signup_controller.dart';
import 'package:lottery/app/services/user_data.dart';

class ReferalLevelController extends GetxController {
  //TODO: Implement ReferalLevelController

  final count = 0.obs;
  RxMap data = {}.obs;
  RxInt selectedLevel = 0.obs;
  RxBool isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    isLoading.value = true;
    assignData();
  }

  assignData() async {
    String userName = Get.find<UserController>().userData.value?.username ?? '';
    data.value = await fetchReferrals(userName: userName);
    isLoading.value = false;
    print(data['level1']);
    print(data['level2']);
    print(data['level3']);
    print(data['level4']);
    print(data['level5']);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
