import 'package:alarma_comunitaria/models/alert_status.dart';
import 'package:alarma_comunitaria/models/alert_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlert {
  final String id;
  final String userId;
  final String communityId;
  final AlertType type;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final AlertStatus status;
  final int viewsCount;
  final List<String> viewedUserIds;
  final String? customDescription;
  final String? userName;
  final String? manzana;
  final String? casa;
  final String? barrio;
  final String? department;
  final String? houseDescription;
  final String? phone;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  const EmergencyAlert({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.status,
    this.viewsCount = 0,
    this.viewedUserIds = const [],
    this.customDescription,
    this.userName,
    this.manzana,
    this.casa,
    this.barrio,
    this.department,
    this.houseDescription,
    this.phone,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory EmergencyAlert.fromMap(Map<String, dynamic> map, String id) {
    final viewedList = (map['viewedUserIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return EmergencyAlert(
      id: id,
      userId: map['userId'] as String? ?? '',
      communityId: map['communityId'] as String? ?? '',
      type: AlertTypeX.fromString(map['type'] as String? ?? 'robbery'),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AlertStatusX.fromString(map['status'] as String? ?? 'active'),
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? viewedList.length,
      viewedUserIds: viewedList,
      customDescription: map['customDescription'] as String?,
      userName: map['userName'] as String?,
      manzana: map['manzana'] as String?,
      casa: map['casa'] as String?,
      barrio: map['barrio'] as String?,
      department: map['department'] as String?,
      houseDescription: map['houseDescription'] as String?,
      phone: map['phone'] as String?,
      resolvedBy: map['resolvedBy'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'communityId': communityId,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'viewsCount': viewsCount,
      'viewedUserIds': viewedUserIds,
      'customDescription': customDescription,
      'userName': userName,
      'manzana': manzana,
      'casa': casa,
      'barrio': barrio,
      'department': department,
      'houseDescription': houseDescription,
      'phone': phone,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
    };
  }
}
