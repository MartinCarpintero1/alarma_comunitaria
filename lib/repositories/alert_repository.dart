import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/emergency_alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AlertRepository {
  final FirebaseFirestore _firestore;

  AlertRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _alertsCollection =>
      _firestore.collection('alerts');

  Stream<List<EmergencyAlert>> watchActiveAlerts(String communityId) {
    return _alertsCollection
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyAlert.fromMap(doc.data(), doc.id))
            .where((alert) => alert.status != AlertStatus.resolved && alert.status != AlertStatus.cancelled)
            .toList());
  }

  Future<String> createAlert(EmergencyAlert alert) async {
    final docRef = await _alertsCollection.add(alert.toMap());
    return docRef.id;
  }

  Future<void> updateAlertStatus(String alertId, AlertStatus status) async {
    await _alertsCollection.doc(alertId).update({'status': status.name});
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).delete();
    } catch (e) {
      debugPrint('Delete failed on server rules, updating status to cancelled: $e');
      await _alertsCollection.doc(alertId).update({'status': 'cancelled'});
    }
  }

  Future<void> updateAlertLocation(String alertId, double lat, double lng) async {
    await _alertsCollection.doc(alertId).update({
      'latitude': lat,
      'longitude': lng,
    });
  }

  Future<void> markAsViewed(String alertId, String userId) async {
    try {
      await _alertsCollection.doc(alertId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error in markAsViewed: $e');
    }
  }

  Stream<List<EmergencyAlert>> watchHistory(String communityId) {
    return _alertsCollection
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyAlert.fromMap(doc.data(), doc.id))
            .toList());
  }
}
