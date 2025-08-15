const { onCall, HttpsError } = require("firebase-functions/v2/https");
const axios = require("axios");

// ✅ Replace these with your actual production credentials
//const CASHFREE_APP_ID = "938786749be238db75ec7ca81b687839"; // ✅ Production App ID
//const CASHFREE_SECRET_KEY = "cfsk_ma_prod_0ebae42506c356589f53a8ad6f269861_ee089022"; // ✅ Production Secret

const CASHFREE_APP_ID = "938786749be238db75ec7ca81b687839";
//const CASHFREE_SECRET_KEY = "cfsk_ma_test_a4a619ca99cbe910768f1552ae9acd0b_2c580269";
const CASHFREE_SECRET_KEY = "cfsk_ma_prod_0ebae42506c356589f53a8ad6f269861_ee089022";
const CASHFREE_API_URL = "https://api.cashfree.com/pg/orders"; // ✅ Production Endpoint

exports.createOrder = onCall(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    const data = request.data;
    const { orderId, orderAmount, customerDetails } = data;

    if (!orderId || !orderAmount || !customerDetails) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }
    
    console.log("Creating order with Cashfree:", {
               orderId,
               orderAmount,
               customerDetails,
             });

    const orderData = {
      order_id: orderId,
      order_amount: orderAmount,
      order_currency: "INR",
      customer_details: {
        customer_id: customerDetails.customerId,
        customer_email: customerDetails.customerEmail,
        customer_phone: customerDetails.customerPhone,
      },
      order_meta: {
        return_url: "https://your-app.com/return?order_id={order_id}",
        notify_url: "https://your-app.com/notify",
      },
    };

    try {
      const response = await axios.post(CASHFREE_API_URL, orderData, {
        headers: {
          "x-api-version": "2022-09-01", // ✅ Use stable version
          "x-client-id": CASHFREE_APP_ID,
          "x-client-secret": CASHFREE_SECRET_KEY,
          "Content-Type": "application/json",
        },
      });

    console.log("Order created successfully with Cashfree:", response.data);
      return {
        paymentSessionId: response.data.payment_session_id,
        orderId: orderId,
      };
    } catch (error) {
      console.error(
        "Error creating order with Cashfree:",
        error.response ? error.response.data : error.message
      );
      console.error("Error creating order with Cashfree:", error.response ? error.response.data : error.message);
      throw new HttpsError(
        "internal",
        "Failed to create order with Cashfree: " +
        (error.response?.data?.message || error.message)
      );
    }
  }
);
