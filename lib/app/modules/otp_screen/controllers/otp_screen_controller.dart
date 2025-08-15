// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:lottery/app/modules/login/controllers/login_signup_controller.dart';
// import 'package:lottery/app/routes/app_pages.dart';
// import 'package:pinput/pinput.dart';
//
// import '../../../models/user_model.dart';
//
// class OtpScreenController extends GetxController {
//   //TODO: Implement OtpScreenController
//
//   late final SmsRetriever smsRetriever;
//   late final TextEditingController pinController;
//   late final FocusNode focusNode;
//   late final GlobalKey<FormState> formKey;
//   // RxString otp = ''.obs;
//   RxString verificationId = ''.obs;
//   FirebaseAuth auth = FirebaseAuth.instance;
//   RxBool isLoading = false.obs;
//
//
//   @override
//   void onInit() {
//     super.onInit();
//     formKey = GlobalKey<FormState>();
//     pinController = TextEditingController();
//     focusNode = FocusNode();
//   }
//
//   @override
//   void dispose() {
//     pinController.dispose();
//     focusNode.dispose();
//     super.dispose();
//   }
//
//   Future<void> verifyOTP() async {
//     isLoading.value = true;
//     try {
//
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId.value,
//         smsCode: pinController.text,
//       );
//
//       await auth.signInWithCredential(credential);
//       if(!Get.find<LoginSignupController>().isLogin.value){
//         await _saveUserData(auth.currentUser, Get.find<LoginSignupController>().fullNameController.text, Get.find<LoginSignupController>().usernameController.text, Get.find<LoginSignupController>().referralUsernameController.text);
//       }
//       isLoading.value = false;
//       Get.offAllNamed(Routes.BOTTOM_BAR);
//     } catch (e) {
//       Get.snackbar('Error', 'Invalid OTP');
//       isLoading.value = false;
//     }
//   }
//
//   Future<void> _saveUserData(User? user, String name, String username,
//       String? referralUsername) async {
//     if (user != null) {
//       // UserModel userModel = UserModel(
//       //   uid: user.uid,
//       //   name: name,
//       //   username: username,
//       //   phoneNumber: user.phoneNumber.toString(),
//       //   referralUsername: referralUsername ?? "",
//       //   createdAt: FieldValue.serverTimestamp() as Timestamp,
//       //   streak: 0,
//       //   followers: 0,
//       //   following: 0,
//       //   wins: 0,
//       //   refWinner: 0,
//       //   email: '', password: '',
//       //   lastActive: DateTime.now(),
//       //   isOnline: true,
//       //   fcmToken: '',
//       // );
//       // await FirebaseFirestore.instance.collection("users").doc(user.uid).set(userModel.toMap());
//
//     }
//   }
// }
