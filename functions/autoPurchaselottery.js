const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");

const db = admin.firestore();
// const messaging = admin.messaging();

exports.autoPurchaseLottery = onDocumentCreated(
  {
    document: "lotteries/{date}",
  },
  async (event) => {
    try {
      const date = event.params.date; // e.g., "2025-04-14"
      const lotteryDoc = event.data;
      if (!lotteryDoc.exists) {
        logger.info(`Lottery document ${date} does not exist. Skipping auto-purchase.`);
        return null;
      }

      const lotteryData = lotteryDoc.data();
      const lotteryRef = db.collection("lotteries").doc(date);

      // Check which lotteries (1-10) exist and are active
      const activeLotteries = [];
      for (let i = 1; i <= 10; i++) {
        const lotteryKey = `lottery_${i}`;
        if (lotteryData[lotteryKey] && lotteryData[lotteryKey].status === true) {
          activeLotteries.push(i);
        }
      }

      if (activeLotteries.length === 0) {
        logger.info(`No active lotteries found in document ${date}. Skipping auto-purchase.`);
        return null;
      }

      logger.info(`Active lotteries for ${date}: ${activeLotteries.join(', ')}`);

      // Process users in batches to handle large datasets
      const usersRef = db.collection("users");
      let lastDoc = null;
      const batchSize = 500; // Firestore batch write limit
      let processedUsers = 0;

      while (true) {
        // Query users with pagination
        let query = usersRef.orderBy("username").limit(batchSize);
        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const userSnapshot = await query.get();
        if (userSnapshot.empty) {
          logger.info(`No more users to process for auto-purchase in ${date}.`);
          break;
        }

        lastDoc = userSnapshot.docs[userSnapshot.docs.length - 1];

        // Prepare a batch for Firestore updates
        const batch = db.batch();
        let batchOperations = 0;
        // const notifications = []; // Store notifications to send after the batch

        // Process each user
        for (const userDoc of userSnapshot.docs) {
          const userId = userDoc.id;
          const userData = userDoc.data();
          const userRef = usersRef.doc(userId);

          // Check auto-purchase settings for all 10 lotteries (default to false if not set)
          const userLotterySettings = {};
          let hasAnyAutoPurchase = false;
          
          for (let i = 1; i <= 10; i++) {
            const settingKey = `automaticPurchaseLottery${i}`;
            userLotterySettings[i] = userData[settingKey] === true;
            if (userLotterySettings[i]) {
              hasAnyAutoPurchase = true;
            }
          }

          // Skip if user has no auto-purchase enabled for any lottery
          if (!hasAnyAutoPurchase) {
            continue;
          }

          // Check totalCoins (default to 0 if not set) - handle decimal values
          const totalCoins = parseFloat(userData.totalCoins) || 0;
          const referralUsername = userData.referralUsername || null;
          let coinsToDeduct = 0;
          const purchases = {}; // Track which lotteries were purchased
          
          // Determine cost per lottery based on referral status
          const costPerLottery = referralUsername ? 2.0 : 1.0;
          logger.info(`Processing user ${userId}: ${referralUsername ? 'has referral' : 'no referral'}, cost per lottery: ${costPerLottery}, current coins: ${totalCoins}`);

          // Process each active lottery
          for (const lotteryNumber of activeLotteries) {
            // Check if user has auto-purchase enabled for this lottery and has enough coins
            if (userLotterySettings[lotteryNumber] && (totalCoins - coinsToDeduct) >= costPerLottery) {
              coinsToDeduct += costPerLottery;
              purchases[lotteryNumber] = true;
            } else {
              purchases[lotteryNumber] = false;
            }
          }

          // Skip if no purchases are possible
          if (coinsToDeduct === 0) {
            // Send notification for failed purchase due to insufficient coins
            // if (userData.fcmToken) {
            //   const enabledLotteries = activeLotteries.filter(num => userLotterySettings[num]);
            //   if (enabledLotteries.length > 0) {
            //     const failedMessage = {
            //       notification: {
            //         title: "Failed to Purchase Lottery - Insufficient Coins",
            //         body: `You don't have enough coins to auto-purchase lotteries on ${date}. Each lottery costs ${costPerLottery} coin(s).`,
            //       },
            //       data: {
            //         type: "auto_purchase_failed",
            //         date: date,
            //         enabledLotteries: enabledLotteries.join(','),
            //       },
            //       token: userData.fcmToken,
            //     };
            //     notifications.push({ message: failedMessage, userId });
            //   }
            // }
            continue;
          }

          // Update user's totalCoins - handle decimal precision
          const newTotalCoins = parseFloat((totalCoins - coinsToDeduct).toFixed(2));
          batch.update(userRef, { totalCoins: newTotalCoins });
          batchOperations++;
          
          logger.info(`User ${userId}: Deducted ${coinsToDeduct} coins. Previous: ${totalCoins}, New: ${newTotalCoins}`);

          // Handle referral rewards if user has a referralUsername
          const purchasedLotteries = Object.keys(purchases).filter(key => purchases[key]);
          if (referralUsername && purchasedLotteries.length > 0) {
            try {
              // Query for the referral user by username
              const referralUserQuery = await usersRef.where('username', '==', referralUsername).limit(1).get();
              
              if (!referralUserQuery.empty) {
                const referralUserDoc = referralUserQuery.docs[0];
                const referralUserId = referralUserDoc.id;
                const referralUserRef = usersRef.doc(referralUserId);
                
                // Calculate referral bonus (1.0 coin per purchase)
                const referralBonus = parseFloat((purchasedLotteries.length * 1.0).toFixed(2));
                
                // Add coins to referral user's account
                batch.update(referralUserRef, {
                  totalCoins: admin.firestore.FieldValue.increment(referralBonus)
                });
                batchOperations++;
                
                logger.info(`Added ${referralBonus} coins to referral user ${referralUsername} (${referralUserId}) for user ${userId} purchases of lotteries: ${purchasedLotteries.join(', ')}`);
              } else {
                logger.warn(`Referral user with username ${referralUsername} not found for user ${userId}`);
              }
            } catch (referralError) {
              logger.error(`Error processing referral reward for user ${userId} with referral ${referralUsername}:`, referralError);
              // Continue processing even if referral fails
            }
          }

          // Update lottery document: Add user to purchased lotteries
          for (const lotteryNumber of purchasedLotteries) {
            batch.update(lotteryRef, {
              [`lottery_${lotteryNumber}.users.${userId}`]: userId,
              [`lottery_${lotteryNumber}.totalUsersCount`]: admin.firestore.FieldValue.increment(1),
            });
            batchOperations++;
          }

          // Prepare success notification
          // if (userData.fcmToken && purchasedLotteries.length > 0) {
          //   const purchasedLotteryNames = purchasedLotteries.map(num => `Daily Lottery ${num}`);

          //   const successMessage = {
          //     notification: {
          //       title: "Lottery Purchased Automatically!",
          //       body: `Successfully purchased ${purchasedLotteryNames.join(", ")} on ${date} for ${coinsToDeduct} coin(s).`,
          //     },
          //     data: {
          //       type: "auto_purchase_success",
          //       date: date,
          //       lotteries: purchasedLotteries.join(","),
          //       lotteryNames: purchasedLotteryNames.join(","),
          //       coinsDeducted: coinsToDeduct.toString(),
          //     },
          //     token: userData.fcmToken,
          //   };
          //   notifications.push({ message: successMessage, userId });
          // }

          // Check if batch is nearing the limit (500 operations)
          // Reduced threshold to account for potential referral operations and multiple lottery updates
          if (batchOperations >= 300) {
            await batch.commit();
            logger.info(`Committed batch of ${batchOperations} operations for auto-purchase in ${date}.`);
            batchOperations = 0;
          }
        }

        // Commit any remaining operations in the batch
        if (batchOperations > 0) {
          await batch.commit();
          logger.info(`Committed final batch of ${batchOperations} operations for auto-purchase in ${date}.`);
        }

        // Send notifications after the batch is committed
        // for (const { message, userId } of notifications) {
        //   try {
        //     await messaging.send(message);
        //     logger.info(`Notification sent to user ${userId} for auto-purchase in ${date}.`);
        //   } catch (error) {
        //     logger.error(`Failed to send notification to user ${userId}:`, error);
        //   }
        // }

        processedUsers += userSnapshot.size;
        logger.info(`Processed ${processedUsers} users for auto-purchase in ${date}. Active lotteries: ${activeLotteries.join(', ')}`);
      }

      logger.info(`Completed auto-purchase processing for lottery document ${date}. Processed lotteries: ${activeLotteries.join(', ')}`);
      return null;
    } catch (error) {
      logger.error("Error in autoPurchaseLottery function:", error);
      throw new Error("Failed to process auto-purchase for lottery");
    }
  },
);