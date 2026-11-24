import 'dart:async';

import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/emergency_alert.dart';
import 'package:alarma_comunitaria/repositories/alert_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository();
});

final activeAlertsProvider = StreamProvider.family<List<EmergencyAlert>, String>(
  (ref, communityId) {
    final repository = ref.watch(alertRepositoryProvider);
    return repository.watchActiveAlerts(communityId);
  },
);

final historyAlertsProvider = StreamProvider.family<List<EmergencyAlert>, String>(
  (ref, communityId) {
    final repository = ref.watch(alertRepositoryProvider);
    return repository.watchHistory(communityId);
  },
);

class AlertController {
  final AlertRepository repository;

  AlertController(this.repository);

  Future<String> createAlert(EmergencyAlert alert) async {
    return repository.createAlert(alert);
  }

  Future<void> updateAlertStatus(String alertId, AlertStatus status) async {
    await repository.updateAlertStatus(alertId, status);
  }
}
