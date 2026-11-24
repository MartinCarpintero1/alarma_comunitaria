import 'package:alarma_comunitaria/models/hospital.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository();
});

/// Stream de todos los hospitales registrados en la colección "hospitales"
final hospitalesStreamProvider = StreamProvider<List<Hospital>>((ref) {
  final repository = ref.watch(hospitalRepositoryProvider);
  return repository.watchAllHospitals();
});

class HospitalRepository {
  final FirebaseFirestore _firestore;

  HospitalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _hospitalsCollection =>
      _firestore.collection('hospitales');

  /// Escucha en tiempo real todos los documentos de la colección "hospitales"
  Stream<List<Hospital>> watchAllHospitals() {
    return _hospitalsCollection.snapshots().map((snapshot) {
      debugPrint('Firestore colección "hospitales": se recibieron ${snapshot.docs.length} documentos');
      final list = <Hospital>[];
      for (final doc in snapshot.docs) {
        try {
          final hospital = Hospital.fromFirestore(doc);
          debugPrint('Hospital cargado de "hospitales": ${hospital.name} -> Lat: ${hospital.latitude}, Lng: ${hospital.longitude}');
          list.add(hospital);
        } catch (e, stack) {
          debugPrint('Error parseando documento de hospital (${doc.id}): $e\n$stack');
        }
      }
      return list;
    });
  }

  /// Consulta directa a la colección "hospitales" y devuelve los [limit] más cercanos
  Future<List<Hospital>> getNearestHospitals({
    required double userLat,
    required double userLng,
    int limit = 3,
  }) async {
    try {
      final snapshot = await _hospitalsCollection.get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Colección "hospitales" vacía en getNearestHospitals');
        return [];
      }

      final list = snapshot.docs.map((doc) {
        return Hospital.fromFirestore(doc, userLat: userLat, userLng: userLng);
      }).toList();

      list.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });

      return list.take(limit).toList();
    } catch (e) {
      debugPrint('Error obteniendo hospitales en Firestore (colección "hospitales"): $e');
      return [];
    }
  }

  /// Inicia la llamada a un número de teléfono o número de emergencia (ej: 911, 107)
  static Future<bool> callPhone(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      return false;
    }

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      return await launchUrl(uri);
    } catch (e) {
      debugPrint('No se pudo abrir el marcador telefónico para $phoneNumber: $e');
      return false;
    }
  }

  /// Inicia la llamada al 911 (Emergencias)
  static Future<bool> call911() async {
    return callPhone('911');
  }

  /// Inicia la llamada de emergencia al 911
  static Future<bool> call107() async {
    return call911();
  }

  /// Abre Google Maps o la aplicación de navegación para guiar hasta el hospital
  static Future<bool> openNavigation(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('No se pudo abrir Google Maps: $e');
        return false;
      }
    }
  }
}
