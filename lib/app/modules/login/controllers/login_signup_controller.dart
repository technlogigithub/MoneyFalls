import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/models/user_model.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/services/notification_service.dart';
import 'package:lottery/app/services/user_data.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/snackbars.dart';

class LoginSignupController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  RxBool isLogin = true.obs;
  RxBool showHidePassword = true.obs;
  RxBool isLoading = false.obs;

  RxBool termCondition = false.obs;
  RxBool isEmailVerificationSent = false.obs;

  // storing userId
  RxString refUserID = ''.obs;

  // Controllers for email and password
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // SignUp Controllers
  TextEditingController fullNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController referralUsernameController = TextEditingController();
  TextEditingController newPhoneController = TextEditingController();
  
  UserController _userController = Get.find<UserController>();
  
  // Timer for automatic verification checking
  Timer? _verificationTimer;
  
  void togglePasswordVisibility() {
    showHidePassword.value = !showHidePassword.value;
  }

  void changeScreen(bool login) {
    isLogin.value = login;
    isEmailVerificationSent.value = false; // Reset verification state
  }

  void onOffToggle() {
    showHidePassword.value = !showHidePassword.value;
  }

  // SignIn with Email & Password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    isLoading.value = true;

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        isLoading.value = false;
        AppSnackBar.showError(
          message: 'Please verify your email before signing in. Check your inbox for verification link.',
        );
        
        // Optionally, offer to resend verification email
        _showResendVerificationDialog(userCredential.user!);
        return;
      }

      // Save user data after successful login
      if (userCredential.user != null) {
        print('User logged in: ${userCredential.user!.uid}');
        await _userController.refreshUserData();
      }

      isLoading.value = false;

      // Proceed to the next screen (e.g., Dashboard)
      Get.offAllNamed(Routes.BOTTOM_BAR);
    } catch (e) {
      isLoading.value = false;
      String errorMessage = 'Authentication failed.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format. Please enter a valid email.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed attempts. Please try again later.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection.';
            break;
        }
      }
      
      AppSnackBar.showError(message: errorMessage);
    }
  }

  // SignUp with Email & Password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    isLoading.value = true;

    try {
      if (!termCondition.value) {
        AppSnackBar.showError(message: 'Please accept Terms and Conditions');
        isLoading.value = false;
        return;
      }

      if (fullNameController.text.isEmpty) {
        AppSnackBar.showError(message: 'Please enter your full name');
        isLoading.value = false;
        return;
      }

      if (usernameController.text.isEmpty) {
        AppSnackBar.showError(message: 'Please enter a username');
        isLoading.value = false;
        return;
      }

      // Check if the username already exists in Firestore
      bool usernameExists = await _checkUsernameExists(usernameController.text);
      if (usernameExists) {
        AppSnackBar.showError(
            message: 'Username already exists. Please choose another one.');
        isLoading.value = false;
        return;
      }

      // Validate referral username if provided
      if (referralUsernameController.text.isNotEmpty) {
        bool referralUserName = await _checkUsernameExists(referralUsernameController.text);
        if (!referralUserName) {
          AppSnackBar.showError(message: 'Referral username is not valid');
          isLoading.value = false;
          return;
        }
      }

      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Save user data first
        await _saveUserData(userCredential.user!, email,
            userCredential.user!.displayName ?? "", null);
        
        // Wait a moment before sending verification (helps with delivery)
        await Future.delayed(Duration(milliseconds: 500));
        
        // Send email verification with better error handling
        await _sendVerificationEmailWithRetry(userCredential.user!);
        
        isEmailVerificationSent.value = true;
        isLoading.value = false;
        
        AppSnackBar.showSuccess(
          message: 'Account created successfully! Please check your email for verification link.',
        );
        
        // Show verification dialog with auto-check
        _showEmailVerificationDialog(userCredential.user!);
      }
    } catch (e) {
      isLoading.value = false;
      String errorMessage = 'Sign-up failed.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered. Please use a different email.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format. Please enter a valid email.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled. Please contact support.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection.';
            break;
        }
      }
      
      AppSnackBar.showError(message: errorMessage);
    }
  }

  // Enhanced email verification sending with retry logic
  Future<void> _sendVerificationEmailWithRetry(User user, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        await user.sendEmailVerification();
        print('Verification email sent successfully on attempt ${attempts + 1}');
        return;
      } catch (e) {
        attempts++;
        print('Failed to send verification email (attempt $attempts): $e');
        
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: 2));
        } else {
          // If all retries failed, show error but don't throw
          AppSnackBar.showWarning(
            message: 'Having trouble sending verification email. You can resend it from the verification screen.',
          );
        }
      }
    }
  }

  void _showEmailVerificationDialog(User user) {
    Get.dialog(
      AlertDialog(
        title: Text('Verify Your Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: AppColors.yellowColor,
            ),
            SizedBox(height: 16),
            Text(
              'We\'ve sent a verification link to ${user.email}. Please check your email and click the link to verify your account.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Don\'t forget to check your spam/junk folder!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Once verified, you can sign in to your account.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _stopVerificationCheck();
              Get.back();
              changeScreen(true); // Switch to login screen
            },
            child: Text('Go to Login'),
          ),
          TextButton(
            onPressed: () async {
              await _checkVerificationStatus(user);
            },
            child: Text('I\'ve Verified'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _resendVerificationEmail(user);
            },
            child: Text('Resend Email'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    
    // Start automatic verification checking
    _startVerificationCheck(user);
  }

  // Show resend verification dialog for existing users
  void _showResendVerificationDialog(User user) {
    Get.dialog(
      AlertDialog(
        title: Text('Email Not Verified'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your email is not verified. Please check your email for the verification link.'),
            SizedBox(height: 16),
            Text(
              'Don\'t forget to check your spam/junk folder!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _checkVerificationStatus(user);
            },
            child: Text('I\'ve Verified'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _resendVerificationEmail(user);
            },
            child: Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  // Enhanced resend verification email with better error handling
  Future<void> _resendVerificationEmail(User user) async {
    try {
      // Reload user to get latest info
      await user.reload();
      
      if (user.emailVerified) {
        AppSnackBar.showSuccess(message: 'Email is already verified!');
        await refreshEmailVerificationStatus();
        return;
      }

      // Check for rate limiting (Firebase has built-in rate limiting)
      await user.sendEmailVerification();
      
      AppSnackBar.showSuccess(
        message: 'Verification email sent to ${user.email}! Please check your inbox and spam folder.',
      );
      
      // Provide additional guidance
      Get.snackbar(
        'Email Sent',
        'If you don\'t receive the email within 5 minutes, please check your spam folder or try a different email address.',
        duration: Duration(seconds: 8),
        backgroundColor: Colors.blue[100],
        colorText: Colors.blue[800],
        icon: Icon(Icons.info_outline, color: Colors.blue[800]),
      );
      
    } catch (e) {
      print('Email verification error: $e');
      String errorMessage = 'Failed to send verification email.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please wait a few minutes before requesting another email.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled. Please contact support.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your internet connection.';
            break;
          case 'user-not-found':
            errorMessage = 'User account not found. Please sign up again.';
            break;
        }
      }
      
      AppSnackBar.showError(message: errorMessage);
    }
  }

  // Start automatic verification checking
  void _startVerificationCheck(User user) {
    _stopVerificationCheck(); // Stop any existing timer
    
    _verificationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        await user.reload();
        if (user.emailVerified) {
          timer.cancel();
          Get.back(); // Close verification dialog
          await _userController.refreshUserData();
          Get.offAllNamed(Routes.BOTTOM_BAR);
          AppSnackBar.showSuccess(message: 'Email verified successfully! Welcome aboard!');
        }
      } catch (e) {
        print('Error checking verification status: $e');
        // Don't show error to user, just log it
      }
    });
    
    // Stop checking after 10 minutes to prevent indefinite polling
    Timer(Duration(minutes: 10), () {
      _stopVerificationCheck();
    });
  }

  void _stopVerificationCheck() {
    _verificationTimer?.cancel();
    _verificationTimer = null;
  }

  // Manual verification status check
  Future<void> _checkVerificationStatus(User user) async {
    try {
      await user.reload();
      if (user.emailVerified) {
        _stopVerificationCheck();
        Get.back(); // Close any open dialogs
        await _userController.refreshUserData();
        Get.offAllNamed(Routes.BOTTOM_BAR);
        AppSnackBar.showSuccess(message: 'Email verified successfully! Welcome aboard!');
      } else {
        AppSnackBar.showWarning(
          message: 'Email not yet verified. Please check your inbox and spam folder, then try again.',
        );
      }
    } catch (e) {
      AppSnackBar.showError(message: 'Error checking verification status. Please try again.');
    }
  }

  // Check if current user's email is verified
  Future<bool> checkEmailVerification() async {
    User? user = auth.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data
      return user.emailVerified;
    }
    return false;
  }

  // Method to refresh email verification status
  Future<void> refreshEmailVerificationStatus() async {
    User? user = auth.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        // Update user data in Firestore if needed
        await _userController.refreshUserData();
        Get.offAllNamed(Routes.BOTTOM_BAR);
        AppSnackBar.showSuccess(message: 'Email verified successfully!');
      } else {
        AppSnackBar.showInfo(message: 'Email not yet verified. Please check your inbox.');
      }
    }
  }

  // Debug method for troubleshooting
  Future<void> debugEmailVerification() async {
    User? user = auth.currentUser;
    if (user != null) {
      print('=== EMAIL VERIFICATION DEBUG ===');
      print('User email: ${user.email}');
      print('Email verified: ${user.emailVerified}');
      print('User created: ${user.metadata.creationTime}');
      print('User last sign in: ${user.metadata.lastSignInTime}');
      
      try {
        await user.sendEmailVerification();
        print('Verification email sent successfully');
      } catch (e) {
        print('Error sending verification: $e');
      }
      print('================================');
    }
  }

  Future<void> _saveUserData(
      User user, String email, String name, String? referralUsername) async {
    print('Saving user data to Firestore');
    try {
      // Create user model
      UserModel userModel = UserModel(
        uid: user.uid,
        name: fullNameController.text,
        username: usernameController.text.toString().toLowerCase().trim(),
        email: email,
        phoneNumber: newPhoneController.text,
        referralUsername: referralUsernameController.text.toString().toLowerCase().trim(),
        createdAt: Timestamp.now(),
        streak: 0,
        followers: 0,
        following: 0,
        wins: 0,
        refWinner: 0,
        password: "",
        lastActive: DateTime.now(),
        isOnline: true,
        fcmToken: NotificationService.instance.fcmToken.toString(),
        followersList: [],
        totalCoins: 0,
      );

      // Save the user data to Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(userModel.toMap());
          
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      // Don't throw error as the account is already created
      AppSnackBar.showWarning(message: 'Account created but some data may not be saved properly.');
    }
  }

  // Function to check if the username already exists in Firestore
  Future<bool> _checkUsernameExists(String username) async {
    try {
      String cleanUsername = username.toLowerCase().trim();
      var querySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: cleanUsername)
          .get();
      // If the query returns any documents, the username already exists
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking username: $e");
      return false; // In case of error, allow the username (will be caught later if actually exists)
    }
  }

  Future<void> addFollower() async {
    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(refUserID.value);
      await userRef.update({
        'followersList':
            FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid]),
        'followers': FieldValue.increment(1),
      });
      print(
          'Follower added: ${usernameController.text.toString().trim()} to user: ${refUserID.value}');
    } catch (e) {
      print('Error adding follower: $e');
    }
  }

  // Clean up resources when controller is disposed
  @override
  void onClose() {
    _stopVerificationCheck();
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    usernameController.dispose();
    referralUsernameController.dispose();
    newPhoneController.dispose();
    super.onClose();
  }

  // Reset form data
  void resetForm() {
    emailController.clear();
    passwordController.clear();
    fullNameController.clear();
    usernameController.clear();
    referralUsernameController.clear();
    newPhoneController.clear();
    termCondition.value = false;
    isEmailVerificationSent.value = false;
    showHidePassword.value = true;
  }

  // Method to handle forgot password
  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      AppSnackBar.showSuccess(
        message: 'Password reset email sent! Check your inbox.',
      );
    } catch (e) {
      String errorMessage = 'Failed to send password reset email.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
        }
      }
      
      AppSnackBar.showError(message: errorMessage);
    }
  }
}

