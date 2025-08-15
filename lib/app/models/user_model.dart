import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String name;
  String username;
  String email;
  String phoneNumber;
  String referralUsername;
  Timestamp createdAt;
  int streak;
  int followers;
  int following;
  int wins;
  int refWinner;
  String password;
  DateTime lastActive;
  bool isOnline;
  String fcmToken;
  List<String> followersList;
  double totalCoins;
  String profileImage;
  bool automaticPurchaseLottery1;
  bool automaticPurchaseLottery2;
  bool automaticPurchaseLottery3;
  bool automaticPurchaseLottery4;
  bool automaticPurchaseLottery5;
  bool automaticPurchaseLottery6;
  bool automaticPurchaseLottery7;
  bool automaticPurchaseLottery8;
  bool automaticPurchaseLottery9;
  bool automaticPurchaseLottery10;
  int totalWinCount;
  BeneficiaryModel? beneficiary; // Added beneficiary field (non-required)
  String? bankIfsc;
  String? bankAccountNumber;
  String? vpa;
  String? address;
  String? city;
  String? state;
  String? postalCode;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.referralUsername,
    required this.createdAt,
    required this.streak,
    required this.followers,
    required this.following,
    required this.wins,
    required this.refWinner,
    required this.password,
    required this.lastActive,
    required this.isOnline,
    required this.fcmToken,
    required this.followersList,
    this.totalCoins = 0.0,
    this.profileImage = '',
    this.automaticPurchaseLottery1 = false,
    this.automaticPurchaseLottery2 = false,
    this.automaticPurchaseLottery3 = false,
    this.automaticPurchaseLottery4 = false,
    this.automaticPurchaseLottery5 = false,
    this.automaticPurchaseLottery6 = false,
    this.automaticPurchaseLottery7 = false,
    this.automaticPurchaseLottery8 = false,
    this.automaticPurchaseLottery9 = false,
    this.automaticPurchaseLottery10 = false,
    this.totalWinCount = 0,
    this.beneficiary, // Added to constructor as optional
    this.bankIfsc,
    this.bankAccountNumber,
    this.vpa,
    this.address,
    this.city,
    this.state,
    this.postalCode,
  });

  // Convert UserModel to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'referralUsername': referralUsername,
      'createdAt': createdAt,
      'streak': streak,
      'followers': followers,
      'following': following,
      'wins': wins,
      'refWinner': refWinner,
      'password': password,
      'lastActive': lastActive,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'followersList': followersList,
      'totalCoins': totalCoins,
      'profile_image': profileImage,
      'automaticPurchaseLottery1': automaticPurchaseLottery1,
      'automaticPurchaseLottery2': automaticPurchaseLottery2,
      'automaticPurchaseLottery3': automaticPurchaseLottery3,
      'automaticPurchaseLottery4': automaticPurchaseLottery4,
      'automaticPurchaseLottery5': automaticPurchaseLottery5,
      'automaticPurchaseLottery6': automaticPurchaseLottery6,
      'automaticPurchaseLottery7': automaticPurchaseLottery7,
      'automaticPurchaseLottery8': automaticPurchaseLottery8,
      'automaticPurchaseLottery9': automaticPurchaseLottery9,
      'automaticPurchaseLottery10': automaticPurchaseLottery10,
      'totalWinCount': totalWinCount,
      'beneficiary': beneficiary?.toMap(), // Convert beneficiary to map
      'bankIfsc': bankIfsc,
      'bankAccountNumber': bankAccountNumber,
      'vpa': vpa,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
    };
  }

  // Factory method to create UserModel from Firestore data
  factory UserModel.fromFirestore(Map<String, dynamic>? data) {
    // Handle null data case
    if (data == null) {
      return UserModel(
        uid: '',
        name: '',
        username: '',
        email: '',
        phoneNumber: '',
        referralUsername: '',
        createdAt: Timestamp.now(),
        streak: 0,
        followers: 0,
        following: 0,
        wins: 0,
        refWinner: 0,
        password: '',
        lastActive: DateTime.now(),
        isOnline: false,
        fcmToken: '',
        followersList: [],
      );
    }

    // Safe parsing of totalCoins to handle various data types
    double parseTotalCoins() {
      try {
        final coinsData = data['totalCoins'];
        if (coinsData == null) return 0.0;
        if (coinsData is double) return coinsData;
        if (coinsData is int) return coinsData.toDouble();
        if (coinsData is String) return double.tryParse(coinsData) ?? 0.0;
        return 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    // Safe parsing of DateTime
    DateTime parseLastActive() {
      try {
        final lastActiveData = data['lastActive'];
        if (lastActiveData == null) return DateTime.now();
        if (lastActiveData is Timestamp) return lastActiveData.toDate();
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    // Safe parsing of Timestamp
    Timestamp parseCreatedAt() {
      try {
        final createdAtData = data['createdAt'];
        if (createdAtData == null) return Timestamp.now();
        if (createdAtData is Timestamp) return createdAtData;
        return Timestamp.now();
      } catch (e) {
        return Timestamp.now();
      }
    }

    // Safe parsing of followers list
    List<String> parseFollowersList() {
      try {
        final followersData = data['followersList'];
        if (followersData == null) return [];
        if (followersData is List) {
          return followersData.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
        }
        return [];
      } catch (e) {
        return [];
      }
    }

    return UserModel(
      uid: data['uid']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      referralUsername: data['referralUsername']?.toString() ?? '',
      createdAt: parseCreatedAt(),
      streak: data['streak'] is int ? data['streak'] : (int.tryParse(data['streak']?.toString() ?? '0') ?? 0),
      followers: data['followers'] is int ? data['followers'] : (int.tryParse(data['followers']?.toString() ?? '0') ?? 0),
      following: data['following'] is int ? data['following'] : (int.tryParse(data['following']?.toString() ?? '0') ?? 0),
      wins: data['wins'] is int ? data['wins'] : (int.tryParse(data['wins']?.toString() ?? '0') ?? 0),
      refWinner: data['refWinner'] is int ? data['refWinner'] : (int.tryParse(data['refWinner']?.toString() ?? '0') ?? 0),
      password: data['password']?.toString() ?? '',
      lastActive: parseLastActive(),
      isOnline: data['isOnline'] is bool ? data['isOnline'] : false,
      fcmToken: data['fcmToken']?.toString() ?? '',
      followersList: parseFollowersList(),
      totalCoins: parseTotalCoins(),
      profileImage: data['profile_image']?.toString() ?? '',
      automaticPurchaseLottery1: data['automaticPurchaseLottery1'] is bool ? data['automaticPurchaseLottery1'] : false,
      automaticPurchaseLottery2: data['automaticPurchaseLottery2'] is bool ? data['automaticPurchaseLottery2'] : false,
      automaticPurchaseLottery3: data['automaticPurchaseLottery3'] is bool ? data['automaticPurchaseLottery3'] : false,
      automaticPurchaseLottery4: data['automaticPurchaseLottery4'] is bool ? data['automaticPurchaseLottery4'] : false,
      automaticPurchaseLottery5: data['automaticPurchaseLottery5'] is bool ? data['automaticPurchaseLottery5'] : false,
      automaticPurchaseLottery6: data['automaticPurchaseLottery6'] is bool ? data['automaticPurchaseLottery6'] : false,
      automaticPurchaseLottery7: data['automaticPurchaseLottery7'] is bool ? data['automaticPurchaseLottery7'] : false,
      automaticPurchaseLottery8: data['automaticPurchaseLottery8'] is bool ? data['automaticPurchaseLottery8'] : false,
      automaticPurchaseLottery9: data['automaticPurchaseLottery9'] is bool ? data['automaticPurchaseLottery9'] : false,
      automaticPurchaseLottery10: data['automaticPurchaseLottery10'] is bool ? data['automaticPurchaseLottery10'] : false,
      totalWinCount: data['totalWinCount'] is int ? data['totalWinCount'] : (int.tryParse(data['totalWinCount']?.toString() ?? '0') ?? 0),
      beneficiary: BeneficiaryModel.fromFirestore(data['beneficiary']),
      bankIfsc: data['bankIfsc']?.toString(),
      bankAccountNumber: data['bankAccountNumber']?.toString(),
      vpa: data['vpa']?.toString(),
      address: data['address']?.toString(),
      city: data['city']?.toString(),
      state: data['state']?.toString(),
      postalCode: data['postalCode']?.toString(),
    );
  }
}

class BeneficiaryModel {
  String? beneficiaryId;
  String? beneficiaryName;
  String? beneficiaryEmail;
  String? beneficiaryPhone;
  String? beneficiaryCountryCode;
  String? bankAccountNumber;
  String? bankIfsc;
  String? vpa;
  String? beneficiaryAddress;
  String? beneficiaryCity;
  String? beneficiaryState;
  String? beneficiaryPostalCode;
  Timestamp? timestamp;

  BeneficiaryModel({
    this.beneficiaryId,
    this.beneficiaryName,
    this.beneficiaryEmail,
    this.beneficiaryPhone,
    this.beneficiaryCountryCode,
    this.bankAccountNumber,
    this.bankIfsc,
    this.vpa,
    this.beneficiaryAddress,
    this.beneficiaryCity,
    this.beneficiaryState,
    this.beneficiaryPostalCode,
    this.timestamp,
  });

  // Convert BeneficiaryModel to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'beneficiaryEmail': beneficiaryEmail,
      'beneficiaryPhone': beneficiaryPhone,
      'beneficiaryCountryCode': beneficiaryCountryCode,
      'bankAccountNumber': bankAccountNumber,
      'bankIfsc': bankIfsc,
      'vpa': vpa,
      'beneficiaryAddress': beneficiaryAddress,
      'beneficiaryCity': beneficiaryCity,
      'beneficiaryState': beneficiaryState,
      'beneficiaryPostalCode': beneficiaryPostalCode,
      'timestamp': timestamp,
    };
  }

  // Factory method to create BeneficiaryModel from Firestore data
  factory BeneficiaryModel.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return BeneficiaryModel();
    }
    return BeneficiaryModel(
      beneficiaryId: data['beneficiaryId'],
      beneficiaryName: data['beneficiaryName'],
      beneficiaryEmail: data['beneficiaryEmail'],
      beneficiaryPhone: data['beneficiaryPhone'],
      beneficiaryCountryCode: data['beneficiaryCountryCode'],
      bankAccountNumber: data['bankAccountNumber'],
      bankIfsc: data['bankIfsc'],
      vpa: data['vpa'],
      beneficiaryAddress: data['beneficiaryAddress'],
      beneficiaryCity: data['beneficiaryCity'],
      beneficiaryState: data['beneficiaryState'],
      beneficiaryPostalCode: data['beneficiaryPostalCode'],
      timestamp: data['timestamp'],
    );
  }
}