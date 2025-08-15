// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:lottery/app/utils/constants.dart';
// import 'package:lottery/app/utils/global_extension.dart';
// import 'package:lottery/app/utils/my_text.dart';
// import 'package:pinput/pinput.dart';
//
// import '../controllers/otp_screen_controller.dart';
//
// class OtpScreenView extends GetView<OtpScreenController> {
//   const OtpScreenView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         body: Column(
//           children: [
//             60.height,
//             Center(
//               child: Image.asset(
//                 AssetsConstant.enterOtp,
//               ),
//             ),
//             20.height,
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15.0),
//                   child: Column(
//                     children: [
//                       Center(
//                         child: MyText.titleLarge(
//                           'We sent a code ',
//                           letterSpacing: 1,
//                           color: AppColors.yellowColor,
//                           fontSize: 21,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 30.0),
//                         child: Center(
//                           child: MyText.titleLarge(
//                             'Enter the OTP code sent to your\nPhone Number.',
//                             textAlign: TextAlign.center,
//                             color: AppColors.blackColor,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             height: 2,
//                           ),
//                         ),
//                       ),
//
//                       Pinput(
//                         length: 6,
//                         showCursor: true,
//                         focusNode: controller.focusNode,
//                         defaultPinTheme: PinTheme(
//                           width: 60,
//                           height: 60,
//                           textStyle: TextStyle(
//                             fontSize: 24,
//                                         fontWeight: FontWeight.w500,
//                                         color: AppColors.otpDigitsColor,
//                           ),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(100),
//                             color: AppColors.whiteColor,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black
//                                     .withOpacity(0.15), // 15% opacity black
//                                 offset: const Offset(2, 2), // X: 2, Y: 2
//                                 blurRadius: 40, // Blur: 40
//                                 spreadRadius: 0, // Spread: 0
//                               ),
//                             ],
//                           ),
//                         ),
//                         controller: controller.pinController,
//                       ),
//
//                       32.height,
//                       buildContinueButton('Sign in'),
//                       25.height,
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.refresh,
//                             size: 22,
//                           ),
//                           5.width,
//                           MyText.bodyMedium(
//                             'Resend',
//                             fontSize: 19,
//                             fontWeight: FontWeight.w600,
//                           )
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   GestureDetector buildContinueButton(String text) {
//     return GestureDetector(
//       onTap: () {
//         controller.verifyOTP();
//       },
//       child: Container(
//         width: Get.width,
//         decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(7),
//             color: AppColors.buttonBackgroundColor),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 15.0),
//           child: Obx(
//             () => Center(
//               child: controller.isLoading.value
//                   ? CircularProgressIndicator(color: AppColors.whiteColor,)
//                   : MyText.titleLarge(
//                       text,
//                       fontSize: 18,
//                       color: AppColors.whiteColor,
//                     ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
