import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lottery/app/services/user_data.dart';
import 'package:lottery/app/utils/snackbars.dart';

class WalletController extends GetxController {
  final userController = Get.find<UserController>();
  late CFPaymentGatewayService cfPaymentGatewayService;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  TextEditingController amountController = TextEditingController();
  TextEditingController upiIdController = TextEditingController();

  late double _lastPaymentAmount;
  RxBool isLoading = false.obs;
  RxBool isWithdraw = false.obs;

  static const String _baseUrl = 'https://api.cashfree.com/pg/orders';
  static const String _clientId = '938786749be238db75ec7ca81b687839';
  static const String _clientSecret =
      'cfsk_ma_prod_0ebae42506c356589f53a8ad6f269861_ee089022';
  static const String _apiVersion = '2022-09-01';

  @override
  void onInit() {
    super.onInit();
    cfPaymentGatewayService = CFPaymentGatewayService();
    cfPaymentGatewayService.setCallback(verifyPayment, onError);
  }

  verifyPayment(String orderId) {
    print("Verify: $orderId");
    print("Payment completed successfully!");
    AppSnackBar.showSuccess(message: "Payment completed successfully!");
    updateCoinsInFirebase(_lastPaymentAmount);
    _lastPaymentAmount = 0;
  }

  onError(CFErrorResponse errorResponse, String orderId) {
    print("Error: 27${errorResponse.getMessage()} 27 for order: $orderId");
    AppSnackBar.showError(
        message: "Payment Failed: ${errorResponse.getMessage()}");
  }

  Future<void> initiatePayment(double amount) async {
    try {
      _lastPaymentAmount = amount;
      final orderId = "order_${DateTime.now().millisecondsSinceEpoch}";
      final paymentSessionId =
          await createOrder(amount, orderId); // pass orderId

      if (paymentSessionId == null) {
        AppSnackBar.showError(message: "Failed to create payment session");
        return;
      }

      CFSession? cfSession = CFSessionBuilder()
          .setEnvironment(CFEnvironment.PRODUCTION)
          .setOrderId(orderId) // same order ID as above
          .setPaymentSessionId(paymentSessionId)
          .build();

      var cfWebCheckout =
          CFWebCheckoutPaymentBuilder().setSession(cfSession).build();
      isLoading.value = false;
      cfPaymentGatewayService.doPayment(cfWebCheckout);
    } catch (e) {
      log("Error during payment: $e");
      AppSnackBar.showError(message: 'Payment error: $e');
    }
  }

