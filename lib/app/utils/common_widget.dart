import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';
import 'package:lottery/app/routes/app_pages.dart';

import '../modules/settings/controllers/settings_controller.dart';
import '../modules/settings/views/settings_view.dart';

class CommonWidgets {
  // topBar (unchanged)
  static Widget topBar({
    required String label,
    required String hint,
    bool showBackIcon = true,
    double verticalPadding = 20.0,
    bool showArrow = true,
  }) {
    return Stack(
      children: [
        Image.asset(AssetsConstant.topGradient),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              30.height,
              Visibility(
                visible: showArrow,
                child: Container(
                  padding: EdgeInsets.only(left: 8, right: 5),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black.withAlpha(80),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 15,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: MyText(
                  label,
                  fontSize: 32,
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              MyText.titleLarge(
                hint,
                fontSize: 13,
                color: AppColors.whiteColor,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Updated searchDialogue with FCM token storage
  static Widget searchDialogue(TextEditingController searchController) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseMessaging _messaging = FirebaseMessaging.instance; // Add this
    final String currentUserId = _auth.currentUser?.uid ?? 'currentUserId'; // Get current user ID
    RxList<QueryDocumentSnapshot> searchedUsers = <QueryDocumentSnapshot>[].obs;

    void searchUsers(String query) async {
      if (query.isEmpty) {
        searchedUsers.clear();
        return;
      }
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Filter out the current user
      searchedUsers.value = snapshot.docs.where((doc) => doc.id != currentUserId).toList();
    }

    Future<void> createChat(String chatRoomId, String currentUserId, String otherUserId, Map<String, dynamic> otherUserData) async {
      // Get the current user's FCM token
      String? currentUserFcmToken = await _messaging.getToken();

      // Fetch the other user's FCM token (assuming it's stored in their user document)
      DocumentSnapshot otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      String? otherUserFcmToken = otherUserDoc.exists ? (otherUserDoc.data() as Map<String, dynamic>)['fcmToken'] : null;

      DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(chatRoomId).get();
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatRoomId).set({
          'lastMessage': 'Chat started',
          'lastOnline': otherUserData['status'] == 'online' ? FieldValue.serverTimestamp() : null,
          'timestamp': FieldValue.serverTimestamp(),
          'participants': [currentUserId, otherUserId],
          'participantNames': {
            currentUserId: 'Current User', // Replace with actual name from auth
            otherUserId: otherUserData['name'],
          },
          'participantImages': {
            currentUserId: AssetsConstant.onlineLogo, // Replace with actual image from auth
            otherUserId: otherUserData['image'],
          },
          'participantFcmTokens': {
            currentUserId: currentUserFcmToken ?? '',
            otherUserId: otherUserFcmToken ?? '',
          },
        });
      }
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18.9,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    searchUsers(value);
                  },
                  decoration: InputDecoration(
                    hintText: "Search by username or phone number",
                    suffixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Search Results",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Obx(
                    () => searchedUsers.isEmpty
                    ? Text("No users found")
                    : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: List.generate(searchedUsers.length, (index) {
                      var userData = searchedUsers[index].data() as Map<String, dynamic>;
                      String userId = searchedUsers[index].id;
                      return GestureDetector(
                        onTap: () async {
                          String chatRoomId = generateChatRoomId(currentUserId, userId);
                          await createChat(chatRoomId, currentUserId, userId, userData);

                          Get.back(); // Close the dialogue
                          Get.toNamed(
                            Routes.CHAT_SCREEN,
                            arguments: {
                              'chatRoomId': chatRoomId,
                              'userName': userData['name'] ?? 'Unknown',
                              'userImage': userData['image'] ?? AssetsConstant.onlineLogo,
                              'userStatus': userData['status'] ?? 'offline',
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  userData['image'] ?? AssetsConstant.onlineLogo,
                                ),
                                radius: 20,
                                onBackgroundImageError: (_, __) => AssetImage('assets/dummy/user1.png'),
                              ),
                              SizedBox(width: 10),
                              Text(
                                userData['name'] ?? 'Unknown',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -25,
          left: 50,
          child: CustomPaint(
            size: Size(60, 40),
            painter: TrianglePainter(),
          ),
        ),
      ],
    );
  }

  static String generateChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}

// TrianglePainter (unchanged)
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


class CommonWidget {
  // topBar (unchanged)
  static Widget topBars({
    required String label,
    required String hint,
    bool showBackIcon = true,
    double verticalPadding = 20.0,
    bool showArrow = true,
  }) {
    return Stack(
      children: [
        Image.asset(AssetsConstant.topGradient),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              30.height,
              Visibility(
                visible: showArrow,
                child: Container(
                  padding: EdgeInsets.only(left: 8, right: 5),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black.withAlpha(80),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        // Get.offAllNamed(Routes.SETTINGS);
                        Get.toNamed(Routes.SETTINGS);
                        // Get.back();
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 15,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),

                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: MyText(
                  label,
                  fontSize: 32,
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              MyText.titleLarge(
                hint,
                fontSize: 13,
                color: AppColors.whiteColor,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ],
    );
  }}
