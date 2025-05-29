// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Add this to your functions/index.js file

exports.sendIosNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    console.log(`Processing iOS notification: ${JSON.stringify(notification, null, 2)}`);

    // Only process iOS notifications
    if (notification.platform !== 'ios') {
      console.log('Not an iOS notification, skipping');
      return null;
    }

    // Skip if notification has already been sent
    if (notification.status !== 'pending' && notification.status !== 'pending_token') {
      console.log('Notification already processed:', notification.status);
      return null;
    }

    try {
      // Use debug token for testing if no token available
      if (!notification.fcmToken) {
        // Check if this is a test user
        const isTestUser = notification.recipientId === 'M1uABjXQ13dPxiTGVgi7UI6NKYf1' ||
                          notification.recipientId === '6fbbrljd7ehgs7Ea1DFRdvnC5Jn1';

        if (isTestUser) {
          // Use your device's token for testing
          const debugToken = 'fXcFe_YBeEQ6q4fm-mjNmX:APA91bEbsy3KtFJ1c9ZRgYowrtEsSgBa0MXOG6_2LU5_927Ueiy8nYSUYyroAnUX2ieHo5FfNwWQMk4LSgZ7H1Dtxz_i7yDAIp-GbLZHCXTzncNBQicF-jo';

          console.log(`Using debug token for test user: ${notification.recipientId}`);
          notification.fcmToken = debugToken;
          await snapshot.ref.update({ fcmToken: debugToken });
        } else {
          console.log('No FCM token available for notification:', context.params.notificationId);
          await snapshot.ref.update({
            status: 'pending_token',
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            error: 'No FCM token available'
          });
          return null;
        }
      }

      // iOS-specific notification format
      const message = {
        token: notification.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        // iOS-specific configuration - More conservative format
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              sound: 'default',
              badge: 1,
            },
            // Include data in the APNS payload
            notificationType: notification.data.type || 'general',
            senderId: notification.data.senderId || '',
            timestamp: notification.data.timestamp || '',
          }
        },
        // Include the data payload for the app to process
        data: {
          type: notification.data.type || 'general',
          senderId: notification.data.senderId || '',
          timestamp: notification.data.timestamp || '',
        }
      };

      console.log('Sending iOS notification with message:', JSON.stringify(message, null, 2));

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent iOS notification:', response);

      // Update status to sent
      await snapshot.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return response;
    } catch (error) {
      console.error('Error sending iOS notification:', error);
      console.error('Error code:', error.code);
      console.error('Error details:', error.details);

      // Update status to error
      await snapshot.ref.update({
        status: 'error',
        error: error.message,
        errorCode: error.code || 'unknown',
        errorTime: admin.firestore.FieldValue.serverTimestamp()
      });

      return null;
    }
  });

// Listen for new notification documents in Firestore
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    console.log(`Processing new notification: ${JSON.stringify(notification, null, 2)}`);

    // Skip if notification has already been sent or has no token
    if (notification.status !== 'pending' && notification.status !== 'pending_token') {
      console.log(`Notification already processed: status=${notification.status}`);
      return null;
    }

    try {
      // Check if this is a test user and we should use a debug token
      const isTestUser = notification.recipientId.includes('test_') ||
                        notification.recipientId === '6fbbrljd7ehgs7Ea1DFRdvnC5Jn1' ||
                        notification.recipientId === 'M1uABjXQ13dPxiTGVgi7UI6NKYf1';

      // Use your device token for testing if recipient is a test user without token
      const debugToken = 'fXcFe_YBeEQ6q4fm-mjNmX:APA91bEbsy3KtFJ1c9ZRgYowrtEsSgBa0MXOG6_2LU5_927Ueiy8nYSUYyroAnUX2ieHo5FfNwWQMk4LSgZ7H1Dtxz_i7yDAIp-GbLZHCXTzncNBQicF-jo';

      if (!notification.fcmToken && isTestUser) {
        console.log(`Using debug token for test user: ${notification.recipientId}`);
        notification.fcmToken = debugToken;
        await snapshot.ref.update({ fcmToken: debugToken });
      }

      // If still no token, check the user document for an updated token
      if (!notification.fcmToken) {
        console.log(`Looking for token in user document: ${notification.recipientId}`);

        const userDoc = await admin.firestore().collection('users').doc(notification.recipientId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          if (userData.fcmToken) {
            console.log(`Found token in user document: ${userData.fcmToken.substring(0, 20)}...`);
            notification.fcmToken = userData.fcmToken;
            await snapshot.ref.update({ fcmToken: userData.fcmToken });
          }
        }
      }

      // Skip if no token available after all attempts
      if (!notification.fcmToken) {
        console.log('No FCM token available for notification:', context.params.notificationId);
        await snapshot.ref.update({
          status: 'pending_token',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          error: 'No FCM token available'
        });
        return null;
      }

      // Prepare FCM message with enhanced iOS configuration
      const message = {
        token: notification.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data || {},
        // iOS specific configuration - CRITICAL FOR iOS NOTIFICATIONS
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              sound: 'default',
              badge: 1,
              'content-available': 1,
              'mutable-content': 1,
              'thread-id': notification.data.type || 'default', // Group by notification type
              'category': notification.data.type || 'DEFAULT', // For notification actions
            },
            // Include the data payload for iOS
            ...notification.data
          },
          headers: {
            'apns-priority': '10', // High priority
            'apns-push-type': 'alert'
          }
        },
        // Android specific configuration
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'chat_notifications',
            priority: 'high',
            defaultSound: true,
            visibility: 'public',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          }
        },
        // Set high priority for all platforms
        webpush: {
          headers: {
            Urgency: 'high',
          }
        }
      };

      console.log('Sending notification with message:', JSON.stringify(message, null, 2));

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);

      // Update status to sent
      await snapshot.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response
      });

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      console.error('Error code:', error.code);
      console.error('Error details:', error.details || 'No additional details');

      // Update status to error
      await snapshot.ref.update({
        status: 'error',
        error: error.message,
        errorCode: error.code || 'unknown',
        errorTime: admin.firestore.FieldValue.serverTimestamp()
      });

      // If the token is invalid, mark it for cleanup
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {

        try {
          // Mark the token as invalid in the user document
          await admin.firestore().collection('users').doc(notification.recipientId).update({
            fcmTokenValid: false,
            fcmTokenError: error.code,
            fcmTokenErrorTime: admin.firestore.FieldValue.serverTimestamp()
          });
          console.log(`Marked invalid token for user ${notification.recipientId}`);
        } catch (userUpdateError) {
          console.error('Error marking invalid token:', userUpdateError);
        }
      }

      return null;
    }
  });

