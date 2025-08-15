import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants.dart';
import '../../../utils/my_text.dart';
import '../controllers/wallet_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawHistoryView extends StatelessWidget {
  const WithdrawHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WalletController controller = Get.find<WalletController>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF648CBC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Withdraw History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF648CBC), Color(0xFFFEE800)],
            stops: [0.19, 0.8],
            begin: Alignment.topRight,
            end: Alignment.centerLeft,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.whiteColors,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: controller.userWithdrawRequestsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return const Center(
                          child: Text('No withdraw history found.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        Color statusColor;
                        switch (
                            (item['status'] ?? '').toString().toLowerCase()) {
                          case 'paid':
                            statusColor = Colors.green;
                            break;
                          case 'pending':
                            statusColor = Colors.orange;
                            break;
                          case 'processing':
                            statusColor = Colors.blue;
                            break;
                          default:
                            statusColor = Colors.red;
                        }
                        // Format amount
                        String amountStr =
                            '₹' + (item['amount']?.toString() ?? '0');
                        // Format date
                        String dateStr = '';
                        if (item['createdAt'] != null &&
                            item['createdAt'] is Timestamp) {
                          final dt = (item['createdAt'] as Timestamp).toDate();
                          dateStr =
                              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                        }
                        // UPI
                        String upiStr = item['upiId']?.toString() ?? '';
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                                color:
                                    AppColors.lightBlueColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  MyText(
                                    amountStr,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppColors.lightBlueColor,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: MyText(
                                      (item['status'] ?? '')
                                              .toString()
                                              .capitalizeFirst ??
                                          '',
                                      fontSize: 14,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  MyText(
                                    dateStr,
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  MyText(
                                    upiStr,
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
