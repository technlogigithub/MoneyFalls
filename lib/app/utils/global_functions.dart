import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'constants.dart';

class GlobalFunctions {
  static void showProgressDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Getting the ticket...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              CircularProgressIndicator(
                color: AppColors.blackColor,
                strokeWidth: 3.5,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideProgressDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}