// Referral tree functionality (unchanged from your original code)
Future<Map<String, List<Map<String, dynamic>>>> getReferralTree(String userName,
    {int maxLevels = 5}) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, List<Map<String, dynamic>>> referralTree = {
    'level1': [],
    'level2': [],
    'level3': [],
    'level4': [],
    'level5': [],
  };

  Future<List<Map<String, dynamic>>> getReferrals(
      List<String> referUserIds) async {
    try {
      const int chunkSize = 10;
      List<List<String>> chunks = [];
      for (int i = 0; i < referUserIds.length; i += chunkSize) {
        chunks.add(referUserIds.sublist(
            i,
            i + chunkSize > referUserIds.length
                ? referUserIds.length
                : i + chunkSize));
      }

      List<Map<String, dynamic>> allResults = [];

      for (List<String> chunk in chunks) {
        QuerySnapshot querySnapshot = await firestore
            .collection('users')
            .where('referralUsername', whereIn: chunk)
            .get();

        allResults.addAll(querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList());
      }

      return allResults;
    } catch (e) {
      print('Error fetching referrals: $e');
      return [];
    }
  }

  try {
    QuerySnapshot level1Snapshot = await firestore
        .collection('users')
        .where('referralUsername', isEqualTo: userName)
        .get();
    referralTree['level1'] = level1Snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();

    if (referralTree['level1']!.isEmpty || maxLevels < 2) return referralTree;

    List<String> level1Ids = referralTree['level1']!
        .map((user) => user['username'] as String)
        .toList();
    referralTree['level2'] = await getReferrals(level1Ids);

    if (referralTree['level2']!.isEmpty || maxLevels < 3) return referralTree;

    List<String> level2Ids = referralTree['level2']!
        .map((user) => user['username'] as String)
        .toList();
    referralTree['level3'] = await getReferrals(level2Ids);

    if (referralTree['level3']!.isEmpty || maxLevels < 4) return referralTree;

    List<String> level3Ids = referralTree['level3']!
        .map((user) => user['username'] as String)
        .toList();
    referralTree['level4'] = await getReferrals(level3Ids);

    if (referralTree['level4']!.isEmpty || maxLevels < 5) return referralTree;

    List<String> level4Ids = referralTree['level4']!
        .map((user) => user['username'] as String)
        .toList();
    referralTree['level5'] = await getReferrals(level4Ids);

    return referralTree;
  } catch (e) {
    print('Error building referral tree: $e');
    return referralTree;
  }
}

Future<Map<String, List<Map<String, dynamic>>>> fetchReferrals({
  String? userName,
}) async {
  UserController splashController = Get.find<UserController>();
  String currentUserName = userName ?? splashController.userData.value?.username ?? '';
  Map<String, List<Map<String, dynamic>>> referrals =
      await getReferralTree(currentUserName);
  print('currentUserName: ' + referrals.toString());

  return referrals;
}