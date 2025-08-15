import 'package:get/get.dart';

class WinnersController extends GetxController {
  //TODO: Implement WinnersController

  final count = 0.obs;
  RxString lotteryName = ''.obs;
  List<Map<String, dynamic>> userData = [
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 500',
      'new_message': '5',
      'image': 'assets/dummy/user1.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 300',
      'new_message': '5',
      'image': 'assets/dummy/user2.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 200',
      'new_message': '5',
      'image': 'assets/dummy/user3.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 800',
      'new_message': '5',
      'image': 'assets/dummy/user1.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 100',
      'new_message': '5',
      'image': 'assets/dummy/user1.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 5000',
      'new_message': '5',
      'image': 'assets/dummy/user1.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 550',
      'new_message': '5',
      'image': 'assets/dummy/user1.png',
      'last_online': '2 min ago'
    },
    {
      'name': 'John Doe',
      'last_message': 'Won \$ 300',
      'new_message': '5',
      'image': 'assets/dummy/user1.png',
      'last_online': '2 min ago'
    },
  ];

  @override
  void onInit() {
    super.onInit();
    getArguments();
  }

  getArguments() async {
    lotteryName.value = Get.arguments['lotteryId'];
    print('this is lotteryName ${lotteryName}');
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
