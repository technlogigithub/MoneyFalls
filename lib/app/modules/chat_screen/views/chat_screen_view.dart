import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/full_screen.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';
import 'package:waveform_recorder/waveform_recorder.dart';

import '../../../utils/image_picker.dart';
import '../controllers/chat_screen_controller.dart';

class ChatScreenView extends GetView<ChatScreenController> {
  const ChatScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    // Assume chatRoomId is passed via arguments or some logic

    String userId = FirebaseAuth
        .instance.currentUser!.uid; // Replace with actual user ID logic

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
              buildTopBar(),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: Get.width,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColors,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: controller
                                  .getMessages(controller.chatRoomId.value),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                var messages = snapshot.data!.docs;
                                return ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.all(16),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    var message = messages[index];
                                    var messageData =
                                        message.data() as Map<String, dynamic>;
                                    Timestamp? timestamp =
                                        messageData['timestamp'];
                                    DateTime? messageDate = timestamp?.toDate();

                                    // Check if a date divider is needed
                                    Widget? dateDivider;
                                    if (index < messages.length - 1) {
                                      var prevMessage = messages[index + 1];
                                      var prevMessageData = prevMessage.data()
                                          as Map<String, dynamic>;
                                      DateTime? prevMessageDate =
                                          (prevMessageData['timestamp']
                                                  as Timestamp?)
                                              ?.toDate();
                                      if (messageDate != null &&
                                          prevMessageDate != null) {
                                        if (!_isSameDay(
                                            messageDate, prevMessageDate)) {
                                          dateDivider =
                                              _buildDateDivider(messageDate);
                                        }
                                      }
                                    } else if (messageDate != null) {
                                      // For the oldest message, always show the date
                                      dateDivider =
                                          _buildDateDivider(messageDate);
                                    }
                                    return Column(
                                      children: [
                                        if (dateDivider != null) dateDivider,
                                        chatBubble(
                                          text: messageData['text'] ?? '',
                                          imageUrl: messageData['imageUrl'],
                                          voiceUrl: messageData['voiceUrl'],
                                          timestamp:
                                              messageDate, // Pass the timestamp
                                          isMe: messageData['userId'] == userId,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          chatInputField(controller.chatRoomId.value, userId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Helper to build date divider
  Widget _buildDateDivider(DateTime date) {
    String formattedDate =
        DateFormat('MMMM dd, yyyy').format(date); // e.g., "March 27, 2025"
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: MyText(
              formattedDate,
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }

  // Chat Bubble Widget (unchanged)
  Widget chatBubble({
    required String text,
    String? imageUrl,
    String? voiceUrl,
    DateTime? timestamp,
    required bool isMe,
  }) {
    String formattedTime = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp) // e.g., "09:48 PM"
        : 'N/A';

    return Align(
      alignment: isMe ? Alignment.bottomLeft : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(Get.context!).size.width * 0.7,
                ),
                child: Container(
                  padding: (text.isNotEmpty && imageUrl == null)
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                      : const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        isMe ? const Color(0xFF648CBC) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (text.isNotEmpty)
                        MyText(
                          text,
                          color: isMe ? Colors.white : Colors.black,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      if (imageUrl != null)
                        GestureDetector(
                          onTap: () {
                            Get.to(FullScreen(imageUrl: imageUrl));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text('Error loading image');
                              },
                            ),
                          ),
                        ),
                      if (voiceUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: VoiceMessageWidget(
                              voiceUrl: voiceUrl, isMe: isMe),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2),
            child: MyText(
              formattedTime,
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
          5.height,
        ],
      ),
    );
  }

  // Top Bar (unchanged)
  Padding buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          Container(
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
                child: Icon(Icons.arrow_back_ios,
                    size: 15, color: AppColors.whiteColor),
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 15.0).copyWith(right: 8),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Obx(
                      () => GestureDetector(
                    onTap: () {
                      Get.toNamed(Routes.OTHER_PERSON_PROFILE, arguments: {
                        'userID': controller.otherUserid.value,
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                          (controller.userImage.value.isEmpty ||
                              controller.userImage.value == 'null')
                              ? AssetsConstant.onlineLogo
                              : controller.userImage.value,
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.green,
                    border: Border.all(color: AppColors.whiteColor),
                  ),
                ),
              ],
            ),
          ),
          Obx(
                () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(controller.userName.value,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                MyText('online',
                    fontSize: 9,
                    fontWeight: FontWeight.normal,
                    color: Colors.white),
              ],
            ),
          ),

          Spacer(), // Pushes the delete icon to the far right

          // GestureDetector(
          //   onTap: () {
          //     // Your delete action here
          //     print('Delete icon tapped'+controller.chatRoomId.toString());
          //     controller.deleteChat(controller.chatRoomId.toString());
          //   },
          //   child: Icon(
          //     Icons.delete,
          //     color: Colors.white,
          //     size: 24,
          //   ),
          // ),
        ],
      ),
    );
  }

  // Input Field with Firebase Integration

  Widget chatInputField(String chatRoomId, String userId) {
    final ChatScreenController controller =
        Get.find<ChatScreenController>(); // Assuming controller is injected

    return ListenableBuilder(
      listenable: controller.waveController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: controller.waveController.isRecording == true
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: WaveformRecorder(
                          height: 48,
                          waveColor: AppColors.yellowColor,
                          durationTextStyle:
                              const TextStyle(color: Colors.black),
                          controller: controller.waveController,
                          onRecordingStopped: () async {
                            controller.audioPlayer.stop();
                            controller.isPlaying.value = false;
                            controller.currentPosition.value = Duration.zero;
                            controller.totalDuration.value = Duration.zero;
                          },
                          onRecordingStarted: () async {
                            // Handle recording start if needed
                          },
                        ),
                      )
                    : controller.waveController.file?.path != null
                        ? Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    if (controller.isPlaying.value) {
                                      await controller.audioPlayer.pause();
                                      controller.isPlaying.value = false;
                                    } else {
                                      final path =
                                          controller.waveController.file?.path;
                                      if (path != null) {
                                        await controller.audioPlayer
                                            .play(DeviceFileSource(path));
                                        controller.isPlaying.value = true;
                                      }
                                    }
                                  } catch (e) {
                                    print("Audio playback error: $e");
                                  }
                                },
                                child: Obx(
                                  () => Icon(
                                    controller.isPlaying.value
                                        ? Icons.pause
                                        : Icons.play_arrow_outlined,
                                  ),
                                ),
                              ),
                              Obx(
                                () => Expanded(
                                  child: controller
                                              .totalDuration.value.inSeconds >
                                          0
                                      ? Slider(
                                          value: controller
                                              .currentPosition.value.inSeconds
                                              .toDouble(),
                                          max: controller
                                              .totalDuration.value.inSeconds
                                              .toDouble(),
                                          onChanged: (value) {
                                            controller.audioPlayer.seek(
                                                Duration(
                                                    seconds: value.toInt()));
                                          },
                                        )
                                      : Slider(
                                          value: 0,
                                          max: 1,
                                          onChanged: null,
                                        ),
                                ),
                              ),
                              Obx(
                                () => Text(
                                  '${controller.formatTime(controller.currentPosition.value)} / ${controller.formatTime(controller.totalDuration.value)}',
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: controller.textEditingController,
                            onChanged: (value) {
                              controller.isTextFieldEmpty.value =
                                  value.trim().isEmpty;
                            },
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              prefixIcon: Transform.rotate(
                                angle: 45,
                                child: GestureDetector(
                                  onTap: () async {
                                    final picker =
                                        await ImagePickerUtil.pickImage();
                                    if (picker != null) {
                                      String? imageUrl =
                                          await controller.uploadImage(
                                              picker, chatRoomId, userId);
                                      print('We got the image url $imageUrl');
                                      if (imageUrl != null) {
                                        await controller.sendMessage(
                                            chatRoomId, '', userId,
                                            imageUrl: imageUrl);
                                      }
                                    }
                                  },
                                  child: const Icon(Icons.attach_file,
                                      color: AppColors.lightBlueColor),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => controller.isTextFieldEmpty.value
                    ? controller.waveController.file?.path != null
                        ? Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final path =
                                      controller.waveController.file?.path;
                                  if (path != null) {
                                    final file = File(path);
                                    if (await file.exists()) {
                                      await file.delete();
                                      controller.waveController.clear();
                                      controller.audioPlayer.stop();
                                      controller.currentPosition.value =
                                          Duration.zero;
                                      controller.totalDuration.value =
                                          Duration.zero;
                                    }
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 15,
                                  child: Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              GestureDetector(
                                onTap: () async {
                                  String? filePath = await controller
                                      .waveController.file?.path;
                                  if (filePath != null) {
                                    String? voiceUrl =
                                        await controller.uploadVoice(
                                            filePath, chatRoomId, userId);
                                    if (voiceUrl != null) {
                                      await controller.sendMessage(
                                          chatRoomId, '', userId,
                                          voiceUrl: voiceUrl);
                                      final file = File(filePath);
                                      if (await file.exists()) {
                                        await file.delete();
                                        controller.waveController.clear();
                                        controller.audioPlayer.stop();
                                        controller.currentPosition.value =
                                            Duration.zero;
                                        controller.totalDuration.value =
                                            Duration.zero;
                                      }
                                    }
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFF648CBC),
                                  child: Icon(
                                    Icons.done,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          )
                        : GestureDetector(
                            onTap: () async {
                              try {
                                if (controller.waveController.isRecording) {
                                  await controller.waveController
                                      .stopRecording();
                                  // Upload happens in onRecordingStopped callback
                                } else {
                                  await controller.waveController
                                      .startRecording();
                                }
                              } catch (e) {
                                print('Error with recording: $e');
                              }
                            },
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF648CBC),
                              child: Icon(
                                controller.waveController.isRecording
                                    ? Icons.stop
                                    : Icons.mic,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF648CBC),
                        child: GestureDetector(
                          onTap: () => controller.sendMessage(
                            chatRoomId,
                            controller.textEditingController.text,
                            userId,
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// New widget for voice message playback
class VoiceMessageWidget extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;

  const VoiceMessageWidget({required this.voiceUrl, required this.isMe});

  @override
  _VoiceMessageWidgetState createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => position = p);
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: widget.isMe ? Colors.white : Colors.black,
          ),
          onPressed: () async {
            if (isPlaying) {
              await _audioPlayer.pause();
              setState(() => isPlaying = false);
            } else {
              await _audioPlayer.play(UrlSource(widget.voiceUrl));
              setState(() => isPlaying = true);
            }
          },
        ),
        Expanded(
          child: Slider(
            activeColor: widget.isMe ? Colors.white : Colors.black,
            inactiveColor: widget.isMe ? Colors.white54 : Colors.grey,
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble(),
            onChanged: (value) async {
              final newPosition = Duration(seconds: value.toInt());
              await _audioPlayer.seek(newPosition);
              setState(() => position = newPosition);
            },
          ),
        ),
        Text(
          _formatDuration(position),
          style: TextStyle(color: widget.isMe ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
