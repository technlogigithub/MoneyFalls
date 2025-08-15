import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Add this for storage
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:waveform_recorder/waveform_recorder.dart';
import 'dart:io'; // Add this for File
import '../../../models/recording_model.dart';
import 'package:http/http.dart' as http;

import '../../../routes/app_pages.dart';
import '../../../services/get_server_key.dart'; // Add this

class ChatScreenController extends GetxController {
  final TextEditingController textEditingController = TextEditingController();
  RxBool isTextFieldEmpty = true.obs;
  WaveformRecorderController waveController = WaveformRecorderController();
  Rxn<XFile> recordingFile = Rxn<XFile>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Add Firebase Storage
  RxString chatRoomId = ''.obs;
  RxString userName = ''.obs;
  RxString userImage = ''.obs;
  RxString userStatus = ''.obs;
  // Replace with your FCM Server Key from Firebase Console > Cloud Messaging
   RxString fcmServerKey = 'YOUR_FCM_SERVER_KEY'.obs;


  final AudioPlayer audioPlayer = AudioPlayer();
  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  RxString otherUserid= ''.obs;

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Future<void> sendMessage(String chatRoomId, String message, String userId, {String? imageUrl, String? voiceUrl}) async {
  //   if (message.trim().isEmpty && imageUrl == null && voiceUrl == null) return;
  //
  //   // Prepare message data
  //   Map<String, dynamic> messageData = {
  //     'text': message.isNotEmpty ? message : '',
  //     'userId': userId,
  //     'isMe': true,
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'imageUrl': imageUrl, // Add image URL if present
  //     'voiceUrl': voiceUrl, // Add voice URL if present
  //   };
  //
  //   // Add message to the messages subcollection
  //   await _firestore.collection('chats').doc(chatRoomId).collection('messages').add(messageData);
  //
  //   // Update chat metadata
  //   await _firestore.collection('chats').doc(chatRoomId).update({
  //     'lastMessage': message.isNotEmpty ? message : (imageUrl != null ? 'Image' : 'Voice message'),
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'lastOnline': FieldValue.serverTimestamp(),
  //   });
  //
  //   // Send notification to the other user
  //   await sendNotification(chatRoomId, userId, message.isNotEmpty ? message : (imageUrl != null ? 'Sent an image' : 'Sent a voice message'));
  //
  //   textEditingController.clear();
  //   isTextFieldEmpty.value = true;
  // }


  Future<void> sendMessage(String chatRoomId, String message, String userId,
      {String? imageUrl, String? voiceUrl}) async {
    if (message.trim().isEmpty && imageUrl == null && voiceUrl == null) return;

    Map<String, dynamic> messageData = {
      'text': message.isNotEmpty ? message : null,
      'userId': userId,
      'isMe': true,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'seenBy': [userId], // Initialize with the sender's ID
    };

    await _firestore.collection('chats').doc(chatRoomId).collection('messages').add(messageData);

    // Update the chat document with the last message and reset lastMessageSeenBy
    await _firestore.collection('chats').doc(chatRoomId).update({
      'lastMessage': message.isNotEmpty ? message : (imageUrl != null ? 'Image' : 'Voice message'),
      'timestamp': FieldValue.serverTimestamp(),
      'lastOnline': FieldValue.serverTimestamp(),
      'lastMessageSeenBy': [userId], // Only the sender has seen it initially
    });

    await sendNotification(chatRoomId, userId,
        message.isNotEmpty ? message : (imageUrl != null ? 'Sent an image' : 'Sent a voice message'));

    textEditingController.clear();
    isTextFieldEmpty.value = true;
  }

  void _markMessagesAsSeen() async {
    if (FirebaseAuth.instance.currentUser!.uid.isEmpty) return;

    QuerySnapshot messages = await _firestore
        .collection('chats')
        .doc(chatRoomId.value)
        .collection('messages')
        .where('userId', isNotEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var message in messages.docs) {
      var messageData = message.data() as Map<String, dynamic>;
      List<String> seenBy = List<String>.from(messageData['seenBy'] ?? []);
      if (!seenBy.contains(FirebaseAuth.instance.currentUser!.uid)) {
        seenBy.add(FirebaseAuth.instance.currentUser!.uid);
        batch.update(message.reference, {'seenBy': seenBy});
      }
    }
    await batch.commit();

    // Update lastMessageSeenBy in the chat document
    QuerySnapshot lastMessageSnapshot = await _firestore
        .collection('chats')
        .doc(chatRoomId.value)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastMessageSnapshot.docs.isNotEmpty) {
      var lastMessage = lastMessageSnapshot.docs.first;
      var lastMessageData = lastMessage.data() as Map<String, dynamic>;
      List<String> seenBy = List<String>.from(lastMessageData['seenBy'] ?? []);
      await _firestore.collection('chats').doc(chatRoomId.value).update({
        'lastMessageSeenBy': seenBy,
      });
    }
  }



