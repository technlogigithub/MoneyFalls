import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/modules/favourite/views/favourite_view.dart';
import 'package:lottery/app/modules/profile/views/profile_view.dart';
import 'package:lottery/app/modules/wallet/views/wallet_view.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/main.dart';
import '../../../routes/app_pages.dart';
import '../../home/views/home_view.dart';

class BottomBarController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  RxList<Map<String, dynamic>> searchedUsers = <Map<String, dynamic>>[].obs;
  var currentIndex = 0.obs; // Already reactive
  var userData = "".obs; // Made reactive for consistency
  var isLoading = false.obs;
  RxBool comingFromBottomBar = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (iscommingFromNotification) {
      currentIndex.value = 3; // Explicitly set value
    }
    fetchUserData();
  }

  void fetchUserData() async {
    if (currentUserId.isNotEmpty) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      userData.value = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? ''
          : '';
    }
  }

  Widget onTapChange(int index) {
    currentIndex.value = index; // Ensure the index is updated reactively
    switch (index) {
      case 0:
        print('Switching to index Case 0: $index');
        return HomeView();
      case 1:
        openDialogue(); // Open dialog without blocking view switch
        return HomeView(); // Use SearchView or create one if needed
      case 2:
        return const WalletView();
      case 3:
        return FavouriteView();
      case 4:
        return ProfileView();
      default:
        print('Switching to default: $index');
        return HomeView();
    }
  }

  void openDialogue() {
    if (currentUserId.isEmpty) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TextEditingController searchController = TextEditingController();

      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          height: 400,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) {
                  searchUsers(value.toString().toLowerCase().trim());
                },
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search by username or phone number",
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                if (isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                } else if (searchedUsers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("No users found"),
                  );
                } else {
                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchedUsers.length,
                      itemBuilder: (context, index) {
                        var user = searchedUsers[index];
                        var userData = user['data'] as Map<String, dynamic>;
                        String userId = user['id'];
                        bool isLastMessageSeen =
                            user['isLastMessageSeen'] ?? false;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              userData['profile_image'] ??
                                  AssetsConstant.onlineLogo,
                            ),
                          ),
                          title: Text(userData['username'] ?? 'Unknown'),
                          subtitle: Text(userData['phoneNumber'] ?? ''),
                          // trailing: user['lastMessage'] != null
                          //     ? Row(
                          //   mainAxisSize: MainAxisSize.min,
                          //   children: [
                          //     Text(
                          //       user['lastMessageTime'] ?? '',
                          //       style: const TextStyle(
                          //         color: Colors.grey,
                          //         fontSize: 12,
                          //       ),
                          //     ),
                          //     const SizedBox(width: 5),
                          //     if (user['lastMessageSender'] == currentUserId)
                          //       Icon(
                          //         Icons.done_all,
                          //         size: 16,
                          //         color: isLastMessageSeen ? Colors.blue : Colors.grey,
                          //       ),
                          //   ],
                          // )
                          //     : null,
                          onTap: () {
                            Get.back();
                            Get.toNamed(Routes.OTHER_PERSON_PROFILE,
                                arguments: {
                                  'userID': userId,
                                });
                          },
                        );
                      },
                    ),
                  );
                }
              }),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    });
  }

  void searchUsers(String query) async {
    if (query.isEmpty) {
      searchedUsers.clear();
      return;
    }

    isLoading.value = true;
    try {
      // Firestore queries (same as before)
      QuerySnapshot usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      QuerySnapshot phoneSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isGreaterThanOrEqualTo: query)
          .where('phoneNumber', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      List<QueryDocumentSnapshot> combinedResults =
          [...usernameSnapshot.docs, ...phoneSnapshot.docs].toSet().toList();

      List<Map<String, dynamic>> userList = [];
      for (var doc in combinedResults) {
        if (doc.id == currentUserId) continue;

        var userData = doc.data() as Map<String, dynamic>;
        String userId = doc.id;

        String? lastMessage;
        String? lastMessageTime;
        String? lastMessageSender;
        bool isLastMessageSeen = false;

        userList.add({
          'id': userId,
          'data': userData,
          'lastMessage': lastMessage,
          'lastMessageTime': lastMessageTime,
          'lastMessageSender': lastMessageSender,
          'isLastMessageSeen': isLastMessageSeen,
        });
      }

      searchedUsers.value = userList;
    } catch (e) {
      Get.snackbar('Error', 'Failed to search users: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
