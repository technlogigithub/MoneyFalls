import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final Completer<XFile?> completer = Completer<XFile?>();

    // Show bottom sheet with options
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final XFile? image =
                await picker.pickImage(source: ImageSource.camera);
                Get.back(); // Close the bottom sheet
                completer.complete(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
                Get.back(); // Close the bottom sheet
                completer.complete(image);
              },
            ),
          ],
        ),
      ),
      // Ensure the bottom sheet is dismissed when the user presses the back button
      isDismissible: true,
    ).then((_) {
      // If the bottom sheet is dismissed (e.g., by pressing the back button),
      // complete the completer with null if it hasn't been completed yet
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    // Wait for the completer to complete and return the XFile
    return await completer.future;
  }
}