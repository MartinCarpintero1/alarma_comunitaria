const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendEmergencyNotification = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const alert = snap.data();
    const communityId = alert.communityId;
    const type = alert.type;

    let emoji = "🚨";
    let label = "Emergencia";
    if (type === "medical") {
      emoji = "🚑";
      label = "Emergencia Médica";
    } else if (type === "fire") {
      emoji = "🔥";
      label = "Incendio";
    } else if (type === "robbery") {
      emoji = "🚨";
      label = "Robo / Intruso";
    }

    const payload = {
      notification: {
        title: "🚨 NUEVA ALERTA DE EMERGENCIA",
        body: `${emoji} ${label} reportado en tu comunidad!`,
        sound: "default",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        alertId: context.params.alertId,
      },
    };

    // Envía la notificación push a todos los dispositivos de la comunidad a través de Google Play Services
    return admin.messaging().sendToTopic(`community_${communityId}`, payload);
  });