  Future<void> sendNotification(String chatRoomId, String senderId, String message) async {
    try {
      // Fetch the chat document to get participant FCM tokens
      DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(chatRoomId).get();
      if (!chatDoc.exists) return;

      var chatData = chatDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(chatData['participants']);
      String recipientId = participants.firstWhere((id) => id != senderId);
      String? recipientFcmToken = chatData['participantFcmTokens'][recipientId];
      String? currentUserName = chatData['participantNames'][FirebaseAuth.instance.currentUser?.uid];


      if (recipientFcmToken == null || recipientFcmToken.isEmpty) {
        print('Recipient FCM token not found');
        return;
      }


      await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/lotteryapp-a5eab/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $fcmServerKey',
        },
        body: jsonEncode(<String, dynamic>{
          "message": {
            "token":
            recipientFcmToken,
            "notification": {
              "body": textEditingController.text.toString(),
              "title": 'New Message from $currentUserName',
            },
            "data": {
              "type": "chat",
              "chatRoomId": "chat_123",
              "userName": "Zain",
              "userImage": "https://yourcdn.com/avatar.jpg"
            }
          }
        }),
      );
      print('toen');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Upload image to Firebase Storage and return URL
  Future<String?> uploadImage(XFile imageFile, String chatRoomId, String userId) async {
    try {
      String fileName = 'images/$chatRoomId/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      await ref.putFile(File(imageFile.path));
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload voice recording to Firebase Storage and return URL
  Future<String?> uploadVoice(String filePath, String chatRoomId, String userId) async {
    try {
      String fileName = 'voice/$chatRoomId/${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      Reference ref = _storage.ref().child(fileName);
      await ref.putFile(File(filePath));
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading voice: $e');
      return null;
    }
  }

  String formatDuration(int milliseconds) {
    int minutes = milliseconds ~/ 60000;
    int seconds = (milliseconds % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}.${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> playRecording(Recording recording) async {
    recording.isPlaying.value = true;
    if (recording.audioPlayer != null) {
      await recording.audioPlayer!.stop();
    }
    final audioPlayer = AudioPlayer();
    recording.audioPlayer = audioPlayer;
    await audioPlayer.play(
      DeviceFileSource(recording.filePath),
      position: Duration(milliseconds: recording.currentPosition.value),
    );
    audioPlayer.onPositionChanged.listen((position) {
      recording.currentPosition.value = position.inMilliseconds;
    });
    audioPlayer.onDurationChanged.listen((duration) {
      recording.duration.value = duration.inMilliseconds;
    });
    audioPlayer.onPlayerComplete.listen((event) {
      recording.currentPosition.value = 0;
      recording.isPlaying.value = false;
    });
  }

  Future<void> seekAudio(Recording recording, int position) async {
    if (recording.audioPlayer != null) {
      await recording.audioPlayer!.seek(Duration(milliseconds: position));
      recording.currentPosition.value = position;
    }
  }



  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }


  @override
  void onInit() {
    super.onInit();
    getArguments();
    getTokenFromServer();
    _markMessagesAsSeen();
    audioPlayer.onDurationChanged.listen((Duration d) {
      totalDuration.value = d;
    });

    audioPlayer.onPositionChanged.listen((Duration p) {
      currentPosition.value = p;
    });

    audioPlayer.onPlayerComplete.listen((event) {
      isPlaying.value = false;
      currentPosition.value = Duration.zero;
    });
  }

  void getArguments() {
    chatRoomId.value = Get.arguments['chatRoomId'] ?? 'defaultChatRoom';
    userName.value = Get.arguments['userName'] ?? 'Unknown';
    userImage.value = Get.arguments['userImage'] ?? AssetsConstant.onlineLogo;
    print('got the arguments ${userImage.value}');
    userStatus.value = Get.arguments['userStatus'] ?? 'offline';
    otherUserid.value = Get.arguments['otherUserid'] ?? '';
  }

  getTokenFromServer() async{
    final get = GetServerKey();
     fcmServerKey.value = await get.serverToken();
     print('got the serverKey $fcmServerKey');
  }


}