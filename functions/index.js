const admin = require("firebase-admin");

// Initialize Firebase Admin SDK (only once, here in index.js)
admin.initializeApp();

// // Import and export the v2 function (createDailyLotteries)
const createLottery = require("./createLottery");
exports.createDailyLotteries = createLottery.createDailyLotteries;

// // Import and export the v2 function (createOrder)
const createOrder = require("./createOrder");
exports.createOrder = createOrder.createOrder;

// Import and export the v2 function (announceLotteryWinners)
const announceWinners = require("./announceWinners");
exports.announceLotteryWinners = announceWinners.announceLotteryWinners;

// Import and export the v2 function (autoPurchaseLottery)
const autoPurchaseLottery = require("./autoPurchaselottery");
exports.autoPurchaseLottery = autoPurchaseLottery.autoPurchaseLottery;