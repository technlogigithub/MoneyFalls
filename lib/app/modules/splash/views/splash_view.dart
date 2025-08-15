import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/constants.dart';
import '../controllers/splash_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashView extends GetView<SplashController> {
   SplashView({super.key});
  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBackground(),

          // Centered Logo + Text with Fade Animation
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'Money\n Falls'.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(

                      textStyle: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          color: AppColors.whiteColor,
                          height: 1),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: Duration(seconds: 1))
                    .then()
                    .shimmer(
                      duration: Duration(
                        seconds: 2,
                      ),
                      color: AppColors.whiteColor.withOpacity(0.5),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for Animated Gradient Background
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimateGradient(
      duration: const Duration(seconds: 3),
      primaryColors: [
        Color(0xFFFFE800), // Yellow color
        Color(0xFF648CBC), // Blue color
      ],
      secondaryColors: [
        Color(0xFF648CBC), // Blue color
        Color(0xFFFFE800), // Yellow color
      ],
    );
  }
}

// Future<void>checkUserAlreadyLogin() async {
//   if (FirebaseAuth.instance.currentUser != null) {
//     currentRoute = Routes.BOTTOM_BAR;
//     await FirebaseFirestore.instance.collection("users").doc(
//         FirebaseAuth.instance.currentUser?.uid).update({
//       "isOnline": true,
//       "lastActive": DateTime.now(),
//       "fcmToken": NotificationService.instance.fcmToken
//     });
//
//   } else {
//     currentRoute = Routes.LOGIN_SIGNUP;
//   }
// }
