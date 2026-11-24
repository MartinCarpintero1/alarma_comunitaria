import 'package:alarma_comunitaria/models/bombero.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final bomberoRepositoryProvider = Provider<BomberoRepository>((ref) {
  return BomberoRepository();
});

/// Stream de todos los cuarteles de bomberos en la colección "bomberos"
final bomberosStreamProvider = StreamProvider<List<Bombero>>((ref) {
  final repository = ref.watch(bomberoRepositoryProvider);
  return repository.watchAllBomberos();
});

class BomberoRepository {
  final FirebaseFirestore _firestore;

  BomberoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bomberosCollection =>
      _firestore.collection('bomberos');

  /// Escucha en tiempo real todos los documentos de la colección "bomberos"
  Stream<List<Bombero>> watchAllBomberos() {
    return _bomberosCollection.snapshots().map((snapshot) {
      debugPrint('Firestore colección "bomberos": se recibieron ${snapshot.docs.length} documentos');
      final list = <Bombero>[];
      for (final doc in snapshot.docs) {
        try {
          final bombero = Bombero.fromFirestore(doc);
          debugPrint('Bombero cargado de "bomberos": ${bombero.name} -> Lat: ${bombero.latitude}, Lng: ${bombero.longitude}');
          list.add(bombero);
        } catch (e, stack) {
          debugPrint('Error parseando documento de bombero (${doc.id}): $e\n$stack');
        }
      }
      return list;
    });
  }

  /// Consulta directa a la colección "bomberos" y devuelve los [limit] más cercanos
  Future<List<Bombero>> getNearestBomberos({
    required double userLat,
    required double userLng,
    int limit = 3,
  }) async {
    try {
      final snapshot = await _bomberosCollection.get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Colección "bomberos" vacía en getNearestBomberos');
        return [];
      }

      final list = snapshot.docs.map((doc) {
        return Bombero.fromFirestore(doc, userLat: userLat, userLng: userLng);
      }).toList();

      list.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });

      return list.take(limit).toList();
    } catch (e) {
      debugPrint('Error obteniendo bomberos en Firestore (colección "bomberos"): $e');
      return [];
    }
  }

  /// Inicia la llamada de emergencia al 911
  static Future<bool> call100() async {
    return callPhone('911');
  }

  /// Inicia llamada telefónica a un número
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

  /// Abre Google Maps o la aplicación de navegación para guiar hasta el cuartel
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
