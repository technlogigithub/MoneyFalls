import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class UserStatusService extends GetxService {
  // Define Rx variables to track status
  var isOnline = true.obs;  // Track if the user is online
  var currentUser = FirebaseAuth.instance.currentUser;

  @override
  void onInit() {
    super.onInit();
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == AppLifecycleState.paused.toString()) {
        isOnline.value = false;
        print('App is in background');
        await updateUserStatus(false);
      } else if (message == AppLifecycleState.resumed.toString()) {
        await updateUserStatus(true);
      }
      return Future.value(message);
    });
    updateUserStatus(isOnline.value);
  }
  Future<void> updateUserStatus(bool status) async {
    if (currentUser != null) {
      isOnline.value = status;
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'isOnline': status,
        'lastActive': DateTime.now(),
      });
    }
  }
}
