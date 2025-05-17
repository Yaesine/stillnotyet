// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Listen for new notification documents in Firestore
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();

    // Skip if notification has already been sent or has no token
    if (notification.status !== 'pending' || !notification.fcmToken) {
      console.log('Notification already sent or missing token');
      return null;
    }

    try {
      // Prepare FCM message
      const message = {
        token: notification.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'chat_notifications',
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true
            }
          }
        }
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);

      // Update status to sent
      await snapshot.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);

      // Update status to error
      await snapshot.ref.update({
        status: 'error',
        error: error.message
      });

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