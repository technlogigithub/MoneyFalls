import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery/app/services/user_data.dart';


class EditProfileController extends GetxController {
  //TODO: Implement ProfileController
FirebaseAuth auth = FirebaseAuth.instance;
  final count = 0.obs;
  RxString referralName = "".obs;
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  RxBool isLoading = false.obs;
  RxBool editEmail = false.obs;
  RxBool editName = false.obs;
final FocusNode emailFocusNode = FocusNode();
final FocusNode nameFocusNode = FocusNode();
UserController splashController = Get.find<UserController>();

  @override
  void onInit() {
    super.onInit();

    assignData();
  }

  assignData()async{
    userNameController.text = splashController.userData.value?.name ?? "";
    referralName.value = splashController.userData.value?.username ?? "";
    phoneNumberController.text = splashController.userData.value?.phoneNumber ?? "";
    emailController.text = splashController.userData.value?.email ?? "";
  }

  //update currentUserName
  updateUserName() {
    FirebaseFirestore.instance.collection('users').doc(auth.currentUser?.uid).update({
      'name': userNameController.text,
    });
  }

  updateEmailUserName() async {
    isLoading.value = true;
    Future.delayed(Duration(seconds: 2),() async {
      await updateUserName();
      await splashController.refreshUserData();
      Get.back();
      isLoading.value = false;
    });

    // updateEmail();
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

  void editPhone() {
    editEmail.value = !editEmail.value;
  }
}
