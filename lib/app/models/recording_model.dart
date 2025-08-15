import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class Recording {
  String fileName;
  String filePath;
  AudioPlayer? audioPlayer;
  RxInt currentPosition; // To store the current playback position
  RxInt duration; // To store the total duration
  Rx<Duration> finalDuration;
  RxBool isPlaying;
  Recording({
    required this.fileName,
    required this.filePath,
    this.audioPlayer,
    required this.isPlaying,
    required int initialPosition,
    required int totalDuration,
    required Duration checkFinalDuration,
  })  : currentPosition = initialPosition.obs,  // RxInt to update reactively
        finalDuration = checkFinalDuration.obs ,
        duration = totalDuration.obs;  // RxInt to store total duration reactively
}
