import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';
import '../controllers/favourite_controller.dart';

class FavouriteView extends GetView<FavouriteController> {
  FavouriteView({super.key});
  @override
  final FavouriteController controller = Get.put(FavouriteController());

  @override
  Widget build(BuildContext context) {
    controller.onInit();
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF648CBC), Color(0xFFFEE800)],
              stops: [0.19, 0.8],
              begin: Alignment.topRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Chats',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              30.height,
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: Get.width,
                      height: Get.height,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColors,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 27.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              30.height,
                              MyText(
                                'Messages',
                                fontSize: 26,
                                fontWeight: FontWeight.normal,
                                color: AppColors.newBlockColor,
                              ),
                              20.height,
                              Obx(() => Column(
                                children: [
                                  if (controller.isSelectionMode.value)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          controller.deleteChat(String as String);
                                        },
                                      ),
                                    ),
                                  controller.chatListWithUnseen.isEmpty
                                      ? Center(child: Text('No chats available'))
                                      : ListView.builder(
                                    shrinkWrap: true,
                                    physics: BouncingScrollPhysics(),
                                    itemCount: controller.chatListWithUnseen.length,
                                    itemBuilder: (context, index) {
                                      var chat = controller.chatListWithUnseen[index];
                                      var data = chat['data'] as Map<String, dynamic>;
                                      String chatRoomId = chat['chatRoomId'];
                                      int unseenCount = chat['unseenCount'] ?? 0;

                                      List<String> participants = List<String>.from(data['participants']);
                                      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                      String otherUserId = participants.firstWhere((id) => id != currentUserId);
                                      String name = data['participantNames'][otherUserId] ?? 'Unknown';
                                      String image = data['participantImages'][otherUserId] ?? 'https://via.placeholder.com/60';

                                      bool isSelected = controller.selectedChats.contains(chatRoomId);

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 25.0),
                                        child: GestureDetector(
                                          onLongPress: () {
                                            print("loing presas");
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text("Delete Chat"),
                                                  content: Text("Are you sure you want to delete this chat?"),
                                                  actions: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop(); // Close dialog
                                                          },
                                                          child: Text("Cancel"),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            controller.deleteChat(chatRoomId); // Your delete function
                                                            Navigator.of(context).pop(); // Close dialog after delete
                                                          },
                                                          child: Text("Done"),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },


                                          onTap: () {
                                            if (controller.isSelectionMode.value) {
                                              controller.toggleSelection(chatRoomId);
                                            } else {
                                              Get.toNamed(
                                                Routes.CHAT_SCREEN,
                                                arguments: {
                                                  'chatRoomId': chatRoomId,
                                                  'userName': name,
                                                  'userImage': image,
                                                  'userStatus': 'offline',
                                                  'otherUserid': otherUserId
                                                },
                                              );
                                            }
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.only(left: 8, right: 15, top: 8, bottom: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: AppColors.searchFieldBorderColor),
                                                  color: isSelected ? Colors.grey[300] : Colors.white,
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(100),
                                                      child: Image.network(
                                                        image,
                                                        height: 50,
                                                        width: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Image.asset('assets/icon/icon.png', height: 50, width: 50, fit: BoxFit.cover);
                                                        },
                                                      ),
                                                    ),
                                                    20.width,
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          MyText(
                                                            name,
                                                            fontSize: 17,
                                                            fontWeight: FontWeight.normal,
                                                            color: AppColors.newBlockColor,
                                                          ),
                                                          MyText(
                                                            data['lastMessage'] ?? 'No messages yet',
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.normal,
                                                            color: AppColors.messageColor,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    10.width,
                                                    MyText(
                                                      formatTimestamp(data['timestamp']),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.normal,
                                                      color: AppColors.messageColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (unseenCount > 0 && !isSelected)
                                                Positioned(
                                                  right: -5,
                                                  top: -10,
                                                  child: Container(
                                                    margin: const EdgeInsets.only(top: 5),
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: MyText(
                                                      unseenCount.toString(),
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (isSelected)
                                                Positioned(
                                                  right: -5,
                                                  top: -10,
                                                  child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ))

                            ],
                          ),
                        ),
                      ),
                    ),
                    searchField(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  GestureDetector buildContinueButton(String text) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.lightBlueColor),
          color: AppColors.lightBlueColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: MyText.titleLarge(text, fontSize: 18, color: AppColors.whiteColor),
          ),
        ),
      ),
    );
  }

  Positioned searchField() {
    return Positioned(
      top: -30,
      right: 20,
      left: 20,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18.9,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller.searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search ....',
            hintStyle: TextStyle(color: AppColors.searchFieldColor),
            labelStyle: TextStyle(color: AppColors.searchFieldColor),
            suffixIcon: Icon(Icons.search, color: AppColors.searchFieldColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}