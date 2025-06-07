// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const {RtcTokenBuilder, RtcRole} = require("agora-token");

admin.initializeApp();

// Constants for product IDs
const PRODUCT_IDS = {
  PREMIUM: {
    MONTHLY: "com.marifecto.datechatmeet.prem.monthly",
    THREE_MONTHS: "com.marifecto.premium.3months",
    SIX_MONTHS: "com.marifecto.premium.6months",
  },
  BOOST: {
    ONE_PACK: "com.marifecto.boost.1pack",
    FIVE_PACK: "com.marifecto.boost.5pack",
    TEN_PACK: "com.marifecto.boost.10pack",
  },
  SUPER_LIKE: {
    FIVE_PACK: "com.marifecto.superlike.5pack",
    FIFTEEN_PACK: "com.marifecto.superlike.15pack",
    THIRTY_PACK: "com.marifecto.superlike.30pack",
  },
};

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
          console.log("Found token in user document");
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
      .where("data.messageId", "==", context.messageId)
      .limit(1)
      .get();

    if (!existingNotifications.empty) {
      console.log(`Notification already exists for message ${context.messageId}, skipping`);
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
      console.log("Recent notification already exists, skipping duplicate");
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
    const notificationId = `msg_${context.messageId}_${Date.now()}`;

    await admin.firestore().collection("notifications").doc(notificationId).set({
      type: "message",
      title: "Marifactor",
      body: `${senderName} sent you a new message`,
      recipientId: message.receiverId,
      fcmToken: fcmToken,
      data: {
        type: "message",
        senderId: message.senderId,
        messageId: context.messageId,
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

// Verify Apple receipt
exports.verifyAppleReceipt = onCall(async (request) => {
  try {
    const {receiptData} = request.data;
    if (!receiptData) {
      throw new functions.https.HttpsError("invalid-argument", "Receipt data is required");
    }

    // Verify with Apple's servers
    const response = await validateWithApple(receiptData);
    return response;
  } catch (error) {
    console.error("Error verifying receipt:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Grant purchase to user
exports.grantPurchase = onCall(async (request) => {
  try {
    const {userId, productId, purchaseToken, platform} = request.data;
    if (!userId || !productId) {
      throw new functions.https.HttpsError("invalid-argument", "User ID and product ID are required");
    }

    // Grant the purchase based on product type
    const result = await grantPurchase(userId, productId, purchaseToken, platform);
    return result;
  } catch (error) {
    console.error("Error granting purchase:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Store receipt for future verification
exports.storeReceipt = onCall(async (request) => {
  try {
    const {userId, receiptData, productId, platform} = request.data;
    if (!userId || !receiptData || !productId) {
      throw new functions.https.HttpsError("invalid-argument", "User ID, receipt data, and product ID are required");
    }

    await storeReceipt(userId, receiptData, productId, platform);
    return {success: true};
  } catch (error) {
    console.error("Error storing receipt:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Handle expired subscription
exports.handleExpiredSubscription = onCall(async (request) => {
  try {
    const {userId} = request.data;
    if (!userId) {
      throw new functions.https.HttpsError("invalid-argument", "User ID is required");
    }

    await handleExpiredSubscription(userId);
    return {success: true};
  } catch (error) {
    console.error("Error handling expired subscription:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Handle pending renewal
exports.handlePendingRenewal = onCall(async (request) => {
  try {
    const {userId, productId} = request.data;
    if (!userId || !productId) {
      throw new functions.https.HttpsError("invalid-argument", "User ID and product ID are required");
    }

    await handlePendingRenewal(userId, productId);
    return {success: true};
  } catch (error) {
    console.error("Error handling pending renewal:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Get boost count
exports.getBoostCount = onCall(async (request) => {
  try {
    const {userId} = request.data;
    if (!userId) {
      throw new functions.https.HttpsError("invalid-argument", "User ID is required");
    }

    const count = await getBoostCount(userId);
    return {count};
  } catch (error) {
    console.error("Error getting boost count:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Get super like count
exports.getSuperLikeCount = onCall(async (request) => {
  try {
    const {userId} = request.data;
    if (!userId) {
      throw new functions.https.HttpsError("invalid-argument", "User ID is required");
    }

    const count = await getSuperLikeCount(userId);
    return {count};
  } catch (error) {
    console.error("Error getting super like count:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Helper functions

/**
 * Validates a receipt with Apple's servers
 * @param {string} receiptData - The base64 encoded receipt data
 * @return {Promise<Object>} The validation response from Apple
 */
async function validateWithApple(receiptData) {
  // TODO: Implement actual Apple receipt validation
  // For now, return a mock response
  return {
    status: 0,
    receipt: {
      bundle_id: "com.marifecto",
      application_version: "1.0",
      in_app: [],
    },
  };
}

/**
 * Grants a purchase to a user
 * @param {string} userId - The user's ID
 * @param {string} productId - The product ID
 * @param {string} purchaseToken - The purchase token
 * @param {string} platform - The platform (ios/android)
 * @return {Promise<Object>} The result of granting the purchase
 */
async function grantPurchase(userId, productId, purchaseToken, platform) {
  const userRef = admin.firestore().collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    throw new Error("User not found");
  }

  const now = admin.firestore.Timestamp.now();

  // Handle different product types
  if (productId.startsWith("com.marifecto.premium")) {
    // Handle premium subscription
    let expiryDate;
    switch (productId) {
      case PRODUCT_IDS.PREMIUM.MONTHLY:
        expiryDate = new Date(now.toDate().setMonth(now.toDate().getMonth() + 1));
        break;
      case PRODUCT_IDS.PREMIUM.THREE_MONTHS:
        expiryDate = new Date(now.toDate().setMonth(now.toDate().getMonth() + 3));
        break;
      case PRODUCT_IDS.PREMIUM.SIX_MONTHS:
        expiryDate = new Date(now.toDate().setMonth(now.toDate().getMonth() + 6));
        break;
      default:
        throw new Error("Invalid premium product ID");
    }

    await userRef.update({
      isPremium: true,
      premiumUntil: admin.firestore.Timestamp.fromDate(expiryDate),
      premiumStartDate: now,
      premiumType: productId,
      premiumFeatures: [
        "unlimited_likes",
        "see_who_likes_you",
        "super_likes",
        "rewind",
        "read_receipts",
        "priority_matches",
      ],
    });

    return {
      type: "premium",
      expiryDate: expiryDate.toISOString(),
    };
  } else if (productId.startsWith("com.marifecto.boost")) {
    // Handle boost purchase
    let boostCount;
    switch (productId) {
      case PRODUCT_IDS.BOOST.ONE_PACK:
        boostCount = 1;
        break;
      case PRODUCT_IDS.BOOST.FIVE_PACK:
        boostCount = 5;
        break;
      case PRODUCT_IDS.BOOST.TEN_PACK:
        boostCount = 10;
        break;
      default:
        throw new Error("Invalid boost product ID");
    }

    await userRef.update({
      availableBoosts: admin.firestore.FieldValue.increment(boostCount),
      lastBoostPurchase: now,
    });

    return {
      type: "boost",
      count: boostCount,
    };
  } else if (productId.startsWith("com.marifecto.superlike")) {
    // Handle super like purchase
    let superLikeCount;
    switch (productId) {
      case PRODUCT_IDS.SUPER_LIKE.FIVE_PACK:
        superLikeCount = 5;
        break;
      case PRODUCT_IDS.SUPER_LIKE.FIFTEEN_PACK:
        superLikeCount = 15;
        break;
      case PRODUCT_IDS.SUPER_LIKE.THIRTY_PACK:
        superLikeCount = 30;
        break;
      default:
        throw new Error("Invalid super like product ID");
    }

    await userRef.update({
      availableSuperLikes: admin.firestore.FieldValue.increment(superLikeCount),
      lastSuperLikePurchase: now,
    });

    return {
      type: "superlike",
      count: superLikeCount,
    };
  }

  throw new Error("Invalid product ID");
}

/**
 * Stores a receipt for future verification
 * @param {string} userId - The user's ID
 * @param {string} receiptData - The receipt data
 * @param {string} productId - The product ID
 * @param {string} platform - The platform (ios/android)
 * @return {Promise<void>}
 */
async function storeReceipt(userId, receiptData, productId, platform) {
  await admin.firestore().collection("receipts").add({
    userId,
    receiptData,
    productId,
    platform,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    verified: false,
  });
}

/**
 * Handles an expired subscription
 * @param {string} userId - The user's ID
 * @return {Promise<void>}
 */
async function handleExpiredSubscription(userId) {
  const userRef = admin.firestore().collection("users").doc(userId);
  await userRef.update({
    isPremium: false,
    premiumExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
    premiumFeatures: [],
  });
}

/**
 * Handles a pending renewal
 * @param {string} userId - The user's ID
 * @param {string} productId - The product ID
 * @return {Promise<void>}
 */
async function handlePendingRenewal(userId, productId) {
  const userRef = admin.firestore().collection("users").doc(userId);
  await userRef.update({
    pendingRenewal: true,
    pendingRenewalProductId: productId,
    pendingRenewalDate: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Gets the current boost count for a user
 * @param {string} userId - The user's ID
 * @return {Promise<number>} The number of available boosts
 */
async function getBoostCount(userId) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new Error("User not found");
  }
  return userDoc.data()?.availableBoosts || 0;
}

/**
 * Gets the current super like count for a user
 * @param {string} userId - The user's ID
 * @return {Promise<number>} The number of available super likes
 */
async function getSuperLikeCount(userId) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new Error("User not found");
  }
  return userDoc.data()?.availableSuperLikes || 0;
}
