const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");

const db = admin.firestore();
const messaging = admin.messaging();

exports.announceLotteryWinners = onSchedule(
  {
    schedule: "59 18 * * *", // 7:35 PM daily
    timeZone: "Asia/Kolkata",
  },
  async (context) => {
    try {
      await new Promise((resolve) => setTimeout(resolve, 55000));
      const lotteriesRef = db.collection("lotteries");

      // Get the current date in UTC
      const now = new Date();

      // Always use the previous day's lottery document
      const lotteryDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const dateStr = lotteryDate.toISOString().split("T")[0]; // e.g., "2025-05-24"

      // Get the lottery document for the previous day
      const docRef = lotteriesRef.doc(dateStr);
      const docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        logger.info(`No lottery document found for ${dateStr}. Skipping winner announcement.`);
        return null;
      }

      const lotteryData = docSnapshot.data();
      const updates = {};
      const winners = {};

      // Process each lottery (lottery_1 through lottery_10)
      for (let i = 1; i <= 10; i++) {
        const lotteryKey = `lottery_${i}`;
        const lottery = lotteryData[lotteryKey];

        // Skip if the lottery doesn't exist
        if (!lottery) {
          logger.info(`${lotteryKey} not found in document ${dateStr}. Skipping.`);
          continue;
        }

        // Skip if the lottery is already closed or has no users
        if (!lottery.status) {
          logger.info(`${lotteryKey} in document ${dateStr} is already closed. Skipping.`);
          continue;
        }

        const usersMap = lottery.users || {};
        const userIds = Object.keys(usersMap);

        if (userIds.length === 0) {
          logger.info(`${lotteryKey} in document ${dateStr} has no participants. Closing lottery.`);
          updates[`${lotteryKey}.status`] = false;
          continue;
        }

        // Randomly select a winner
        const winnerId = userIds[Math.floor(Math.random() * userIds.length)];
        const totalUsersCount = lottery.totalUsersCount || 0;

        // Update the lottery data with the winner and close the lottery
        updates[`${lotteryKey}.winnerID`] = winnerId;
        updates[`${lotteryKey}.status`] = false;

        // Store the winner and totalUsersCount for coin update and notification
        winners[lotteryKey] = { winnerId, totalUsersCount };

        logger.info(`Winner for ${lotteryKey} in document ${dateStr}: ${winnerId}`);
      }

      // Update the lottery document with winners and status
      if (Object.keys(updates).length > 0) {
        await docRef.update(updates);
        logger.info(`Updated lottery document ${dateStr} with winners and status.`);
      } else {
        logger.info(`No updates needed for lottery document ${dateStr}.`);
        return null;
      }

      await db
        .collection("lotteryCount")
        .doc("count") // Assuming the document ID is "count"
        .update({
          count: admin.firestore.FieldValue.increment(1),
        });
      // Helper function to get the top 5 referral levels above a user
      const getTopReferrals = async (userId, maxLevels = 5) => {
        const referrals = [];
        let currentUserId = userId;

        for (let level = 1; level <= maxLevels; level++) {
          const userDoc = await db.collection("users").doc(currentUserId).get();
          if (!userDoc.exists) {
            logger.warn(`User ${currentUserId} not found at level ${level}. Stopping referral chain.`);
            break;
          }

          const userData = userDoc.data();
          const referralUsername = userData.referralUsername;

          if (!referralUsername) {
            logger.info(`No referralUsername for user ${currentUserId} at level ${level}. Stopping referral chain.`);
            break;
          }

          // Find the user whose username matches the referralUsername
          const referrerQuery = await db
            .collection("users")
            .where("username", "==", referralUsername)
            .limit(1)
            .get();

          if (referrerQuery.empty) {
            logger.info(`No user found with username ${referralUsername} at level ${level}. Stopping referral chain.`);
            break;
          }

          const referrerDoc = referrerQuery.docs[0];
          const referrerId = referrerDoc.id;
          referrals.push({ id: referrerId, username: referralUsername });

          // Move up to the next level
          currentUserId = referrerId;
        }

        return referrals;
      };

      // Update the totalCoins for each winner, their referrers, and send notifications
      for (const [lotteryKey, { winnerId, totalUsersCount }] of Object.entries(winners)) {
        const userRef = db.collection("users").doc(winnerId);

        // Get the top 5 referrers
        const topReferrals = await getTopReferrals(winnerId, 5);
        const numReferrals = topReferrals.length;

        // Calculate coin distribution
        let winnerCoins, referrerBonus;
        if (numReferrals === 0) {
          // No referrers: Winner gets 100%
          winnerCoins = totalUsersCount;
          referrerBonus = 0;
        } else if (numReferrals === 5) {
          // 5 referrers: Winner gets 95%, referrers share 5% (1% each)
          winnerCoins = totalUsersCount * 0.95;
          referrerBonus = (totalUsersCount * 0.01); // 1% per referrer
        } else {
          // Fewer than 5 referrers: Winner gets (100% - numReferrals%), referrers get 1% each
          const winnerPenalty = numReferrals * 0.01; // e.g., 3% for 3 referrers
          winnerCoins = totalUsersCount * (1 - winnerPenalty); // e.g., 97% for 3 referrers
          referrerBonus = totalUsersCount * 0.01; // 1% per referrer
        }

        // Round to 2 decimal places to avoid floating-point precision issues
        winnerCoins = Number(winnerCoins.toFixed(2));
        referrerBonus = Number(referrerBonus.toFixed(2));

        // Use a transaction to safely update the winner's and referrers' totalCoins
        await db.runTransaction(async (transaction) => {
          // Perform all READs first
          // Read the winner's document
          const userDoc = await transaction.get(userRef);
          if (!userDoc.exists) {
            logger.warn(`User ${winnerId} not found. Skipping coin update and notification for ${lotteryKey}.`);
            return;
          }

          // Read all referrers' documents
          const referrerDocs = [];
          for (const referrer of topReferrals) {
            const referrerRef = db.collection("users").doc(referrer.id);
            const referrerDoc = await transaction.get(referrerRef);
            referrerDocs.push({ ref: referrerRef, doc: referrerDoc, referrer });
          }

          // Now perform all WRITEs
          // Update the winner's totalCoins
          const userData = userDoc.data();
          const currentTotalCoins = userData.totalCoins || 0;
          const newTotalCoins = Number((currentTotalCoins + winnerCoins).toFixed(2));
          transaction.update(userRef, {
            totalCoins: newTotalCoins,
            totalWinCount: admin.firestore.FieldValue.increment(1),
          });
          logger.info(`Updated totalCoins for user ${winnerId} (winner of ${lotteryKey}): ${currentTotalCoins} -> ${newTotalCoins}`);

          // Update the totalCoins for each referrer
          for (const { ref: referrerRef, doc: referrerDoc, referrer } of referrerDocs) {
            if (!referrerDoc.exists) {
              logger.warn(`Referrer ${referrer.id} not found. Skipping coin update and notification.`);
              continue;
            }

            const referrerData = referrerDoc.data();
            const referrerCurrentTotalCoins = referrerData.totalCoins || 0;
            const referrerNewTotalCoins = Number((referrerCurrentTotalCoins + referrerBonus).toFixed(2));

            transaction.update(referrerRef, { totalCoins: referrerNewTotalCoins });
            logger.info(`Updated totalCoins for referrer ${referrer.id} (username: ${referrer.username}): ${referrerCurrentTotalCoins} -> ${referrerNewTotalCoins}`);
          }
        });

        // Fetch the winner's and referrers' data again for notifications (outside the transaction)
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
          logger.warn(`User ${winnerId} not found after transaction. Skipping notification for ${lotteryKey}.`);
          continue;
        }
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        // Send a notification to the winner if they have an fcmToken
        if (fcmToken) {
          const message = {
            notification: {
              title: "Congratulations! You Won!",
              body: `You won a Ticket on ${dateStr}! You've earned ${winnerCoins} coins.`,
            },
            data: {
              type: "lottery_win",
              lotteryKey: lotteryKey,
              date: dateStr,
              coins: winnerCoins.toString(),
            },
            token: fcmToken,
          };

          try {
            await messaging.send(message);

            logger.info(`Notification sent to user ${winnerId} for winning ${lotteryKey}.`);
          } catch (error) {
            logger.error(`Failed to send notification to user ${winnerId}:`, error);
          }
        } else {
          logger.warn(`No fcmToken found for user ${winnerId}. Skipping notification for ${lotteryKey}.`);
        }

        // Send notifications to the referrers
        for (const referrer of topReferrals) {
          const referrerRef = db.collection("users").doc(referrer.id);
          const referrerDoc = await referrerRef.get();

          if (!referrerDoc.exists) {
            logger.warn(`Referrer ${referrer.id} not found after transaction. Skipping notification.`);
            continue;
          }

          const referrerData = referrerDoc.data();
          const referrerFcmToken = referrerData.fcmToken;

          if (referrerFcmToken) {
            // Notification 1: Inform referrer that someone in their referral chain won
            const winNotification = {
              notification: {
                title: "Someone Win in Your Referral Chain!",
                body: `A user in your referral chain won a ticket on ${dateStr}!`,
              },
              data: {
                type: "referral_lottery_win",
                winnerId: winnerId,
                lotteryKey: lotteryKey,
                date: dateStr,
              },
              token: referrerFcmToken,
            };

            try {
              await messaging.send(winNotification);
              logger.info(`Referral win notification sent to referrer ${referrer.id} for ${lotteryKey} win.`);
            } catch (error) {
              logger.error(`Failed to send referral win notification to referrer ${referrer.id}:`, error);
            }

            // Notification 2: Inform referrer of the referral bonus
            const bonusNotification = {
              notification: {
                title: "Referral Bonus!",
                body: `Your referral won a ticket on ${dateStr}! You've earned ${referrerBonus} coins.`,
              },
              data: {
                type: "referral_bonus",
                winnerId: winnerId,
                lotteryKey: lotteryKey,
                date: dateStr,
                coins: referrerBonus.toString(),
              },
              token: referrerFcmToken,
            };

            try {
              await messaging.send(bonusNotification);
              logger.info(`Referral bonus notification sent to referrer ${referrer.id} for ${lotteryKey} win.`);
            } catch (error) {
              logger.error(`Failed to send referral bonus notification to referrer ${referrer.id}:`, error);
            }
          } else {
            logger.warn(`No fcmToken found for referrer ${referrer.id}. Skipping notifications.`);
          }
        }
      }
      // ✅ Set activeStatus to false after all processing is complete
      await docRef.update({ activeStatus: false });


      return null;
    } catch (error) {
      logger.error("Error announcing lottery winners:", error);
      throw new Error("Failed to announce lottery winners");
    }
  },
);