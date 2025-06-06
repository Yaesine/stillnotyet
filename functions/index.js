// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const {RtcTokenBuilder, RtcRole} = require("agora-token");

const axios = require("axios");

// Add these constants after your existing constants
const APPLE_SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt";
const APPLE_PRODUCTION_URL = "https://buy.itunes.apple.com/verifyReceipt";
// Set your shared secret in Firebase config: firebase functions:config:set apple.shared_secret="YOUR_SECRET"
// Or define it here for testing (but use config in production)
const APPLE_SHARED_SECRET = functions.config().apple?.shared_secret || "a59d6df893014ff289b8ad565bbaff0b";

admin.initializeApp();

// Add this function to your existing index.js file
exports.validateAppleReceipt = onCall(async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const {receiptData, productId} = request.data;
  const userId = request.auth.uid;

  if (!receiptData) {
    throw new functions.https.HttpsError("invalid-argument", "Receipt data is required");
  }

  console.log(`Validating Apple receipt for user ${userId}, product ${productId}`);

  try {
    // First try production URL
    let response = await validateWithApple(APPLE_PRODUCTION_URL, receiptData);

    // If sandbox receipt (status 21007), try sandbox URL
    if (response.data.status === 21007) {
      console.log("Receipt is from sandbox, retrying with sandbox URL");
      response = await validateWithApple(APPLE_SANDBOX_URL, receiptData);
    }

    const validationResult = response.data;

    if (validationResult.status !== 0) {
      console.error(`Invalid receipt status: ${validationResult.status}`);
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid receipt: ${getStatusMessage(validationResult.status)}`,
      );
    }

    // Parse receipt info
    const receipt = validationResult.receipt;
    const latestReceiptInfo = validationResult.latest_receipt_info || [];
    const pendingRenewalInfo = validationResult.pending_renewal_info || [];

    console.log(`Found ${latestReceiptInfo.length} purchases in receipt`);

    // Find the relevant purchase
    const purchase = latestReceiptInfo.find((item) => item.product_id === productId) ||
                    latestReceiptInfo[latestReceiptInfo.length - 1]; // Get latest if specific not found

    if (!purchase) {
      throw new functions.https.HttpsError("not-found", "Purchase not found in receipt");
    }

    console.log(`Processing purchase for product ${purchase.product_id}`);

    // Check if purchase is valid and not expired
    const now = Date.now();
    const expiresDateMs = purchase.expires_date_ms ? parseInt(purchase.expires_date_ms) : null;

    if (expiresDateMs && expiresDateMs < now) {
      console.log("Subscription has expired");
      // Still process it but mark as expired
      await handleExpiredSubscription(userId, purchase);

      return {
        success: true,
        expired: true,
        productId: purchase.product_id,
        expiresDate: new Date(expiresDateMs),
      };
    }

    // Grant the purchase
    await grantPurchase(userId, purchase);

    // Store receipt for future reference and restoration
    await storeReceipt(userId, purchase, receipt, validationResult.latest_receipt);

    // Handle auto-renewal status
    if (pendingRenewalInfo.length > 0) {
      await handlePendingRenewal(userId, pendingRenewalInfo[0]);
    }

    return {
      success: true,
      productId: purchase.product_id,
      expiresDate: expiresDateMs ? new Date(expiresDateMs) : null,
      originalTransactionId: purchase.original_transaction_id,
    };
  } catch (error) {
    console.error("Receipt validation error:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError("internal", "Failed to validate receipt");
  }
});

// Helper function to validate with Apple
async function validateWithApple(url, receiptData) {
  try {
    return await axios.post(url, {
      "receipt-data": receiptData,
      "password": APPLE_SHARED_SECRET,
      "exclude-old-transactions": true,
    }, {
      timeout: 10000, // 10 second timeout
      headers: {
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    console.error("Error calling Apple API:", error.message);
    throw new functions.https.HttpsError("internal", "Failed to contact Apple servers");
  }
}

// Grant purchase to user
async function grantPurchase(userId, purchase) {
  const productId = purchase.product_id;
  const db = admin.firestore();
  const batch = db.batch();

  try {
    const userRef = db.collection("users").doc(userId);

    // Handle different product types
    if (productId.includes("premium")) {
      // Premium subscription
      const expiresDate = new Date(parseInt(purchase.expires_date_ms));
      const subscriptionType = productId.split(".").pop(); // monthly, 3months, 6months

      batch.update(userRef, {
        isPremium: true,
        premiumUntil: admin.firestore.Timestamp.fromDate(expiresDate),
        premiumType: subscriptionType,
        premiumStartDate: admin.firestore.Timestamp.fromDate(new Date(parseInt(purchase.purchase_date_ms))),
        lastReceiptValidation: admin.firestore.FieldValue.serverTimestamp(),
        premiumFeatures: [
          "unlimited_likes",
          "see_who_likes_you",
          "super_likes",
          "rewind",
          "read_receipts",
          "priority_matches",
        ],
      });

      console.log(`Granted premium subscription until ${expiresDate} for user ${userId}`);
    } else if (productId.includes("boost")) {
      // Boost packs
      const boostCount = getBoostCount(productId);

      batch.update(userRef, {
        availableBoosts: admin.firestore.FieldValue.increment(boostCount),
        lastBoostPurchase: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Granted ${boostCount} boosts to user ${userId}`);
    } else if (productId.includes("superlike")) {
      // Super like packs
      const superLikeCount = getSuperLikeCount(productId);

      batch.update(userRef, {
        availableSuperLikes: admin.firestore.FieldValue.increment(superLikeCount),
        lastSuperLikePurchase: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Also update streak data if it exists
      const streakRef = db.collection("users").doc(userId).collection("streak_data").doc("current");
      const streakDoc = await streakRef.get();

      if (streakDoc.exists) {
        batch.update(streakRef, {
          availableSuperLikes: admin.firestore.FieldValue.increment(superLikeCount),
        });
      }

      console.log(`Granted ${superLikeCount} super likes to user ${userId}`);
    }

    await batch.commit();
    console.log(`Successfully granted purchase ${productId} to user ${userId}`);
  } catch (error) {
    console.error("Error granting purchase:", error);
    throw new functions.https.HttpsError("internal", "Failed to grant purchase");
  }
}

// Store receipt for restoration and record keeping
async function storeReceipt(userId, purchase, receipt, latestReceipt) {
  try {
    await admin.firestore().collection("receipts").add({
      userId,
      productId: purchase.product_id,
      transactionId: purchase.transaction_id,
      originalTransactionId: purchase.original_transaction_id,
      purchaseDate: new Date(parseInt(purchase.purchase_date_ms)),
      expiresDate: purchase.expires_date_ms ? new Date(parseInt(purchase.expires_date_ms)) : null,
      validatedAt: admin.firestore.FieldValue.serverTimestamp(),
      environment: receipt.receipt_creation_date_ms ? "production" : "sandbox",
      bundleId: receipt.bundle_id,
      latestReceipt: latestReceipt, // Store for future validations
      isActive: true,
    });

    console.log(`Stored receipt for transaction ${purchase.transaction_id}`);
  } catch (error) {
    console.error("Error storing receipt:", error);
    // Don't throw here, as the purchase was already granted
  }
}

// Handle expired subscriptions
async function handleExpiredSubscription(userId, purchase) {
  try {
    await admin.firestore().collection("users").doc(userId).update({
      isPremium: false,
      premiumExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
      lastExpiredProductId: purchase.product_id,
    });

    console.log(`Marked subscription as expired for user ${userId}`);
  } catch (error) {
    console.error("Error handling expired subscription:", error);
  }
}

// Handle pending renewal info
async function handlePendingRenewal(userId, renewalInfo) {
  try {
    const updates = {
      autoRenewStatus: renewalInfo.auto_renew_status === "1",
      autoRenewProductId: renewalInfo.auto_renew_product_id,
    };

    if (renewalInfo.expiration_intent) {
      updates.expirationIntent = getExpirationIntent(renewalInfo.expiration_intent);
    }

    await admin.firestore().collection("users").doc(userId).update(updates);

    console.log(`Updated renewal info for user ${userId}`);
  } catch (error) {
    console.error("Error handling pending renewal:", error);
  }
}

// Helper functions
function getBoostCount(productId) {
  if (productId.includes("1pack")) return 1;
  if (productId.includes("5pack")) return 5;
  if (productId.includes("10pack")) return 10;
  return 0;
}

function getSuperLikeCount(productId) {
  if (productId.includes("5pack")) return 5;
  if (productId.includes("15pack")) return 15;
  if (productId.includes("30pack")) return 30;
  return 0;
}

function getStatusMessage(status) {
  const statusMessages = {
    21000: "App Store could not read the JSON object",
    21002: "Receipt data is malformed",
    21003: "Receipt could not be authenticated",
    21004: "Shared secret does not match",
    21005: "Receipt server is not currently available",
    21006: "Receipt is valid but subscription has expired",
    21007: "Receipt is from sandbox environment",
    21008: "Receipt is from production environment",
    21009: "Internal data access error",
    21010: "User account not found",
  };

  return statusMessages[status] || "Unknown error";
}

function getExpirationIntent(intent) {
  const intents = {
    "1": "Customer cancelled",
    "2": "Billing error",
    "3": "Customer declined price increase",
    "4": "Product not available",
    "5": "Unknown error",
  };

  return intents[intent] || "Unknown";
}

// Function to restore purchases
exports.restorePurchases = onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;
  const {receiptData} = request.data;

  if (!receiptData) {
    throw new functions.https.HttpsError("invalid-argument", "Receipt data is required");
  }

  console.log(`Restoring purchases for user ${userId}`);

  try {
    // Validate the receipt
    let response = await validateWithApple(APPLE_PRODUCTION_URL, receiptData);

    if (response.data.status === 21007) {
      response = await validateWithApple(APPLE_SANDBOX_URL, receiptData);
    }

    const validationResult = response.data;

    if (validationResult.status !== 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid receipt: ${getStatusMessage(validationResult.status)}`,
      );
    }

    const latestReceiptInfo = validationResult.latest_receipt_info || [];
    const restoredPurchases = [];

    // Process all purchases in the receipt
    for (const purchase of latestReceiptInfo) {
      console.log(`Restoring purchase: ${purchase.product_id}`);

      // Only restore active subscriptions and consumables
      const expiresDateMs = purchase.expires_date_ms ? parseInt(purchase.expires_date_ms) : null;
      const isActiveSubscription = !expiresDateMs || expiresDateMs > Date.now();

      if (isActiveSubscription || !purchase.product_id.includes("premium")) {
        await grantPurchase(userId, purchase);
        restoredPurchases.push({
          productId: purchase.product_id,
          transactionId: purchase.transaction_id,
          expiresDate: expiresDateMs ? new Date(expiresDateMs) : null,
        });
      }
    }

    console.log(`Restored ${restoredPurchases.length} purchases for user ${userId}`);

    return {
      success: true,
      restoredPurchases,
    };
  } catch (error) {
    console.error("Error restoring purchases:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError("internal", "Failed to restore purchases");
  }
});

// Webhook for subscription status updates (optional but recommended)
exports.handleAppleWebhook = functions.https.onRequest(async (req, res) => {
  // Verify the request is from Apple (implement your own verification)
  // Apple Server Notifications for auto-renewable subscriptions

  try {
    const notification = req.body;

    if (!notification || !notification.unified_receipt) {
      res.status(400).send("Invalid notification");
      return;
    }

    console.log("Received Apple webhook notification:", notification.notification_type);

    // Handle different notification types
    switch (notification.notification_type) {
    case "RENEWAL":
    case "INTERACTIVE_RENEWAL":
    case "DID_RECOVER":
      // Process renewal
      await processRenewal(notification);
      break;

    case "CANCEL":
    case "DID_FAIL_TO_RENEW":
    case "REFUND":
      // Handle cancellation/refund
      await processCancellation(notification);
      break;
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("Error processing Apple webhook:", error);
    res.status(500).send("Internal error");
  }
});

exports.generateAgoraToken = onCall(async (request) => {
  // Verify user is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  try {
    const APP_ID = "1abf8e98afd04b01a8637ddc4bfbf3d1";
    const APP_CERTIFICATE = "549ad431723d401ab539ab2513a5b857";

    const channelName = request.data.channelName;
    const uid = request.data.uid || 0;
    const role = RtcRole.PUBLISHER;

    const expirationTimeInSeconds = 3600;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpiredTs,
    );

    console.log(`Generated Agora token for channel: ${channelName}, uid: ${uid}`);

    return {token};
  } catch (error) {
    console.error("Error generating Agora token:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

exports.processAllPendingNotifications = onCall(async (request) => {
  try {
    console.log("Processing all pending notifications...");

    // Get all pending notifications
    const pendingSnapshot = await admin.firestore()
      .collection("notifications")
      .where("status", "==", "pending")
      .get();

    console.log(`Found ${pendingSnapshot.docs.length} pending notifications`);

    const results = {
      total: pendingSnapshot.docs.length,
      processed: 0,
      successful: 0,
      failed: 0,
      errors: [],
    };

    // Process each notification
    for (const notificationDoc of pendingSnapshot.docs) {
      try {
        results.processed++;
        const notification = notificationDoc.data();

        console.log(`Processing notification ${notificationDoc.id}:`, notification.type);

        if (!notification.fcmToken) {
          console.log(`No FCM token for notification ${notificationDoc.id}`);
          await notificationDoc.ref.update({
            status: "error",
            error: "No FCM token available",
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          results.failed++;
          results.errors.push(`No FCM token for ${notificationDoc.id}`);
          continue;
        }

        // Prepare FCM message
        const message = {
          token: notification.fcmToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notification.data || {},
          // iOS specific configuration
          apns: {
            payload: {
              aps: {
                "alert": {
                  title: notification.title,
                  body: notification.body,
                },
                "sound": "default",
                "badge": 1,
                "content-available": 1,
                "mutable-content": 1,
                "thread-id": notification.data.type || "default",
                "category": notification.data.type || "DEFAULT",
              },
              ...notification.data,
            },
            headers: {
              "apns-priority": "10",
              "apns-push-type": "alert",
            },
          },
          // Android specific configuration
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channelId: "chat_notifications",
              priority: "high",
              defaultSound: true,
              visibility: "public",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        };

        // Send the notification
        const response = await admin.messaging().send(message);
        console.log(`Successfully sent notification ${notificationDoc.id}:`, response);

        // Update status to sent
        await notificationDoc.ref.update({
          status: "sent",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: response,
        });

        results.successful++;
      } catch (error) {
        console.error(`Error processing notification ${notificationDoc.id}:`, error);

        // Get notification data for error handling
        const notificationData = notificationDoc.data();

        // Update status to error
        await notificationDoc.ref.update({
          status: "error",
          error: error.message,
          errorCode: error.code || "unknown",
          errorTime: admin.firestore.FieldValue.serverTimestamp(),
        });

        results.failed++;
        results.errors.push(`${notificationDoc.id}: ${error.message}`);

        // Handle invalid tokens
        if (error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered") {
          try {
            if (notificationData.recipientId) {
              await admin.firestore().collection("users").doc(notificationData.recipientId).update({
                fcmTokenValid: false,
                fcmTokenError: error.code,
                fcmTokenErrorTime: admin.firestore.FieldValue.serverTimestamp(),
              });
              console.log(`Marked invalid token for user ${notificationData.recipientId}`);
            }
          } catch (userUpdateError) {
            console.error("Error marking invalid token:", userUpdateError);
          }
        }
      }
    }

    console.log("Processing complete:", results);
    return results;
  } catch (error) {
    console.error("Error in processAllPendingNotifications:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});


exports.sendNotification = onDocumentCreated("notifications/{notificationId}", async (event) => {
  const snapshot = event.data;
  const notification = snapshot.data();

  console.log(`Processing notification: ${JSON.stringify(notification, null, 2)}`);

  // Skip if notification has already been sent
  if (notification.status !== "pending" && notification.status !== "pending_token") {
    console.log(`Notification already processed: status=${notification.status}`);
    return null;
  }

  try {
    // Check for test users
    const isTestUser = notification.recipientId.includes("test_") ||
                      notification.recipientId === "6fbbrljd7ehgs7Ea1DFRdvnC5Jn1" ||
                      notification.recipientId === "M1uABjXQ13dPxiTGVgi7UI6NKYf1";

    const debugToken = "fXcFe_YBeEQ6q4fm-mjNmX:APA91bEbsy3KtFJ1c9ZRgYowrtEsSgBa0MXOG6_2LU5_927Ueiy8nYSUYyroAnUX2ieHo5FfNwWQMk4LSgZ7H1Dtxz_i7yDAIp-GbLZHCXTzncNBQicF-jo";

    if (!notification.fcmToken && isTestUser) {
      console.log(`Using debug token for test user: ${notification.recipientId}`);
      notification.fcmToken = debugToken;
      await snapshot.ref.update({fcmToken: debugToken});
    }

    // If still no token, check the user document
    if (!notification.fcmToken) {
      console.log(`Looking for token in user document: ${notification.recipientId}`);

      const userDoc = await admin.firestore().collection("users").doc(notification.recipientId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.fcmToken) {
          console.log(`Found token in user document`);
          notification.fcmToken = userData.fcmToken;
          await snapshot.ref.update({fcmToken: userData.fcmToken});
        }
      }
    }

    // Skip if no token available
    if (!notification.fcmToken) {
      console.log("No FCM token available for notification:", event.params.notificationId);
      await snapshot.ref.update({
        status: "pending_token",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: "No FCM token available",
      });
      return null;
    }

    // Prepare FCM message
    const message = {
      token: notification.fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      // iOS specific configuration
      apns: {
        payload: {
          aps: {
            "alert": {
              title: notification.title,
              body: notification.body,
            },
            "sound": "default",
            "badge": 1,
            "content-available": 1,
            "mutable-content": 1,
            "thread-id": notification.data.type || "default",
            "category": notification.data.type || "DEFAULT",
          },
          ...notification.data,
        },
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
      },
      // Android specific configuration
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "chat_notifications",
          priority: "high",
          defaultSound: true,
          visibility: "public",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };

    console.log("Sending notification with message:", JSON.stringify(message, null, 2));

    // Send the notification
    const response = await admin.messaging().send(message);
    console.log("Successfully sent notification:", response);

    // Update status to sent
    await snapshot.ref.update({
      status: "sent",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      messageId: response,
    });

    return response;
  } catch (error) {
    console.error("Error sending notification:", error);
    console.error("Error code:", error.code);
    console.error("Error details:", error.details || "No additional details");

    // Update status to error
    await snapshot.ref.update({
      status: "error",
      error: error.message,
      errorCode: error.code || "unknown",
      errorTime: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Handle invalid tokens
    if (error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered") {
      try {
        await admin.firestore().collection("users").doc(notification.recipientId).update({
          fcmTokenValid: false,
          fcmTokenError: error.code,
          fcmTokenErrorTime: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Marked invalid token for user ${notification.recipientId}`);
      } catch (userUpdateError) {
        console.error("Error marking invalid token:", userUpdateError);
      }
    }

    return null;
  }
});

