import 'package:alarma_comunitaria/models/comisaria.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final comisariaRepositoryProvider = Provider<ComisariaRepository>((ref) {
  return ComisariaRepository();
});

/// Stream de todas las comisarías registradas exactamente en la colección "comisarias"
final comisariasStreamProvider = StreamProvider<List<Comisaria>>((ref) {
  final repository = ref.watch(comisariaRepositoryProvider);
  return repository.watchAllComisarias();
});

class ComisariaRepository {
  final FirebaseFirestore _firestore;

  ComisariaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Colección exacta en Firestore: "comisarias"
  CollectionReference<Map<String, dynamic>> get _comisariasCollection =>
      _firestore.collection('comisarias');

  /// Escucha en tiempo real todos los documentos de la colección "comisarias"
  Stream<List<Comisaria>> watchAllComisarias() {
    return _comisariasCollection.snapshots().map((snapshot) {
      debugPrint('Firestore colección "comisarias": se recibieron ${snapshot.docs.length} documentos');
      final list = <Comisaria>[];
      for (final doc in snapshot.docs) {
        try {
          final comisaria = Comisaria.fromFirestore(doc);
          debugPrint('Comisaría cargada de "comisarias": ${comisaria.name} -> Lat: ${comisaria.latitude}, Lng: ${comisaria.longitude}');
          list.add(comisaria);
        } catch (e, stack) {
          debugPrint('Error parseando documento de comisaría (${doc.id}): $e\n$stack');
        }
      }
      return list;
    });
  }

  /// Consulta directa a la colección "comisarias" y devuelve las [limit] más cercanas
  Future<List<Comisaria>> getNearestComisarias({
    required double userLat,
    required double userLng,
    int limit = 3,
  }) async {
    try {
      final snapshot = await _comisariasCollection.get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Colección "comisarias" vacía en getNearestComisarias');
        return [];
      }

      final list = snapshot.docs.map((doc) {
        return Comisaria.fromFirestore(doc, userLat: userLat, userLng: userLng);
      }).toList();

      // Ordenar por distancia de menor a mayor
      list.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });

      return list.take(limit).toList();
    } catch (e) {
      debugPrint('Error obteniendo comisarías en Firestore (colección "comisarias"): $e');
      return [];
    }
  }

  /// Inicia la llamada al número de la comisaría mediante url_launcher
  static Future<bool> callComisaria(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      return false;
    }

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      return await launchUrl(uri);
    } catch (e) {
      debugPrint('No se pudo abrir el marcador telefónico: $e');
      return false;
    }
  }

  /// Abre Google Maps o la aplicación de navegación para guiar en auto hasta la comisaría
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