// Clean up old notifications
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // 30 days ago
    );

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('timestamp', '<', cutoff)
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
exports.processNotificationsWithoutTokens = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    console.log('Running token-less notification processor');

    // Find notifications with pending_token status
    const pendingNotifications = await admin.firestore()
      .collection('notifications')
      .where('status', '==', 'pending_token')
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
            status: 'expired',
            processingError: 'Notification expired before token was available'
          });
          skippedCount++;
          continue;
        }

        // Get the recipient's user document to check for token
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(notification.recipientId)
          .get();

        if (!userDoc.exists) {
          console.log(`User ${notification.recipientId} not found, skipping notification`);
          await notificationDoc.ref.update({
            status: 'error',
            error: 'User not found'
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
          status: 'pending', // Change to regular pending status
          processingTime: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`Updated notification ${notificationDoc.id} with token for user ${notification.recipientId}`);
        processedCount++;
      } catch (error) {
        console.error(`Error processing notification ${notificationDoc.id}:`, error);

        // Mark as error but don't delete
        try {
          await notificationDoc.ref.update({
            status: 'error',
            error: error.message || 'Unknown error',
            processingError: true
          });
        } catch (updateError) {
          console.error('Error updating notification status:', updateError);
        }
      }
    }

    console.log(`Processed ${processedCount} notifications, skipped ${skippedCount}`);
    return null;
  });

// Clean up invalid FCM tokens
exports.cleanupInvalidTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const snapshot = await admin.firestore()
      .collection('users')
      .where('fcmTokenValid', '==', false)
      .get();

    const updatePromises = [];
    snapshot.forEach((doc) => {
      // Remove the invalid token
      updatePromises.push(doc.ref.update({
        fcmToken: admin.firestore.FieldValue.delete(),
        fcmTokenValid: admin.firestore.FieldValue.delete(),
        fcmTokenError: admin.firestore.FieldValue.delete(),
        fcmTokenErrorTime: admin.firestore.FieldValue.delete()
      }));
    });

    await Promise.all(updatePromises);
    console.log(`Cleaned up tokens for ${updatePromises.length} users`);
    return null;
  });

// Function to handle when a new message is created
exports.onNewMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();

    // Only send notification if the message isn't from the recipient
    if (!message || message.senderId === message.receiverId) {
      return null;
    }

    try {
      console.log(`New message detected from ${message.senderId} to ${message.receiverId}`);

      // Get sender details
      const senderDoc = await admin.firestore().collection('users').doc(message.senderId).get();
      const senderData = senderDoc.data() || {};
      const senderName = senderData.name || 'Someone';

      // Get recipient token
      const recipientDoc = await admin.firestore().collection('users').doc(message.receiverId).get();
      if (!recipientDoc.exists) {
        console.log(`Recipient ${message.receiverId} not found`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const fcmToken = recipientData.fcmToken;

      // Truncate message text for notification
      const messageText = message.text || '';
      const truncatedText = messageText.length > 50
        ? `${messageText.substring(0, 47)}...`
        : messageText;

      // Create notification document
      await admin.firestore().collection('notifications').add({
        type: 'message',
        title: '💌 New Message',
        body: `${senderName}: ${truncatedText}`,
        recipientId: message.receiverId,
        fcmToken: fcmToken,
        data: {
          type: 'message',
          senderId: message.senderId,
          messageId: context.params.messageId,
          messageText: truncatedText,
          timestamp: Date.now().toString(),
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: fcmToken ? 'pending' : 'pending_token',
        platform: recipientData.platform || 'unknown',
      });

      console.log(`Created message notification for ${message.receiverId} from ${senderName}`);
      return null;

    } catch (error) {
      console.error('Error creating message notification:', error);
      return null;
    }
  });

// Add a direct test notification function
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  try {
    const token = data.token;
    if (!token) {
      throw new Error('No token provided');
    }

    const message = {
      token: token,
      notification: {
        title: 'Direct Test Notification',
        body: 'Sent directly from Cloud Function',
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: 'Direct Test Notification',
              body: 'Sent directly from Cloud Function',
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          }
        }
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_notifications',
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('Test notification sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Add a function to check notification status
exports.checkNotificationStatus = functions.https.onCall(async (data, context) => {
  try {
    const userId = data.userId || (context.auth ? context.auth.uid : null);
    if (!userId) {
      throw new Error('No user ID provided or user not authenticated');
    }

    // Get the user's FCM token from Firestore
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    // Check recent notifications for this user
    const recentNotifications = await admin.firestore()
      .collection('notifications')
      .where('recipientId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const notificationStatus = {
      hasToken: !!fcmToken,
      tokenPrefix: fcmToken ? fcmToken.substring(0, 10) + '...' : null,
      recentNotifications: recentNotifications.docs.map(doc => {
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
    console.error('Error checking notification status:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});