// Replace your onNewMessage function with this corrected version:

exports.onNewMessage = onDocumentCreated("messages/{messageId}", async (event) => {
  const snapshot = event.data;
  const context = event.params;
  const message = snapshot.data();

  // Only send notification if the message isn't from the recipient
  if (!message || message.senderId === message.receiverId) {
    return null;
  }

  try {
    console.log(`New message detected from ${message.senderId} to ${message.receiverId}`);

    // CRITICAL: Check if notification already exists for this message
    const existingNotifications = await admin.firestore()
      .collection("notifications")
      .where("data.messageId", "==", context.messageId) // ← FIXED: context.messageId NOT context.params.messageId
      .limit(1)
      .get();

    if (!existingNotifications.empty) {
      console.log(`Notification already exists for message ${context.messageId}, skipping`); // ← FIXED
      return null;
    }

    // Check if a notification was created in the last 5 seconds for this sender/receiver pair
    const fiveSecondsAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 5000),
    );

    const recentNotifications = await admin.firestore()
      .collection("notifications")
      .where("recipientId", "==", message.receiverId)
      .where("data.senderId", "==", message.senderId)
      .where("type", "==", "message")
      .where("timestamp", ">", fiveSecondsAgo)
      .limit(1)
      .get();

    if (!recentNotifications.empty) {
      console.log(`Recent notification already exists, skipping duplicate`);
      return null;
    }

    // Get sender details
    const senderDoc = await admin.firestore().collection("users").doc(message.senderId).get();
    const senderData = senderDoc.data() || {};
    const senderName = senderData.name || "Someone";

    // Get recipient token
    const recipientDoc = await admin.firestore().collection("users").doc(message.receiverId).get();
    if (!recipientDoc.exists) {
      console.log(`Recipient ${message.receiverId} not found`);
      return null;
    }

    const recipientData = recipientDoc.data();
    const fcmToken = recipientData.fcmToken;

    // Truncate message text
    const messageText = message.text || "";
    const truncatedText = messageText.length > 50 ?
      `${messageText.substring(0, 47)}...` :
      messageText;

    // Create notification with unique ID including timestamp
    const notificationId = `msg_${context.messageId}_${Date.now()}`; // ← FIXED

    await admin.firestore().collection("notifications").doc(notificationId).set({
      type: "message",
      title: "Marifactor",
      body: `${senderName} sent you a new message`,
      recipientId: message.receiverId,
      fcmToken: fcmToken,
      data: {
        type: "message",
        senderId: message.senderId,
        messageId: context.messageId, // ← FIXED
        messageText: truncatedText,
        timestamp: Date.now().toString(),
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: fcmToken ? "pending" : "pending_token",
      platform: recipientData.platform || "unknown",
    });

    console.log(`Created message notification ${notificationId} for ${message.receiverId} from ${senderName}`);
    return null;
  } catch (error) {
    console.error("Error creating message notification:", error);
    return null;
  }
});

