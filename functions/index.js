const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = onDocumentCreated(
  { document: "notifications/{notificationId}", region: "asia-south1" },
  async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data();
  const userId = data.user_id;
  const title = data.title;
  const body = data.body;
  const type = data.type;
  const relatedId = data.related_id;
  const image = data.image;

  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.log(`User ${userId} not found.`);
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${userId} has no fcmToken.`);
      return null;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type || "",
        related_id: relatedId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };
    
    // Add image if present (usually for listings)
    if (image) {
      payload.notification.image = image;
    }

    const response = await admin.messaging().send(payload);
    console.log("Successfully sent message:", response);
    return response;
  } catch (error) {
    console.error("Error sending message:", error);
    return null;
  }
});
