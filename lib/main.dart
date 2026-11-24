import 'package:alarma_comunitaria/app/app.dart';
import 'package:alarma_comunitaria/app/router.dart';
import 'package:alarma_comunitaria/firebase_options.dart';
import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:alarma_comunitaria/models/emergency_alert.dart';
import 'package:alarma_comunitaria/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notification = message.notification;
  if (notification != null) {
    await NotificationService().showEmergencyNotification(
      id: message.messageId.hashCode,
      title: notification.title ?? '🚨 ALERTA DE EMERGENCIA',
      body: notification.body ?? 'Nueva emergencia reportada en tu comunidad',
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  int _activeSeconds = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _activeSeconds = 0;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    _activeSeconds += 5;
    final minutes = _activeSeconds ~/ 60;
    final seconds = _activeSeconds % 60;
    final timeFormatted = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    try {
      await NotificationService().showStickyOngoingNotification(timeStr: timeFormatted);
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  OneSignal.initialize("76b3c11f-ee30-4af4-8567-7d46f35295c1");
  OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    final data = event.notification.additionalData;
    final alertUserId = data?['userId'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (alertUserId != null && currentUserId != null && alertUserId == currentUserId) {
      event.preventDefault();
    }
  });

  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    if (data != null) {
      final lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
      final lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;
      if (lat != 0.0 && lng != 0.0) {
        final alert = EmergencyAlert(
          id: data['id']?.toString() ?? '',
          userId: data['userId']?.toString() ?? '',
          communityId: '',
          type: AlertTypeX.fromString(data['type']?.toString() ?? 'robbery'),
          latitude: lat,
          longitude: lng,
          createdAt: DateTime.now(),
          status: AlertStatus.active,
          userName: data['userName']?.toString(),
          manzana: data['manzana']?.toString(),
          casa: data['casa']?.toString(),
          barrio: data['barrio']?.toString(),
          phone: data['phone']?.toString(),
          customDescription: data['description']?.toString(),
        );
        AppRouter.router.go('/map', extra: alert);
      }
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService().init();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service_channel',
      channelName: 'Servicio de Alarma Comunitaria',
      channelDescription: 'Monitoreando emergencias comunitarias 24/7.',
      channelImportance: NotificationChannelImportance.HIGH,
    ),
    iosNotificationOptions: IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(const ProviderScope(child: AlarmaComunitariaApp()));
}
