import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/services/user_data.dart';

class FavouriteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController searchController = TextEditingController();
  RxList<Map<String, dynamic>> chatListWithUnseen =
      <Map<String, dynamic>>[].obs;
  RxInt totalUnseenMessages = 0.obs;

  RxBool isSelectionMode = false.obs;
  RxSet<int> selectedIndexes = <int>{}.obs;
  var selectedChatRoomId = ''.obs;

  var selectedChats = <String>{}.obs;

  void toggleSelection(String chatRoomId) {
    if (selectedChats.contains(chatRoomId)) {
      selectedChats.remove(chatRoomId);
    } else {
      selectedChats.add(chatRoomId);
    }
    isSelectionMode.value = selectedChats.isNotEmpty;
  }

  void clearSelection() {
    selectedChats.clear();
    isSelectionMode.value = false;
  }


  @override
  void onInit() {
    super.onInit();
    getData();
  }

  getData() async {
    _fetchChatList();
    print('cooming in init');
    await updateProfileAndFcmTokens();
  }

  Stream<QuerySnapshot> getChatListStream() {
    String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _fetchChatList() {
    String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      chatListWithUnseen.clear();
      totalUnseenMessages.value = 0;
      return;
    }

    getChatListStream().listen((snapshot) async {
      if (!snapshot.docs.isNotEmpty) {
        chatListWithUnseen.clear();
        totalUnseenMessages.value = 0;
        return;
      }

      List<Map<String, dynamic>> updatedChatList = [];
      int totalUnseen = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String chatRoomId = doc.id;

        QuerySnapshot messages = await _firestore
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .get();

        int unseenCount = 0;
        for (var message in messages.docs) {
          var messageData = message.data() as Map<String, dynamic>;
          List<String> seenBy = List<String>.from(messageData['seenBy'] ?? []);
          if (!seenBy.contains(currentUserId)) {
            unseenCount++;
          }
        }

        updatedChatList.add({
          'chatRoomId': chatRoomId,
          'data': data,
          'unseenCount': unseenCount,
        });

        totalUnseen += unseenCount;
      }

      chatListWithUnseen.value = updatedChatList;
      totalUnseenMessages.value = totalUnseen;

      print('Total unseen messages: ${totalUnseenMessages.value}');
    }, onError: (error) {
      Get.snackbar('Error', 'Failed to load chats: $error');
      chatListWithUnseen.clear();
      totalUnseenMessages.value = 0;
    });
  }

  Future<void> updateProfileAndFcmTokens() async {
    try {
      String currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        return;
      }

      // Get current user's FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Get current user's profile picture from UserController
      String? profilePictureUrl =
          Get.find<UserController>().userData.value?.profileImage.toString();
      print('Profile Picture URL: $profilePictureUrl');

      // Check if the profile picture URL or FCM token is null
      if (profilePictureUrl == null || fcmToken == null) {
        print('Error: Profile picture URL or FCM token is null');
        return;
      }

      // Update profile picture and FCM token in all relevant chats
      QuerySnapshot chatRoomsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      if (chatRoomsSnapshot.docs.isEmpty) {
        print('No chat rooms found for the current user');
        return;
      }

      for (var doc in chatRoomsSnapshot.docs) {
        String chatRoomId = doc.id;
        print('Updating chat room: $chatRoomId');

        // Update participantImages and participantFcmTokens for the current user
        await _firestore.collection('chats').doc(chatRoomId).update({
          'participantImages.$currentUserId': profilePictureUrl,
          'participantFcmTokens.$currentUserId': fcmToken,
        });

        print('Updated profile and FCM token in chat room: $chatRoomId');
      }
    } catch (error) {
      print('Error while updating profile and FCM token: $error');
    }
  }

  Future<void> deleteChat(String chatRoomId) async {
    try {
      // Delete all messages in the subcollection
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat room document itself
      batch.delete(_firestore.collection('chats').doc(chatRoomId));

      await batch.commit();

      Get.snackbar('Deleted', 'Chat has been deleted successfully');

      // Remove this line to stay on the same screen
      // Get.toNamed(Routes.FAVOURITE);

    } catch (e) {
      print('Error deleting chat: $e');
      Get.snackbar('Error', 'Failed to delete chat');
    }
  }

}