  Future<void> updateCoinsInFirebase(double amount) async {
    int coinsToAdd = amount.toInt();
    print('The total coins are now $coinsToAdd');
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      await userRef.update({
        'totalCoins': FieldValue.increment(coinsToAdd),
      });
      print("Coins updated successfully!");
      userController.refreshUserData();
    } catch (e) {
      print("Error updating coins: $e");
      AppSnackBar.showError(message: 'Error updating coins: $e');
    }
  }

  Future<String?> createOrder(double amount, String orderId) async {
    print('createOrderAmount: $amount, orderId: $orderId, userId: $userId');

    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createOrder');
      final result = await callable.call({
        "orderId": orderId,
        "orderAmount": amount,
        "customerDetails": {
          "customerId": userId,
          "customerEmail": "user@example.com", // Replace with actual user email
          "customerPhone": "9876543210", // Replace with actual user phone
        },
      });

      final paymentSessionId = result.data["paymentSessionId"];
      log("Payment Session ID: $paymentSessionId");

      return paymentSessionId;
    } catch (e) {
      log("Error creating order: $e");
      AppSnackBar.showError(message: 'Error creating order: $e');
      return null;
    }
  }

  void onContinuePressed() {
    String amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      Get.snackbar("Error", "Please enter an amount");
      return;
    }

    double amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      Get.snackbar("Error", "Please enter a valid amount");
      return;
    }

    isLoading.value = true;

    Get.back();
    print('amount is $amountText');
    initiatePayment(amount);

    amountController.clear();
  }

  Future<String?> getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payout/v1/authorize'),
        headers: {
          'X-Client-Id': _clientId,
          'X-Client-Secret': _clientSecret,
          'Content-Type': 'application/json',
          'x-api-version': _apiVersion,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['token'];
      } else {
        print('Authentication failed: ${response.body}');
        AppSnackBar.showError(
            message: 'Authentication failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting auth token: $e');
      AppSnackBar.showError(message: 'Error getting auth token: $e');
      return null;
    }
  }

  Future<bool> addBeneficiary({
    required String beneficiaryId,
    required String beneficiaryName,
    required String beneficiaryEmail,
    required String beneficiaryPhone,
    required String beneficiaryCountryCode,
    required String bankAccountNumber,
    required String bankIfsc,
    required String vpa,
    required String beneficiaryAddress,
    required String beneficiaryCity,
    required String beneficiaryState,
    required String beneficiaryPostalCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://sandbox.cashfree.com/payout/beneficiary'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': _apiVersion,
          'x-client-id': _clientId,
          'x-client-secret': _clientSecret,
        },
        body: jsonEncode({
          'beneficiary_id': beneficiaryId,
          'beneficiary_name': beneficiaryName,
          'beneficiary_instrument_details': {
            'bank_account_number': bankAccountNumber,
            'bank_ifsc': bankIfsc,
            'vpa': vpa,
          },
          'beneficiary_contact_details': {
            'beneficiary_email': beneficiaryEmail,
            'beneficiary_phone': beneficiaryPhone,
            'beneficiary_country_code': beneficiaryCountryCode,
            'beneficiary_address': beneficiaryAddress,
            'beneficiary_city': beneficiaryCity,
            'beneficiary_state': beneficiaryState,
            'beneficiary_postal_code': beneficiaryPostalCode,
          },
        }),
      );
      print('Raw response: ${response.body}');
      print('Raw response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("response after adding beneficary ${data}");
        if (data['status'] == 'SUCCESS') {
          AppSnackBar.showSuccess(message: 'Beneficiary added successfully');
          return true;
        } else {
          print('Failed to add ${data['message']}');
          AppSnackBar.showError(
              message: 'Failed to add beneficiary: ${data['message']}');
          return false;
        }
      } else {
        print('error adding account ${response.body}');
        AppSnackBar.showError(
            message: 'Error adding beneficiary: ${response.body}');
        return false;
      }
    } catch (e) {
      print('something went wrong $e');
      AppSnackBar.showError(message: 'Error adding beneficiary: $e');
      return false;
    }
  }

  Future<bool> initiatePayout({
    required String beneficiaryId,
    required double amount,
    required String transferId,
    required String transferMode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://sandbox.cashfree.com/payout/transfers'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': _apiVersion,
          'x-client-id': _clientId,
          'x-client-secret': _clientSecret,
        },
        body: jsonEncode({
          "transfer_id": transferId,
          "transfer_amount": amountController.text.trim(),
          "transfer_mode": transferMode,
          "currency": "INR",
          "beneficiary_details": {"beneficiary_id": beneficiaryId}
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'RECEIVED') {
          print('Payout initiated successfully');
          AppSnackBar.showSuccess(message: 'Payout initiated successfully');
          return true;
        } else {
          print('Failed to initiate payout: ${data['message']}');
          AppSnackBar.showError(
              message: 'Failed to initiate payout: ${data['message']}');
          return false;
        }
      } else {
        print('Error initiating payout: ${response.body}');
        AppSnackBar.showError(
            message: 'Error initiating payout: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error initiating payout: $e');
      AppSnackBar.showError(message: 'Error initiating payout: $e');
      return false;
    }
  }

  void onWithdrawPressed({
    required String upiId,
  }) async {
    String amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      Get.snackbar("Error", "Please enter an amount");
      return;
    }

    double amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      Get.snackbar("Error", "Please enter a valid amount");
      return;
    }

    if ((userController.userData.value?.totalCoins ?? 0) < amount) {
      Get.snackbar("Error", "Insufficient coins for withdrawal");
      return;
    }

    isWithdraw.value = true;

    Get.back();

    sendWithdrawalRequest(amount: amount, upiId: upiId);
    isWithdraw.value = false;
    amountController.clear();
  }

  Future<void> sendWithdrawalRequest({
    required double amount,
    required String upiId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in.');
      }

      if ((userController.userData.value?.totalCoins ?? 0) < amount) {
        throw Exception('Insufficient coins for withdrawal');
      }

      final requestData = {
        'userId': user.uid,
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'upiId': upiId,
      };

      await FirebaseFirestore.instance
          .collection('withdrawRequests')
          .add(requestData);
      AppSnackBar.showSuccess(message: 'Withdrawal request sent successfully');
      await updateCoinsInFirebase(-amount);
    } catch (e) {
      print('Error sending withdrawal request: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> userWithdrawRequestsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('withdrawRequests')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<double> userCoinsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      userController.assignValueToModel(uid);
      if (data == null) return 0.0;
      return (data['totalCoins'] ?? 0).toDouble();
    });
  }
}