// Clean up old notifications
exports.cleanupOldNotifications = onSchedule("every 24 hours", async (event) => {
  const cutoff = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
  );

  const snapshot = await admin.firestore()
    .collection("notifications")
    .where("timestamp", "<", cutoff)
    .get();

  const deletePromises = [];
  snapshot.forEach((doc) => {
    deletePromises.push(doc.ref.delete());
  });

  await Promise.all(deletePromises);
  console.log(`Deleted ${deletePromises.length} old notifications`);
  return null;
});

// Function to process notifications that are waiting for FCM tokens
exports.processNotificationsWithoutTokens = onSchedule("every 15 minutes", async (event) => {
  console.log("Running token-less notification processor");

  // Find notifications with pending_token status
  const pendingNotifications = await admin.firestore()
    .collection("notifications")
    .where("status", "==", "pending_token")
    .get();

  console.log(`Found ${pendingNotifications.docs.length} notifications waiting for tokens`);

  let processedCount = 0;
  let skippedCount = 0;

  for (const notificationDoc of pendingNotifications.docs) {
    try {
      const notification = notificationDoc.data();

      // Skip notifications older than 24 hours
      const notificationTime = notification.timestamp?.toDate() || new Date(0);
      const now = new Date();
      const diffHours = (now.getTime() - notificationTime.getTime()) / (1000 * 60 * 60);

      if (diffHours > 24) {
        console.log(`Notification ${notificationDoc.id} is too old (${diffHours.toFixed(1)} hours), marking as expired`);
        await notificationDoc.ref.update({
          status: "expired",
          processingError: "Notification expired before token was available",
        });
        skippedCount++;
        continue;
      }

      // Get the recipient's user document to check for token
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(notification.recipientId)
        .get();

      if (!userDoc.exists) {
        console.log(`User ${notification.recipientId} not found, skipping notification`);
        await notificationDoc.ref.update({
          status: "error",
          error: "User not found",
        });
        skippedCount++;
        continue;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`User ${notification.recipientId} still has no FCM token, keeping notification pending`);
        skippedCount++;
        continue;
      }

      // Update the notification with the token
      await notificationDoc.ref.update({
        fcmToken: fcmToken,
        status: "pending", // Change to regular pending status
        processingTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Updated notification ${notificationDoc.id} with token for user ${notification.recipientId}`);
      processedCount++;
    } catch (error) {
      console.error(`Error processing notification ${notificationDoc.id}:`, error);

      // Mark as error but don't delete
      try {
        await notificationDoc.ref.update({
          status: "error",
          error: error.message || "Unknown error",
          processingError: true,
        });
      } catch (updateError) {
        console.error("Error updating notification status:", updateError);
      }
    }
  }

  console.log(`Processed ${processedCount} notifications, skipped ${skippedCount}`);
  return null;
});

// Clean up invalid FCM tokens
exports.cleanupInvalidTokens = onSchedule("every 24 hours", async (event) => {
  const snapshot = await admin.firestore()
    .collection("users")
    .where("fcmTokenValid", "==", false)
    .get();

  const updatePromises = [];
  snapshot.forEach((doc) => {
    // Remove the invalid token
    updatePromises.push(doc.ref.update({
      fcmToken: admin.firestore.FieldValue.delete(),
      fcmTokenValid: admin.firestore.FieldValue.delete(),
      fcmTokenError: admin.firestore.FieldValue.delete(),
      fcmTokenErrorTime: admin.firestore.FieldValue.delete(),
    }));
  });

  await Promise.all(updatePromises);
  console.log(`Cleaned up tokens for ${updatePromises.length} users`);
  return null;
});

// Add a direct test notification function
exports.sendTestNotification = onCall(async (request) => {
  try {
    const token = request.data.token;
    if (!token) {
      throw new Error("No token provided");
    }

    const message = {
      token: token,
      notification: {
        title: "Direct Test Notification",
        body: "Sent directly from Cloud Function",
      },
      apns: {
        payload: {
          aps: {
            "alert": {
              title: "Direct Test Notification",
              body: "Sent directly from Cloud Function",
            },
            "sound": "default",
            "badge": 1,
            "content-available": 1,
          },
        },
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_notifications",
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log("Test notification sent successfully:", response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending test notification:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Add this to functions/index.js to fix stuck notifications

exports.fixStuckNotifications = onCall(async (request) => {
  try {
    console.log("Fixing stuck notifications...");

    // Get all pending notifications that have both FCM token and error
    const stuckNotifications = await admin.firestore()
      .collection("notifications")
      .where("status", "==", "pending")
      .get();

    console.log(`Found ${stuckNotifications.docs.length} pending notifications`);

    let fixed = 0;

    for (const doc of stuckNotifications.docs) {
      const data = doc.data();

      // If notification has FCM token but also has error field, remove the error
      if (data.fcmToken && data.error) {
        console.log(`Fixing notification ${doc.id} - has token but error field`);

        await doc.ref.update({
          error: admin.firestore.FieldValue.delete(),
          platform: data.platform === "unknown" ? "ios" : data.platform,
        });

        fixed++;
      }
    }

    console.log(`Fixed ${fixed} stuck notifications`);
    return {success: true, fixed: fixed};
  } catch (error) {
    console.error("Error fixing stuck notifications:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Add a function to check notification status
exports.checkNotificationStatus = onCall(async (request) => {
  try {
    const userId = request.data.userId || (request.auth ? request.auth.uid : null);
    if (!userId) {
      throw new Error("No user ID provided or user not authenticated");
    }

    // Get the user's FCM token from Firestore
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      throw new Error("User not found");
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    // Check recent notifications for this user
    const recentNotifications = await admin.firestore()
      .collection("notifications")
      .where("recipientId", "==", userId)
      .orderBy("timestamp", "desc")
      .limit(10)
      .get();

    const notificationStatus = {
      hasToken: !!fcmToken,
      tokenPrefix: fcmToken ? fcmToken.substring(0, 10) + "..." : null,
      recentNotifications: recentNotifications.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          type: data.type,
          status: data.status,
          timestamp: data.timestamp ? data.timestamp.toDate().toISOString() : null,
          error: data.error,
        };
      }),
    };

    return notificationStatus;
  } catch (error) {
    console.error("Error checking notification status:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
