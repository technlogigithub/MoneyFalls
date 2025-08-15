const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");

const db = admin.firestore();

exports.createDailyLotteries = onSchedule(
  {
    schedule: "00 19 * * *", // Runs daily at 12:59 AM IST
    timeZone: "Asia/Kolkata", // Indian Standard Time (IST)
  },
  async (context) => {
    try {
      const lotteriesRef = db.collection("lotteries");

      // Get the current date in YYYY-MM-DD format for the document ID
      const now = new Date();
      const dateStr = now.toISOString().split("T")[0]; // e.g., "2025-04-08"

      // Check if a document for today already exists
      const docRef = lotteriesRef.doc(dateStr);
      const docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        logger.info(`Lottery document for ${dateStr} already exists. Skipping creation.`);
        return null;
      }

      // Create the data for the single document with 10 lotteries
      const lotteryData = {
        activeStatus: true, // ✅ Top-level field outside all lotteries
      };

      // Generate 10 lotteries dynamically
      for (let i = 1; i <= 10; i++) {
        lotteryData[`lottery_${i}`] = {
          name: `Daily Lottery ${i}`,
          status: true,
          totalUsersCount: 0,
          users: {},
          winnerID: "",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
      }

      // Add the single document to Firestore
      await docRef.set(lotteryData);

      logger.info(`Lottery document for ${dateStr} created successfully with activeStatus and 10 lotteries (lottery_1 to lottery_10)!`);
      return null;
    } catch (error) {
      logger.error("Error creating lotteries:", error);
      throw new Error("Failed to create lotteries");
    }
  }
);