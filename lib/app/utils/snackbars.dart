import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:toastification/toastification.dart';

class AppSnackBar {
  static void show({
    required ToastificationType type,
    required String message,
    String? description,
  }) {
    toastification.show(
      type: type,
      style: ToastificationStyle.flat,
      title: Text(message),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: highModeShadow,
      showProgressBar: true,
      dragToClose: true,
    );
  }

  static void showSuccess({required String message, String? description}) {
    show(
        type: ToastificationType.success,
        message: message,
        description: description);
  }

  static void showError({required String message, String? description}) {
    show(
        type: ToastificationType.error,
        message: message,
        description: description);
  }

  static void showInfo({required String message, String? description}) {
    show(
        type: ToastificationType.info,
        message: message,
        description: description);
  }

  static void showWarning({required String message, String? description}) {
    show(
        type: ToastificationType.warning,
        message: message,
        description: description);
  }

  static void showSuccesss({required String message}) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showInfos({required String message}) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.info, color: Colors.white),
    );
  }
}
