import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';
import '../../../utils/constants.dart';
import '../controllers/wallet_controller.dart';
import 'package:lottery/app/modules/wallet/views/withdraw_history_view.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(WalletController());

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
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
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wallet',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    // GestureDetector(
                    //   onTap: () {
                    //     Get.to(() => const WithdrawHistoryView());
                    //   },
                    //   child: Container(
                    //     padding:
                    //         EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(7),
                    //       border: Border.all(color: AppColors.yellowColor),
                    //       color: AppColors.lightBlueColor,
                    //     ),
                    //     child: Center(
                    //       child: Text(
                    //         'Withdraw History',
                    //         style: TextStyle(
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.w500,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              60.height,
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: Get.width,
                      decoration: const BoxDecoration(
                        color: AppColors.whiteColors,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Spacer(),
                          Image.asset(
                            'assets/images/wallet_adding.png',
                            scale: 3,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: buildContinueButton('+ Add Coins', () {
                                    showAddCoinsBottomSheet();
                                  }),
                                ),
                                Expanded(
                                  child:
                                      buildContinueButton('Withdraw Coins', () {
                                    showWithdrawBottomSheet();
                                  }),
                                ),
                              ],
                            ),
                          ),
                          20.height,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: buildContinueButton('Withdraw History', () {
                              Get.to(() => const WithdrawHistoryView());
                            }),
                          ),
                          20.height,
                        ],
                      ),
                    ),
                    balanceCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector buildContinueButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: AppColors.lightBlueColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Obx(() => Center(
                child: (text == 'Withdraw Coins'
                        ? controller.isWithdraw.value
                        : controller.isLoading.value)
                    ? const CircularProgressIndicator(
                        color: AppColors.whiteColor)
                    : MyText.titleLarge(
                        text,
                        fontSize: 15,
                        color: AppColors.whiteColor,
                      ),
              )),
        ),
      ),
    );
  }

  Positioned balanceCard() {
    return Positioned(
      top: -70,
      right: 20,
      left: 20,
      child: Center(
        child: Container(
          width: Get.width * 0.98,
          height: Get.height * 0.25,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/wallet_card.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                'Wallet',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.whiteColor,
              ),
              40.height,
              MyText(
                'Your Coins',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: AppColors.whiteColor,
              ),
              5.height,
              Row(
                children: [
                  Image.asset('assets/images/cruuencyIcon.png', scale: 3),
                  5.width,
                  StreamBuilder<double>(
                    stream: controller.userCoinsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return MyText('...',
                            fontSize: 30, color: AppColors.whiteColor);
                      }
                      if (snapshot.hasError) {
                        return MyText('Err',
                            fontSize: 30, color: AppColors.whiteColor);
                      }
                      final coins = snapshot.data ?? 0.0;
                      return MyText(
                        coins.toStringAsFixed(2),
                        fontSize: 30,
                        color: AppColors.whiteColor,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAddCoinsBottomSheet() {
    Get.bottomSheet(
      backgroundColor: AppColors.whiteColor,
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Coins",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Enter Amount (in INR)",
                border: OutlineInputBorder(),
                hintText: "e.g., 100",
              ),
            ),
            const SizedBox(height: 16),
            buildContinueButton("Continue", controller.onContinuePressed),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void showWithdrawBottomSheet() {
    Get.bottomSheet(
      backgroundColor: AppColors.whiteColor,
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Enter Amount (in INR)",
                border: OutlineInputBorder(),
                hintText: "e.g., 100",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.upiIdController,
              decoration: const InputDecoration(
                labelText: "Enter UPI ID",
                border: OutlineInputBorder(),
                hintText: "e.g., 9876543210@ybl",
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  controller.onWithdrawPressed(
                      upiId: controller.upiIdController.text);
                },
                child: const Text('Withdraw'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
