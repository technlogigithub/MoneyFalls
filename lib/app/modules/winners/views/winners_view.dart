import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/app/utils/constants.dart';
import 'package:lottery/app/utils/global_extension.dart';
import 'package:lottery/app/utils/my_text.dart';
import '../../../services/user_data.dart';
import '../controllers/winners_controller.dart';

List<Map<String, dynamic>> winnersCountList = []; // New list for count
final currentUserId = FirebaseAuth.instance.currentUser!.uid;
UserController userController = Get.find<UserController>();

class WinnersView extends GetView<WinnersController> {
  const WinnersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: Get.width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF648CBC),
                Color(0xFFFEE800),
              ],
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 8, right: 5),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.black.withAlpha(80),
                      ),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            size: 15,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ),
                    ),
                    10.width,
                    const MyText(
                      'Winners',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              20.height,
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: Get.width,
                      height: Get.height,
                      decoration: const BoxDecoration(
                        color: AppColors.whiteColors,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: controller.lotteryName == 'lottery_1'
                            ? _fetchWinners()
                            : _fetchWinners2(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error fetching winners'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('No winners found'));
                          }

                          final winners = snapshot.data!;
                          return SingleChildScrollView(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 27.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  20.height,
                                  const MyText(
                                    'All Winners',
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.newBlockColor,
                                  ),
                                  20.height,
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: winners.length,
                                    itemBuilder: (context, index) {
                                      final data = winners[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 18.0),
                                        child: GestureDetector(
                                          onTap: () {},
                                          child: Winnerwithprofilleamount(data),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Future<List<Map<String, dynamic>>> _fetchWinners() async {
    try {
      // Step 1: Fetch all documents from the lotteries collection
      final lotteriesSnapshot =
          await FirebaseFirestore.instance.collection('lotteries').get();

      // Step 2: Extract winner IDs, totalUserCount, and createdAt field
      final winnerMap = <String,
          List<Map<String, dynamic>>>{}; // Store a list of wins per winnerId
      for (var dateDoc in lotteriesSnapshot.docs) {
        final lotteryData = dateDoc.data();
        final lottery1Map = lotteryData['lottery_1'] as Map<String, dynamic>?;

        print('this is lottery 1 Map ${lottery1Map}');

        final winnerId = lottery1Map?['winnerID'] as String?;
        print('the winner id is $winnerId');
        final totalUserCount =
            lottery1Map?['totalUserCount'] ?? lottery1Map?['totalUsersCount'];
        final createdAt = lottery1Map?['createdAt'] as Timestamp?;

        if (winnerId != null &&
            winnerId.isNotEmpty &&
            totalUserCount != null &&
            totalUserCount is num) {
          winnerMap.putIfAbsent(winnerId, () => []);
          winnerMap[winnerId]!.add({
            'totalUserCount': totalUserCount,
            'createdAt': createdAt,
          });
        }
      }

      // Step 3: Fetch user data for all winner IDs in a single batch
      final winnersData = <Map<String, dynamic>>[];
      if (winnerMap.isNotEmpty) {
        final idChunks = winnerMap.keys
            .toList()
            .asMap()
            .entries
            .groupBy((entry) => entry.key ~/ 10);
        for (var chunk in idChunks.values) {
          final chunkIds = chunk.map((e) => e.value).toList();
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunkIds)
              .get();

          for (var userDoc in usersSnapshot.docs) {
            final winnerId = userDoc.id;
            for (var win in winnerMap[winnerId]!) {
              final amount = win['totalUserCount'] ?? 0;
              final createdAt = win['createdAt'];

              winnersData.add({
                'name': userDoc.data()['name'] ?? 'Unknown',
                'image': userDoc.data()['profile_image'] ??
                    'assets/images/default_user.png',
                'last_message': 'Won $amount',
                'winner_id': userDoc.data()['uid'] ?? '',
                'createdAt':
                    createdAt != null ? createdAt.toDate().toString() : null,
              });
            }
          }
        }
      }

      // Step 4: Sort winnersData by createdAt in descending order
      winnersData.sort((a, b) {
        final dateA = a['createdAt'] != null
            ? DateTime.parse(a['createdAt'])
            : DateTime(0);
        final dateB = b['createdAt'] != null
            ? DateTime.parse(b['createdAt'])
            : DateTime(0);
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

      return winnersData;
    } catch (e) {
      print('Error fetching winners: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWinners2() async {
    try {
      // Step 1: Fetch all documents from the lotteries collection
      final lotteriesSnapshot =
          await FirebaseFirestore.instance.collection('lotteries').get();

      // Step 2: Extract winner IDs, totalUserCount, and createdAt field
      final winnerMap = <String,
          List<Map<String, dynamic>>>{}; // Store a list of wins per winnerId
      for (var dateDoc in lotteriesSnapshot.docs) {
        final lotteryData = dateDoc.data();
        final lottery1Map = lotteryData['lottery_2'] as Map<String, dynamic>?;

        print('this is lottery 1 Map ${lottery1Map}');

        final winnerId = lottery1Map?['winnerID'] as String?;
        print('the winner id is $winnerId');
        final totalUserCount =
            lottery1Map?['totalUserCount'] ?? lottery1Map?['totalUsersCount'];
        final createdAt = lottery1Map?['createdAt'] as Timestamp?;

        if (winnerId != null &&
            winnerId.isNotEmpty &&
            totalUserCount != null &&
            totalUserCount is num) {
          winnerMap.putIfAbsent(winnerId, () => []);
          winnerMap[winnerId]!.add({
            'totalUserCount': totalUserCount,
            'createdAt': createdAt,
          });
        }
      }

      // Step 3: Fetch user data for all winner IDs in a single batch
      final winnersData = <Map<String, dynamic>>[];
      if (winnerMap.isNotEmpty) {
        final idChunks = winnerMap.keys
            .toList()
            .asMap()
            .entries
            .groupBy((entry) => entry.key ~/ 10);
        for (var chunk in idChunks.values) {
          final chunkIds = chunk.map((e) => e.value).toList();
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunkIds)
              .get();

          for (var userDoc in usersSnapshot.docs) {
            final winnerId = userDoc.id;
            for (var win in winnerMap[winnerId]!) {
              final amount = win['totalUserCount'] ?? 0;
              final createdAt = win['createdAt'];
              final userId = win['uid'];

              winnersData.add({
                'name': userDoc.data()['name'] ?? 'Unknown',
                'image': userDoc.data()['profile_image'] ??
                    'assets/images/default_user.png',
                'last_message': 'Won $amount',
                'winner_id': userId,
                'createdAt':
                    createdAt != null ? createdAt.toDate().toString() : null,
              });
            }
          }
        }
      }

      // Step 4: Sort winnersData by createdAt in descending order
      winnersData.sort((a, b) {
        final dateA = a['createdAt'] != null
            ? DateTime.parse(a['createdAt'])
            : DateTime(0);
        final dateB = b['createdAt'] != null
            ? DateTime.parse(b['createdAt'])
            : DateTime(0);
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

      return winnersData;
    } catch (e) {
      print('Error fetching winners: $e');
      return [];
    }
  }

  GestureDetector Winnerwithprofilleamount(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: (){
        final id = data['winner_id'];
        print('the id is $id');
        Get.toNamed(Routes.OTHER_PERSON_PROFILE,arguments: {
          'userID':id
        });
      },
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 15, top: 8, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.searchFieldBorderColor),
          color: Colors.white,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CachedNetworkImage(
                imageUrl: data['image'],
                errorWidget: (context, url, error) =>
                    Image.network(AssetsConstant.onlineLogo),
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              ),
            ),
            // Image.network(
            //   data['image'] ?? AssetsConstant.onlineLogo,
            //   height: 60,
            //   fit: BoxFit.cover,
            // ),
            20.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    data['name'],
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    color: AppColors.newBlockColor,
                  ),
                  MyText(
                    data['last_message'],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.messageColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Spacer(),
            MyText(
              data['createdAt'].toString().substring(0, 10),
            )
          ],
        ),
      ),
    );
  }
}

extension MapBy on Iterable {
  Map<T, List<S>> groupBy<T, S>(T Function(dynamic) keyFunction) => fold(
        <T, List<S>>{},
        (Map<T, List<S>> map, dynamic item) {
          final key = keyFunction(item);
          map.putIfAbsent(key, () => <S>[]).add(item as S);
          return map;
        },
      );
}
